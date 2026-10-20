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

  /// Minimum time required between duplicate scans of the same barcode.
  Duration debounceDuration = const Duration(milliseconds: 1200);

  /// Processing lock to prevent concurrent or duplicate requests while an item
  /// is being verified or added to an order.
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

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
          default:
            break;
        }
      });
    }
  }

  /// Internal handler that filters duplicates and dispatches to stream
  void _handleIncomingBarcode(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    if (_isProcessing) {
      log('Ignored barcode scan "$code": currently processing previous request',
          name: 'SunmiScannerService');
      return;
    }

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

  /// Trigger scanner engine to start scanning (lights up scan head / laser).
  /// Safe to call on any platform; does nothing if not Sunmi Android.
  Future<bool> startScan() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('startScan');
      return result ?? false;
    } catch (e) {
      log('Error calling startScan: $e', name: 'SunmiScannerService');
      return false;
    }
  }

  /// Stop scanner engine reading / turns off scan head light.
  /// Safe to call on any platform; does nothing if not Sunmi Android.
  Future<bool> stopScan() async {
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

  /// Set the processing lock to prevent concurrent scan executions.
  void setProcessing(bool value) {
    _isProcessing = value;
  }

  /// Manually reset debouncing cache if needed (e.g., when resetting an order).
  void resetDebounce() {
    _lastScannedCode = null;
    _lastScannedAt = null;
    _isProcessing = false;
  }
}
