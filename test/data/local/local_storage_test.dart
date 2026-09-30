import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/data/local/local_storage_credentials.dart';
import 'package:izi_kiosco/data/local/local_storage_first_configuration.dart';
import 'package:izi_kiosco/data/local/local_storage_room.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStorageFirstConfiguration', () {
    test('save/get/delete boolean flag', () async {
      expect(await LocalStorageFirstConfiguration.getFirstConfiguration(),
          isNull);
      await LocalStorageFirstConfiguration.saveFirstConfiguration(true);
      expect(await LocalStorageFirstConfiguration.getFirstConfiguration(),
          isTrue);
      await LocalStorageFirstConfiguration.deleteFirstConfiguration();
      expect(await LocalStorageFirstConfiguration.getFirstConfiguration(),
          isNull);
    });
  });

  group('LocalStorageCardErrors', () {
    test('defaults to an empty list', () async {
      expect(await LocalStorageCardErrors.getErrors(), isEmpty);
    });

    test('appends errors preserving order (accumulates)', () async {
      await LocalStorageCardErrors.saveCardErrors('e1');
      await LocalStorageCardErrors.saveCardErrors('e2');
      expect(await LocalStorageCardErrors.getErrors(), ['e1', 'e2']);
    });
  });

  group('LocalStorageCredentials', () {
    test('encrypts and restores email/password', () async {
      await LocalStorageCredentials.saveCredentials('secret', 'user@izi.com');
      final creds = await LocalStorageCredentials.getCredentials();
      expect(creds, isNotNull);
      expect(creds!.email, 'user@izi.com');
      expect(creds.password, 'secret');
    });

    test('stored value is not plaintext', () async {
      await LocalStorageCredentials.saveCredentials('secret', 'user@izi.com');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('lsc');
      expect(raw, isNotNull);
      expect(raw, isNot(contains('secret')));
    });

    test('returns null when nothing is stored', () async {
      expect(await LocalStorageCredentials.getCredentials(), isNull);
    });

    test('delete removes the stored credentials', () async {
      await LocalStorageCredentials.saveCredentials('p', 'e@e.e');
      await LocalStorageCredentials.deleteCredentials();
      expect(await LocalStorageCredentials.getCredentials(), isNull);
    });
  });

  group('LocalStorageRoom', () {
    test('save/get round trip', () async {
      expect(await LocalStorageRoom.getRoom(), isNull);
      await LocalStorageRoom.saveRoom('room-1');
      expect(await LocalStorageRoom.getRoom(), 'room-1');
    });

    // KNOWN BUG: deleteRoom() removes the "lsc" (credentials) key instead of
    // "room", so it does NOT actually delete the stored room. This test pins
    // the current (buggy) behavior so a future fix flips it deliberately.
    test('deleteRoom does not remove the room (documents lsc-key bug)',
        () async {
      await LocalStorageRoom.saveRoom('room-1');
      await LocalStorageRoom.deleteRoom();
      expect(await LocalStorageRoom.getRoom(), 'room-1',
          reason: 'deleteRoom currently removes the wrong key ("lsc")');
    });

    test('deleteRoom wrongly clears credentials instead', () async {
      await LocalStorageCredentials.saveCredentials('p', 'e@e.e');
      await LocalStorageRoom.deleteRoom();
      expect(await LocalStorageCredentials.getCredentials(), isNull,
          reason: 'deleteRoom removes the "lsc" key used by credentials');
    });
  });
}
