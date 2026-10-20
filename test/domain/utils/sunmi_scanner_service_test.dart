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

    test('Debounces duplicate scans within debounceDuration', () async {
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

      // Duplicate scan immediately
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('com.izisoluciones.kiosco/sunmi_scanner', message, (ByteData? reply) {});

      expect(received.length, equals(1));
      await sub.cancel();
    });

    test('Ignores incoming scans when processing lock is enabled', () async {
      final List<String> received = [];
      final sub = SunmiScannerService.instance.onBarcodeScanned.listen((code) {
        received.add(code);
      });

      SunmiScannerService.instance.setProcessing(true);

      final ByteData message =
          const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onBarcodeScanned', {'code': '7799999999999'}),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('com.izisoluciones.kiosco/sunmi_scanner', message, (ByteData? reply) {});

      expect(received, isEmpty);

      SunmiScannerService.instance.setProcessing(false);

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('com.izisoluciones.kiosco/sunmi_scanner', message, (ByteData? reply) {});

      expect(received, contains('7799999999999'));
      await sub.cancel();
    });
  });
}
