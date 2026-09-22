import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/utils/business_utils.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/data/utils/user_utils.dart';
import 'package:izi_kiosco/domain/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TokenUtils', () {
    test('auth token save/get/delete', () async {
      expect(await TokenUtils.getToken(), isNull);
      await TokenUtils.saveToken('abc');
      expect(await TokenUtils.getToken(), 'abc');
      await TokenUtils.deleteToken();
      expect(await TokenUtils.getToken(), isNull);
    });

    test('refresh token round trip', () async {
      await TokenUtils.saveRefreshToken('rt');
      expect(await TokenUtils.getRefreshToken(), 'rt');
      await TokenUtils.deleteRefreshToken();
      expect(await TokenUtils.getRefreshToken(), isNull);
    });

    test('card token round trip', () async {
      await TokenUtils.saveTokenCard('ct');
      expect(await TokenUtils.getTokenCard(), 'ct');
      await TokenUtils.deleteTokenCard();
      expect(await TokenUtils.getTokenCard(), isNull);
    });

    test('pos ip round trip', () async {
      await TokenUtils.savePosIp('10.0.0.1:8081');
      expect(await TokenUtils.getPosIp(), '10.0.0.1:8081');
      await TokenUtils.deletePosIp();
      expect(await TokenUtils.getPosIp(), isNull);
    });

    test('pos token round trip', () async {
      await TokenUtils.savePosToken('pt');
      expect(await TokenUtils.getPosToken(), 'pt');
      await TokenUtils.deletePosToken();
      expect(await TokenUtils.getPosToken(), isNull);
    });

    test('tokens are stored under independent keys', () async {
      await TokenUtils.saveToken('a');
      await TokenUtils.saveRefreshToken('b');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), 'a');
      expect(prefs.getString('rt'), 'b');
    });
  });

  group('BusinessUtils', () {
    test('deviceId round trip', () async {
      expect(await BusinessUtils.getDeviceId(), isNull);
      await BusinessUtils.saveDeviceId(11);
      expect(await BusinessUtils.getDeviceId(), 11);
      await BusinessUtils.deleteDeviceId();
      expect(await BusinessUtils.getDeviceId(), isNull);
    });

    test('sucursalId round trip', () async {
      await BusinessUtils.saveSucursalId(22);
      expect(await BusinessUtils.getSucursalId(), 22);
      await BusinessUtils.deleteSucursalId();
      expect(await BusinessUtils.getSucursalId(), isNull);
    });

    test('contribuyenteId round trip', () async {
      await BusinessUtils.saveContribuyenteId(33);
      expect(await BusinessUtils.getContribuyenteId(), 33);
      await BusinessUtils.deleteContribuyenteId();
      expect(await BusinessUtils.getContribuyenteId(), isNull);
    });
  });

  group('UserUtils', () {
    test('returns null when no user is stored', () async {
      expect(await UserUtils.getUser(), isNull);
    });

    test('serializes and restores a user', () async {
      final user = User(
          id: 'u9', nombres: 'Ana', apellidos: 'Paz', correoElectronico: 'a@b.c');
      await UserUtils.saveUser(user);
      final restored = await UserUtils.getUser();
      expect(restored, isNotNull);
      expect(restored!.id, 'u9');
      expect(restored.nombres, 'Ana');
      expect(restored.apellidos, 'Paz');
      expect(restored.correoElectronico, 'a@b.c');
    });

    test('delete removes the stored user', () async {
      await UserUtils.saveUser(
          User(id: 'u1', nombres: 'X', apellidos: 'Y'));
      await UserUtils.deleteUser();
      expect(await UserUtils.getUser(), isNull);
    });
  });
}
