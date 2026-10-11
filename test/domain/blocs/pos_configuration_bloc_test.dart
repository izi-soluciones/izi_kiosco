import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/pos_configuration/pos_configuration_bloc.dart';
import 'package:izi_kiosco/domain/models/pos.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockPosRepository posRepository;

  setUp(() {
    posRepository = MockPosRepository();
  });

  final pos = Pos.fromJson({'id': 1, 'activo': true});

  group('changeIsTest', () {
    blocTest<PosConfigurationBloc, PosConfigurationState>(
      'updates the isTest flag',
      build: () => PosConfigurationBloc(posRepository, false),
      act: (bloc) => bloc.changeIsTest(true),
      expect: () => [
        isA<PosConfigurationState>().having((s) => s.isTest, 'isTest', true),
      ],
    );
  });

  group('activatePos', () {
    blocTest<PosConfigurationBloc, PosConfigurationState>(
      'emits waiting -> success -> init on success',
      setUp: () {
        when(() => posRepository.activatePos(
                contribuyente: any(named: 'contribuyente'),
                sucursal: any(named: 'sucursal'),
                isTest: any(named: 'isTest')))
            .thenAnswer((_) async => pos);
      },
      build: () => PosConfigurationBloc(posRepository, true),
      act: (bloc) => bloc.activatePos(authState: AuthState.init()),
      expect: () => [
        isA<PosConfigurationState>().having(
            (s) => s.status, 'status', PosConfigurationStatus.waitingActivate),
        isA<PosConfigurationState>().having(
            (s) => s.status, 'status', PosConfigurationStatus.successActivate),
        isA<PosConfigurationState>()
            .having((s) => s.status, 'status', PosConfigurationStatus.init),
      ],
      verify: (_) {
        verify(() => posRepository.activatePos(
            contribuyente: 0, sucursal: 0, isTest: true)).called(1);
      },
    );

    blocTest<PosConfigurationBloc, PosConfigurationState>(
      'emits waiting -> error -> init when the repository throws',
      setUp: () {
        when(() => posRepository.activatePos(
                contribuyente: any(named: 'contribuyente'),
                sucursal: any(named: 'sucursal'),
                isTest: any(named: 'isTest')))
            .thenThrow(Exception('boom'));
      },
      build: () => PosConfigurationBloc(posRepository, true),
      act: (bloc) => bloc.activatePos(authState: AuthState.init()),
      expect: () => [
        isA<PosConfigurationState>().having(
            (s) => s.status, 'status', PosConfigurationStatus.waitingActivate),
        isA<PosConfigurationState>().having(
            (s) => s.status, 'status', PosConfigurationStatus.errorActivate),
        isA<PosConfigurationState>()
            .having((s) => s.status, 'status', PosConfigurationStatus.init),
      ],
    );
  });

  group('changeEnvironment', () {
    blocTest<PosConfigurationBloc, PosConfigurationState>(
      'emits waiting -> success (with new isTest) -> init',
      setUp: () {
        when(() => posRepository.updateEnvironment(
                posId: any(named: 'posId'), isTest: any(named: 'isTest')))
            .thenAnswer((_) async => pos);
      },
      build: () => PosConfigurationBloc(posRepository, false),
      act: (bloc) => bloc.changeEnvironment(true, AuthState.init()),
      expect: () => [
        isA<PosConfigurationState>().having((s) => s.status, 'status',
            PosConfigurationStatus.waitingChangeEnvironment),
        isA<PosConfigurationState>()
            .having((s) => s.status, 'status',
                PosConfigurationStatus.successChangeEnvironment)
            .having((s) => s.isTest, 'isTest', true),
        isA<PosConfigurationState>()
            .having((s) => s.status, 'status', PosConfigurationStatus.init),
      ],
    );
  });
}
