import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/utils/sunmi_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('com.izisoluciones.kiosco/sunmi_scanner');

  setUp(() {
    SunmiScannerService.debugOverrideIsAndroid = true;
    SunmiScannerService.instance.reinitForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'isSunmiDevice':
          return true;
        case 'isScannerAvailable':
          return true;
        case 'startScan':
          return true;
        case 'stopScan':
          return true;
        case 'getScannerModel':
          return 103; // L2 Zebra
        default:
          return null;
      }
    });
    SunmiScannerService.instance.resetDebounce();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    SunmiScannerService.debugOverrideIsAndroid = false;
    SunmiScannerService.instance.reinitForTesting();
    SunmiScannerService.instance.resetDebounce();
  });

  group('SunmiScannerService Tests', () {
    test('isSunmiDevice returns true when platform returns true', () async {
      final isSunmi = await SunmiScannerService.instance.isSunmiDevice();
      expect(isSunmi, isTrue);
    });

    test('isScannerAvailable returns true when connected', () async {
      final available = await SunmiScannerService.instance.isScannerAvailable();
      expect(available, isTrue);
    });

    test('startScan and stopScan invoke channel successfully', () async {
      final startRes = await SunmiScannerService.instance.startScan();
      expect(startRes, isTrue);

      final stopRes = await SunmiScannerService.instance.stopScan();
      expect(stopRes, isTrue);
    });

    test('getScannerModel returns hardware model id', () async {
      final model = await SunmiScannerService.instance.getScannerModel();
      expect(model, equals(103));
    });

    test('Dispatches barcode through stream when native sends onBarcodeScanned',
        () async {
      final List<String> received = [];
      final sub = SunmiScannerService.instance.onBarcodeScanned.listen((code) {
        received.add(code);
      });

      // Simulate native method channel call from Android
      final ByteData message =
          const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onBarcodeScanned', {'code': '7791234567890'}),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('com.izisoluciones.kiosco/sunmi_scanner', message, (ByteData? reply) {});

      expect(received, contains('7791234567890'));
      await sub.cancel();
    });

    test('Debounces duplicate scans within 400ms debounceDuration', () async {
      final List<String> received = [];
      final sub = SunmiScannerService.instance.onBarcodeScanned.listen((code) {
        received.add(code);
      });

      final ByteData message =
          const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onBarcodeScanned', {'code': '7790000000001'}),
      );

      // First scan
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('com.izisoluciones.kiosco/sunmi_scanner', message, (ByteData? reply) {});

      // Duplicate scan immediately (<400ms)
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('com.izisoluciones.kiosco/sunmi_scanner', message, (ByteData? reply) {});

      expect(received.length, equals(1));

      // Wait past debounce duration to allow next scan of same product
      await Future.delayed(const Duration(milliseconds: 450));

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('com.izisoluciones.kiosco/sunmi_scanner', message, (ByteData? reply) {});

      expect(received.length, equals(2));
      await sub.cancel();
    });

    test('Reference counting manages active scanner views without race conditions', () async {
      final List<String> channelCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        channelCalls.add(call.method);
        return true;
      });

      expect(SunmiScannerService.instance.activeClients, equals(0));

      // First view mounts (e.g. MakeOrderRetailInit)
      await SunmiScannerService.instance.startScan();
      expect(SunmiScannerService.instance.activeClients, equals(1));
      expect(channelCalls.last, equals('startScan'));

      // Second view mounts in PageView (e.g. MakeOrderRetailScan)
      await SunmiScannerService.instance.startScan();
      expect(SunmiScannerService.instance.activeClients, equals(2));

      // First view disposes after transition
      channelCalls.clear();
      final stopped1 = await SunmiScannerService.instance.stopScan();
      expect(stopped1, isFalse); // Deferred stop because 1 client remains
      expect(SunmiScannerService.instance.activeClients, equals(1));
      expect(channelCalls, isEmpty); // Native stop was NOT invoked

      // Re-arming during scanning does not inflate client count
      await SunmiScannerService.instance.rearmScan();
      expect(SunmiScannerService.instance.activeClients, equals(1));
      expect(channelCalls.last, equals('startScan'));

      // Second view disposes on exit
      channelCalls.clear();
      final stopped2 = await SunmiScannerService.instance.stopScan();
      expect(stopped2, isTrue);
      expect(SunmiScannerService.instance.activeClients, equals(0));
      expect(channelCalls.last, equals('stopScan'));
    });

    test('stopScan with force: true stops immediately regardless of client count', () async {
      final List<String> channelCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        channelCalls.add(call.method);
        return true;
      });

      await SunmiScannerService.instance.startScan();
      await SunmiScannerService.instance.startScan();
      expect(SunmiScannerService.instance.activeClients, equals(2));

      final forcedStop = await SunmiScannerService.instance.stopScan(force: true);
      expect(forcedStop, isTrue);
      expect(SunmiScannerService.instance.activeClients, equals(0));
      expect(channelCalls.last, equals('stopScan'));
    });

    test('onResumeScanner re-arms scanner when active clients exist', () async {
      final List<String> channelCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        channelCalls.add(call.method);
        return true;
      });

      await SunmiScannerService.instance.startScan();
      channelCalls.clear();

      final ByteData message =
          const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onResumeScanner'),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('com.izisoluciones.kiosco/sunmi_scanner', message, (ByteData? reply) {});

      expect(channelCalls, contains('startScan'));
    });
  });
}
