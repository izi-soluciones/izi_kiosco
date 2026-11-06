import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/add_kiosk/add_kiosk_bloc.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/add_kiosk_dto.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerCommonFallbacks);

  late MockAuthRepository authRepository;
  late MockBusinessRepository businessRepository;

  setUp(() {
    authRepository = MockAuthRepository();
    businessRepository = MockBusinessRepository();
  });

  AddKioskBloc build() => AddKioskBloc(authRepository, businessRepository);

  final dto = AddKioskDto(
      name: 'Kiosk', branchOffice: 1, cashRegister: 1, business: 1);

  group('getCashRegisters', () {
    blocTest<AddKioskBloc, AddKioskState>(
      'emits waiting -> okCashRegister with the registers',
      setUp: () {
        when(() => businessRepository.getCashRegisters(
                contribuyenteId: any(named: 'contribuyenteId'),
                sucursalId: any(named: 'sucursalId')))
            .thenAnswer((_) async => [buildCashRegister()]);
      },
      build: build,
      act: (bloc) => bloc.getCashRegisters(5, AuthState.init()),
      expect: () => [
        isA<AddKioskState>()
            .having((s) => s.status, 'status', AddKioskStatus.waiting),
        isA<AddKioskState>()
            .having((s) => s.status, 'status', AddKioskStatus.okCashRegister)
            .having((s) => s.cashRegisters.length, 'count', 1),
      ],
    );

    blocTest<AddKioskBloc, AddKioskState>(
      'emits waiting -> errorCashRegister -> init on failure',
      setUp: () {
        when(() => businessRepository.getCashRegisters(
                contribuyenteId: any(named: 'contribuyenteId'),
                sucursalId: any(named: 'sucursalId')))
            .thenThrow(Exception('nope'));
      },
      build: build,
      act: (bloc) => bloc.getCashRegisters(5, AuthState.init()),
      expect: () => [
        isA<AddKioskState>()
            .having((s) => s.status, 'status', AddKioskStatus.waiting),
        isA<AddKioskState>().having(
            (s) => s.status, 'status', AddKioskStatus.errorCashRegister),
        isA<AddKioskState>()
            .having((s) => s.status, 'status', AddKioskStatus.init),
      ],
    );
  });

  group('save', () {
    blocTest<AddKioskBloc, AddKioskState>(
      'emits waiting -> okSave on success',
      setUp: () {
        when(() => authRepository.addDevice(any())).thenAnswer((_) async {});
      },
      build: build,
      act: (bloc) => bloc.save(dto),
      expect: () => [
        isA<AddKioskState>()
            .having((s) => s.status, 'status', AddKioskStatus.waiting),
        isA<AddKioskState>()
            .having((s) => s.status, 'status', AddKioskStatus.okSave),
      ],
      verify: (_) => verify(() => authRepository.addDevice(dto)).called(1),
    );

    blocTest<AddKioskBloc, AddKioskState>(
      'emits waiting -> errorSave -> init on failure',
      setUp: () {
        when(() => authRepository.addDevice(any())).thenThrow(Exception('x'));
      },
      build: build,
      act: (bloc) => bloc.save(dto),
      expect: () => [
        isA<AddKioskState>()
            .having((s) => s.status, 'status', AddKioskStatus.waiting),
        isA<AddKioskState>()
            .having((s) => s.status, 'status', AddKioskStatus.errorSave),
        isA<AddKioskState>()
            .having((s) => s.status, 'status', AddKioskStatus.init),
      ],
    );
  });
}
