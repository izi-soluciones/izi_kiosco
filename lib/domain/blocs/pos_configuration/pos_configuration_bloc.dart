import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/models/pos.dart';
import 'package:izi_kiosco/domain/repositories/pos_repository.dart';
import 'dart:developer' as developer;
part 'pos_configuration_state.dart';

class PosConfigurationBloc extends Cubit<PosConfigurationState> {
  final PosRepository _posRepository;
  PosConfigurationBloc(this._posRepository,bool isTest)
      : super(PosConfigurationState.init(isTest));

  Future<Pos?> activatePos({required AuthState authState}) async {
    try {
      emit(state.copyWith(status: PosConfigurationStatus.waitingActivate));
      Pos pos = await _posRepository.activatePos(
          contribuyente: authState.currentContribuyente?.id ?? 0,
          sucursal: authState.currentSucursal?.id ?? 0,
        isTest: state.isTest
      );

      emit(state.copyWith(status: PosConfigurationStatus.successActivate));
      emit(state.copyWith(status: PosConfigurationStatus.init));
      return pos;
    } catch (error) {
      developer.log(error.toString());
      emit(state.copyWith(status: PosConfigurationStatus.errorActivate));
      emit(state.copyWith(status: PosConfigurationStatus.init));
      return null;
    }
  }

  changeIsTest(bool isTest){
    emit(state.copyWith(isTest: isTest));
  }
  Future<Pos?> changeEnvironment(bool isTest,AuthState authState)async{
    try {
      emit(state.copyWith(status: PosConfigurationStatus.waitingChangeEnvironment));
      Pos pos = await _posRepository.updateEnvironment(
        posId: authState.currentPos?.id??0,
          isTest: state.isTest
      );

      emit(state.copyWith(status: PosConfigurationStatus.successChangeEnvironment,isTest: isTest));
      emit(state.copyWith(status: PosConfigurationStatus.init));
      return pos;
    } catch (error) {
      developer.log(error.toString());
      emit(state.copyWith(status: PosConfigurationStatus.errorChangeEnvironment));
      emit(state.copyWith(status: PosConfigurationStatus.init));
      return null;
    }
  }
}
