import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to interact with the Sunmi Scanner Engine on Android Sunmi devices.
///
/// Implements auto-start/stop scanning using Sunmi AIDL (`IScanInterface`)
/// and receives scanned barcode data via Sunmi broadcast (`ACTION_DATA_CODE_RECEIVED`).
///
/// If running on non-Android or non-Sunmi hardware, this service safely degrades
/// gracefully without crashing, allowing standard keyboard listeners to operate.
class SunmiScannerService {
  static const MethodChannel _channel =
      MethodChannel('com.izisoluciones.kiosco/sunmi_scanner');

  static final SunmiScannerService _instance = SunmiScannerService._internal();
  static SunmiScannerService get instance => _instance;

  final StreamController<String> _barcodeController =
      StreamController<String>.broadcast();

  /// Stream of successfully scanned barcodes.
  Stream<String> get onBarcodeScanned => _barcodeController.stream;

  String? _lastScannedCode;
  DateTime? _lastScannedAt;

  /// Minimum time required between duplicate scans of the exact same barcode.
  /// Set to 400ms to filter hardware sensor bounce while permitting rapid sequential
  /// scanning of duplicate retail items.
  Duration debounceDuration = const Duration(milliseconds: 400);

  /// Active clients registered for the scanner lifecycle (e.g. PageView children).
  /// Uses a Set of client tokens/identifiers to make client tracking idempotent
  /// and completely immune to counter drift or accidental multiple calls.
  final Set<String> _activeClients = <String>{};

  @visibleForTesting
  int get activeClients => _activeClients.length;

  Set<String> get activeClientIds => Set.unmodifiable(_activeClients);

  bool _initialized = false;
  bool? _isSunmiCached;

  /// Test override to simulate Android platform in unit tests running on host machines.
  @visibleForTesting
  static bool debugOverrideIsAndroid = false;

  bool get _isAndroid => debugOverrideIsAndroid || (!kIsWeb && Platform.isAndroid);

  SunmiScannerService._internal() {
    _initChannel();
  }

  @visibleForTesting
  void reinitForTesting() {
    _initialized = false;
    _isSunmiCached = null;
    _activeClients.clear();
    resetDebounce();
    _initChannel();
  }

  void _initChannel() {
    if (_initialized) return;
    _initialized = true;

    if (_isAndroid) {
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onBarcodeScanned':
            try {
              final arguments = call.arguments;
              String? code;
              if (arguments is Map) {
                code = arguments['code']?.toString();
              } else if (arguments is String) {
                code = arguments;
              }

              if (code != null) {
                _handleIncomingBarcode(code);
              }
            } catch (e) {
              log('Error handling Sunmi onBarcodeScanned: $e',
                  name: 'SunmiScannerService');
            }
            break;
          case 'onScanError':
            log('Sunmi scanner error: ${call.arguments}',
                name: 'SunmiScannerService');
            break;
          case 'onResumeScanner':
            if (_activeClients.isNotEmpty) {
              log('App resumed with active scanner clients ($_activeClients). Re-arming scanner.',
                  name: 'SunmiScannerService');
              rearmScan();
            }
            break;
          default:
            break;
        }
      });
    }
  }

  /// Internal handler that filters duplicate bursts and dispatches to stream
  void _handleIncomingBarcode(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    final now = DateTime.now();
    if (_lastScannedCode == code && _lastScannedAt != null) {
      final diff = now.difference(_lastScannedAt!);
      if (diff < debounceDuration) {
        log('Debounced duplicate scan for barcode "$code" (${diff.inMilliseconds}ms < ${debounceDuration.inMilliseconds}ms)',
            name: 'SunmiScannerService');
        return;
      }
    }

    _lastScannedCode = code;
    _lastScannedAt = now;

    log('Dispatched Sunmi barcode: $code', name: 'SunmiScannerService');
    _barcodeController.add(code);
  }

  /// Check whether the current device manufacturer/brand is Sunmi.
  Future<bool> isSunmiDevice() async {
    if (!_isAndroid) return false;
    if (_isSunmiCached != null) return _isSunmiCached!;
    try {
      final result = await _channel.invokeMethod<bool>('isSunmiDevice');
      _isSunmiCached = result ?? false;
      return _isSunmiCached!;
    } catch (e) {
      log('Error checking isSunmiDevice: $e', name: 'SunmiScannerService');
      _isSunmiCached = false;
      return false;
    }
  }

  /// Check whether the Sunmi scanner service is currently connected and ready.
  Future<bool> isScannerAvailable() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isScannerAvailable');
      return result ?? false;
    } catch (e) {
      log('Error checking isScannerAvailable: $e', name: 'SunmiScannerService');
      return false;
    }
  }

  /// Registers a view as an active scanner client and triggers the scanner engine.
  /// Uses [clientId] to make client registration idempotent and prevent duplicate counts.
  /// Safe to call on any platform; does nothing if not Sunmi Android.
  Future<bool> startScan([String clientId = 'default']) async {
    _activeClients.add(clientId);
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('startScan');
      return result ?? false;
    } catch (e) {
      log('Error calling startScan: $e', name: 'SunmiScannerService');
      return false;
    }
  }

  /// Re-arms the scanner for subsequent items within an already active view
  /// without changing active client registrations.
  Future<bool> rearmScan() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('startScan');
      return result ?? false;
    } catch (e) {
      log('Error calling rearmScan: $e', name: 'SunmiScannerService');
      return false;
    }
  }

  /// Releases a scanner client. The native hardware scanner is ONLY turned off
  /// when no active clients remain (_activeClients.isEmpty) or if [force] is true.
  /// If [clientId] is supplied, removes only that client.
  /// Safe to call on any platform; does nothing if not Sunmi Android.
  Future<bool> stopScan({String? clientId, bool force = false}) async {
    if (force) {
      _activeClients.clear();
    } else {
      if (clientId != null) {
        _activeClients.remove(clientId);
      } else if (_activeClients.isNotEmpty) {
        _activeClients.remove(_activeClients.first);
      }
    }

    if (_activeClients.isNotEmpty && !force) {
      log('stopScan deferred: ${_activeClients.length} active client(s) still listening ($_activeClients)',
          name: 'SunmiScannerService');
      return false;
    }
    _activeClients.clear();
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('stopScan');
      return result ?? false;
    } catch (e) {
      log('Error calling stopScan: $e', name: 'SunmiScannerService');
      return false;
    }
  }

  /// Get hardware scanner model code (100 = None).
  Future<int> getScannerModel() async {
    if (!_isAndroid) return 100;
    try {
      final result = await _channel.invokeMethod<int>('getScannerModel');
      return result ?? 100;
    } catch (e) {
      log('Error calling getScannerModel: $e', name: 'SunmiScannerService');
      return 100;
    }
  }

  /// Manually reset debouncing cache if needed (e.g., when resetting an order).
  void resetDebounce() {
    _lastScannedCode = null;
    _lastScannedAt = null;
  }
}
