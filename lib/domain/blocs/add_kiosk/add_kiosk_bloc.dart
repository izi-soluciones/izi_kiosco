import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/add_kiosk_dto.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/repositories/auth_repository.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';

part 'add_kiosk_state.dart';
class AddKioskBloc extends Cubit<AddKioskState>{
  final AuthRepository _authRepository;
  final BusinessRepository _businessRepository;
  AddKioskBloc(this._authRepository,this._businessRepository)
      : super(AddKioskState.init());


  getCashRegisters(int sucursal,AuthState authState)async {
    try{
      emit(state.copyWith(status: AddKioskStatus.waiting));
      var cashRegisters = await _businessRepository.getCashRegisters(contribuyenteId: authState.currentContribuyente?.id??0, sucursalId: sucursal);
      emit(state.copyWith(status: AddKioskStatus.okCashRegister,cashRegisters: cashRegisters));
    }
    catch(e){
      emit(state.copyWith(status: AddKioskStatus.errorCashRegister));
      emit(state.copyWith(status: AddKioskStatus.init));
    }
  }

  save(AddKioskDto addKioskDto)async {
    try{
      emit(state.copyWith(status: AddKioskStatus.waiting));
      await _authRepository.addDevice(addKioskDto);
      emit(state.copyWith(status: AddKioskStatus.okSave));
    }
    catch(e){
      emit(state.copyWith(status: AddKioskStatus.errorSave));
      emit(state.copyWith(status: AddKioskStatus.init));
    }

  }
}