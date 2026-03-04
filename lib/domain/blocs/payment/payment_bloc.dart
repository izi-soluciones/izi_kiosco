import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/payment_attempt_dto.dart';
import 'package:izi_kiosco/domain/dto/payment_dto.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/customer.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/models/identification_type.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/models/iva_responsability.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/payment_method.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/models/person_type.dart';
import 'package:izi_kiosco/domain/models/tax_responsability.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:izi_kiosco/domain/utils/crash_report.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
import 'dart:io';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
part 'payment_state.dart';
part 'payment_inputs.dart';
class PaymentConfig{
  Future Function(Contribuyente, Sucursal) setParams;
  Function(PaymentDtoVentaData) setParamsOrderPayment;
  Function(PaymentAttemptDto) setParamsPayment;
  Function(Customer customer) setParamsCustomer;
  PaymentConfig({required this.setParams, required this.setParamsOrderPayment, required this.setParamsPayment, required this.setParamsCustomer});
}
class PaymentBloc extends Cubit<PaymentState> {
  final ComandaRepository _comandaRepository;
  StreamSubscription? qrStream;
  final BusinessRepository _businessRepository;
  final SocketRepository _socketRepository;
  PaymentConfig? countryConfig;
  CancelToken cancelToken = CancelToken();

  PaymentBloc(
      this._comandaRepository, this._businessRepository, this._socketRepository)
      : super(PaymentState.init());

  initOrder(
      {required PaymentObj paymentObj, required AuthState authState}) async {
    try {

      PaymentCountryTaxes? countryTaxes =  _setCountryConfig(authState.currentContribuyente!);

      List<CashRegister> cashRegisters =
          await _businessRepository.getCashRegisters(
              contribuyenteId: authState.currentContribuyente?.id ?? 0,
              sucursalId: authState.currentSucursal?.id ?? 0);

      cashRegisters.removeWhere((element) => !element.abierta);

      if (cashRegisters.isEmpty) {
        emit(state.copyWith(status: PaymentStatus.errorCashRegisters));
        emit(state.copyWith(status: PaymentStatus.waitingGet));
        return;
      }
      int indexCashRegister = cashRegisters
          .indexWhere((element) => element.id == authState.currentDevice?.caja);
      CashRegister? currentCashRegister;
      if (indexCashRegister != -1) {
        currentCashRegister = cashRegisters.elementAtOrNull(indexCashRegister);
      } else {
        currentCashRegister = cashRegisters.firstOrNull;
        // emit(state.copyWith(status: PaymentStatus.errorCashRegisters));
        // emit(state.copyWith(status: PaymentStatus.waitingGet));
        // return;
      }

      
      int indexCurrency = authState.currencies.indexWhere((element) =>
          element.id ==
          authState.currentContribuyente?.config["monedaInventario"]);
      Currency? currentCurrency;
      if (indexCurrency != -1) {
        currentCurrency = authState.currencies.elementAtOrNull(indexCurrency);
      }
      String? economicActivity;
      if(authState.currentDevice?.config.isRetail==true){
        economicActivity = authState.currentDevice?.config.actividadEconomica;
      }
      else{
        if (authState.currentContribuyente?.config?["aERestaurante"] != null) {
          if (authState.currentContribuyente?.config?["aERestaurante"] is num) {
            economicActivity = authState.currentContribuyente?.config?["aERestaurante"]
                ?.toString();
          } else if (authState.currentContribuyente?.config?["aERestaurante"]
          is String) {
            economicActivity = authState.currentContribuyente?.config?["aERestaurante"];
          } else if (authState.currentContribuyente?.config?["aERestaurante"]
          is Map &&
              authState.currentContribuyente?.config?["aERestaurante"]
              ?["codigoCaeb"] !=
                  null) {
            economicActivity = authState.currentContribuyente?.config?["aERestaurante"]?["codigoCaeb"];
          }
        }
      }
      

      if(authState.currentContribuyente?.habilitadoFacturacion==true){
        PaymentStatus? statusVerification = authState.taxesStrategy.verifyParameters(authState.currentContribuyente, authState.currentSucursal, authState.currentDevice, economicActivity);
        if(statusVerification!=null){
          return emit(state.copyWith(status: statusVerification));
        }
      }

      await countryConfig?.setParams(authState.currentContribuyente!,authState.currentSucursal!);

      emit(state.copyWith(
          status: PaymentStatus.successGet,
          step: 1,
          economicActivity: economicActivity,
          currentCurrency: currentCurrency,
          paymentObj: paymentObj,
          countryTaxes:countryTaxes,
          cashRegisters: cashRegisters,
          currentCashRegister: currentCashRegister));
    } catch (error) {
      log(error.toString());
      emit(state.copyWith(
          status: PaymentStatus.errorGet, errorDescription: error.toString()));
      emit(state.copyWith(status: PaymentStatus.waitingGet));
    }
  }

  validateInput(
      {bool documentNumber = false,
      bool businessName = false,
      bool invoiceNumber = false,
      bool authorization = false,
      bool email = false,
      bool firstDigits = false,
      bool lastDigits = false,
      bool phoneNumber = false}) {
    if (phoneNumber) {
      emit(state.copyWith(phoneNumber: state.phoneNumber.validateError()));
      return state.phoneNumber.validateError().inputError == null;
    }

    if (documentNumber) {
      emit(state.copyWith(
          documentNumber: state.documentNumber
              .validateError(valueRequired: state.businessName.value)));
    }
    if (businessName) {
      emit(state.copyWith(
          businessName: state.businessName
              .validateError(valueRequired: state.documentNumber.value)));
    }
    if (email) {
      emit(state.copyWith(
          email: state.email
              .validateError(valueRequired: state.email.value)));
    }
  }

  resetInputs(){
      emit(state.copyWith(
          status: PaymentStatus.setInputs,
          businessName: state.businessName.changeValue(""),
          phoneNumber: state.phoneNumber.changeValue(""),
          documentNumber: state.documentNumber.changeValue(""),
          ));
    emit(state.copyWith(status: PaymentStatus.successGet));
  }

  changeInputs(
      {int? cashRegister,
      bool? withException,
      bool? isManual,
      String? documentNumber,
      String? complement,
      String? businessName,
      String? authorization,
      String? invoiceNumber,
      String? email,
        String? firstDigits,
        String? lastDigits,
      String? phoneNumber}) {
    if (phoneNumber != null) {
      emit(state.copyWith(
          phoneNumber: state.phoneNumber.changeValue(phoneNumber)));
    }
    if (isManual != null) {
      emit(state.copyWith(isManual: isManual));
    }

    if (withException != null) {
      emit(state.copyWith(withException: withException));
    }

    if (documentNumber != null) {
      emit(state.copyWith(
          documentNumber: state.documentNumber.changeValue(documentNumber)));
    }
    if (complement != null) {
      emit(
          state.copyWith(complement: state.complement.changeValue(complement)));
    }
    if (businessName != null) {
      emit(state.copyWith(
          businessName: state.businessName.changeValue(businessName)));
    }
    if (email != null) {
      emit(state.copyWith(
          email: state.email.changeValue(email)));
    }
  }

  changeCashAmount(num cash) {
    emit(state.copyWith(cashAmount: cash));
  }

  changeStep(int step) {
    emit(state.copyWith(step: step));
  }

  backReset() {
    _socketRepository.closeQrListening();
    qrStream?.cancel();
    qrStream = null;
    emit(state.copyWith(
        step: 0,
        paymentType: PaymentType.others,
        cashAmount: 0,
        qrCharge: () => null,
        qrAmount: 0,
        qrPaymentKey: -1));
  }

  selectPayment(PaymentType paymentType, AuthState authState) async {
    try {
      if (paymentType == PaymentType.cashRegister) {
        emit(state.copyWith(status: PaymentStatus.processingOrder));
        Comanda comanda =
            await _comandaRepository.markAsCreated(state.paymentObj?.uuid ?? "");
        if (comanda.numero is int) {
          _printRolloOrder(authState,
              orderNumber: (comanda.numero as int),
              customOrderNumber:
                  comanda.custom is Map && comanda.custom["numeroCustom"] is int
                      ? comanda.custom["numeroCustom"]
                      : null);
        }
        emit(state.copyWith(
            step: 5,
            status: PaymentStatus.paymentProcessed,
            paymentType: paymentType));
        timerSuccess = Timer(
          const Duration(seconds: 10),
          () async {
            emit(state.copyWith(status: PaymentStatus.successInvoice));
          },
        );
        return;
      }
      if(authState.currentContribuyente?.habilitadoFacturacion==true || authState.currentDevice?.config.isRetail!=true){
        emit(state.copyWith(
            paymentType: paymentType,
            step: 2,
            qrWait: false,
            qrLoading: false,
            qrCharge: () => null));
      }
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(status: PaymentStatus.markCreateError));
      emit(state.copyWith(status: PaymentStatus.successGet));
    }
  }

  markPaidQr() {
    emit(state.copyWith(step: 3, paymentType: PaymentType.qr));
  }

  bool _validateInputs() {
    emit(state.copyWith(
        email: state.email
            .validateError(valueRequired: state.email.value),
        documentNumber: state.documentNumber
            .validateError(valueRequired: state.businessName.value),
        businessName: state.businessName
            .validateError(valueRequired: state.documentNumber.value),
        phoneNumber: state.phoneNumber.validateError()));

    if (state.documentNumber.inputError != null) {
      return false;
    }
    if (state.businessName.inputError != null) {
      return false;
    }
    if (state.phoneNumber.inputError != null) {
      return false;
    }
    if (state.email.inputError != null) {
      return false;
    }

    return true;
  }

  @override
  Future<void> close() async {
    if (state.status != PaymentStatus.successInvoice &&
        state.status != PaymentStatus.successPayment &&
        state.status != PaymentStatus.paymentProcessed &&
        state.paymentObj != null && (state.paymentObj?.uuid ?? "").isNotEmpty) {
      // Intentamos cancelar genéricamente cualquier cobro que haya quedado pendiente
      try {
        await _comandaRepository.cancelPaymentAttempt(uuid: state.paymentObj!.uuid!);
      } catch (e) {
        log("Error al cancelar el intento de pago: $e");
      }
    }
    _socketRepository.closeQrListening();
    qrStream?.cancel();
    qrStream = null;
    timerSuccess?.cancel();
    return super.close();
  }

  Future<bool> _makeCardRetailPayment(AuthState authState,
      {bool atc = false, bool linkser = false, bool contactless = true}) async {
    try {
      emit(state.copyWith(step: 4));

      PaymentAttemptDto newPayment = PaymentAttemptDto(
          uuid: state.paymentObj?.uuid ?? "",
          metodoPago: AppConstants.idPaymentMethodPOS,
          nit: state.documentNumber.value.isEmpty
              ? "0"
              : state.documentNumber.value,
          complemento: AppConstants.ciList
                      .contains(state.complement.value.toLowerCase()) ||
                  state.documentNumber.value.isEmpty
              ? null
              : state.complement.value,
          razonSocial: state.businessName.value.isEmpty
              ? "S/N"
              : state.businessName.value,
          telefonoComprador: state.phoneNumber.value,
          correoElectronico: state.email.value.isNotEmpty?state.email.value:null
          );

      countryConfig?.setParamsPayment(newPayment);    

      Charge charge =
          await _comandaRepository.generatePaymentAttempt(newPayment);
      await _listenPaymentRetail(authState, charge);
      CardPayment cardPayment;
      if (linkser) {
        cardPayment = await _comandaRepository.callCardPayment(
            amount: _getIntFromDecimal(
                _roundToNDecimals(state.paymentObj?.amount ?? 0, 2)),
            ip: authState.currentDevice!.config.ipLinkser!);
      } else {
        try {
          cardPayment = await _comandaRepository.callCardPaymentATC(
              amount: (state.paymentObj?.amount ?? 0).moneyFormat(digitsTaxes: authState.taxesStrategy.decimals),
              ip: authState.currentDevice!.config.ipAtc!,
              cancelToken: cancelToken,
              contactless: contactless);
        } catch (e) {
          if (authState.currentDevice?.config.demo == true) {
            cardPayment =
                CardPayment(response: "", cardNumber: "", date: "", hour: "");
          } else {
            rethrow;
          }
        }
      }
      emit(state.copyWith(status: PaymentStatus.processingOrder));
      var success = false;
      for (var i = 0; i < 10; i++) {
        try {
          await _comandaRepository.markPaymentATC(
              state.paymentObj?.uuid ?? "", charge.intentoPago);
          success = true;
          break;
        } catch (e) {
          await Future.delayed(Duration(seconds: 1 * (i + 1)));
          log(e.toString());
        }
      }
      if (!success) {
        CrashReport.report("Error complete payment POS", cardPayment.toJson().toString());
        await LocalStorageCardErrors.saveCardErrors(
            jsonEncode(cardPayment.toJson()));
        emit(state.copyWith(step: 6, status: PaymentStatus.paymentProcessed));
        timerSuccess = Timer(
          const Duration(seconds: 30),
          () async {
            emit(state.copyWith(status: PaymentStatus.successInvoice));
          },
        );
        return false;
      } else {
        return true;
      }
    } catch (e) {
      log(e.toString());
      if(authState.currentContribuyente?.habilitadoFacturacion==true){
        emit(state.copyWith(status: PaymentStatus.cardError,step: 2));
      }
      else{
        emit(state.copyWith(status: PaymentStatus.cardError,step: 1));
      }
      emit(state.copyWith(status: PaymentStatus.successGet));
      return false;
    }
  }

  Future<bool> _makeCardOrderPayment(AuthState authState,
      {bool atc = false, bool linkser = false, bool contactless = true}) async {
    try {
      emit(state.copyWith(step: 4));

      PaymentDto newPayment = _buildPaymentDto(AppConstants.idPaymentMethodPOS);

      Charge charge = await _comandaRepository.generatePayment(
          contribuyenteId: authState.currentContribuyente?.id ?? 0,
          payment: newPayment);
      await _saveAndListenPaymentOrder(authState, charge);
      CardPayment cardPayment;
      if (linkser) {
        cardPayment = await _comandaRepository.callCardPayment(
            amount: _getIntFromDecimal(
                _roundToNDecimals(state.paymentObj?.amount ?? 0, 2)),
            ip: authState.currentDevice!.config.ipLinkser!);
      } else {
        try {
          cardPayment = await _comandaRepository.callCardPaymentATC(
              amount: (state.paymentObj?.amount ?? 0).moneyFormat(digitsTaxes: authState.taxesStrategy.decimals),
              cancelToken: cancelToken,
              ip: authState.currentDevice!.config.ipAtc!,
              contactless: contactless);
        } catch (e) {
          if (authState.currentDevice?.config.demo == true) {
            cardPayment =
                CardPayment(response: "", cardNumber: "", date: "", hour: "");
          } else {
            rethrow;
          }
        }
      }
      emit(state.copyWith(status: PaymentStatus.processingOrder));
      var success = false;
      for (var i = 0; i < 10; i++) {
        try {
          await _comandaRepository.markPaymentATC( charge.uuid, null);
          success = true;
          break;
        } catch (e) {
          await Future.delayed(Duration(seconds: 1 * (i + 1)));
          log(e.toString());
        }
      }
      if (!success) {
        CrashReport.report("Error complete payment POS", cardPayment.toJson().toString());
        await LocalStorageCardErrors.saveCardErrors(
            jsonEncode(cardPayment.toJson()));
        emit(state.copyWith(step: 6, status: PaymentStatus.paymentProcessed));
        timerSuccess = Timer(
          const Duration(seconds: 30),
          () async {
            emit(state.copyWith(status: PaymentStatus.successInvoice));
          },
        );
        return false;
      } else {
        return true;
      }
    } catch (e) {
      log(e.toString());
      if(authState.currentContribuyente?.habilitadoFacturacion==true){
        emit(state.copyWith(status: PaymentStatus.cardError,step: 2));
      }
      else{
        emit(state.copyWith(status: PaymentStatus.cardError,step: 1));
      }
      emit(state.copyWith(status: PaymentStatus.successGet));
      return false;
    }
  }

  Future<bool> makeCardPayment(AuthState authState,
      {bool atc = false, bool linkser = false, bool contactless = true}) async {
    if ((authState.currentContribuyente?.habilitadoFacturacion!=true||(_validateInputs() &&
        (atc || linkser))) &&
        state.paymentObj?.isComanda == true) {
      return await _makeCardOrderPayment(authState,
          atc: atc, contactless: contactless, linkser: linkser);
    } else if (((authState.currentContribuyente?.habilitadoFacturacion!=true)||(_validateInputs() &&
        (atc || linkser))) &&
        state.paymentObj?.isComanda == false) {
      return await _makeCardRetailPayment(authState,
          atc: atc, contactless: contactless, linkser: linkser);
    }
    return false;
  }

  Future<bool> _generateRetailQR(AuthState authState) async {
    if (authState.currentDevice?.config.demo == true) {
      PaymentAttemptDto newPayment = PaymentAttemptDto(
          uuid: state.paymentObj?.uuid ?? "",
          metodoPago: AppConstants.idPaymentMethodPOS,
          nit: state.documentNumber.value.isEmpty
              ? "0"
              : state.documentNumber.value,
          complemento: AppConstants.ciList
                      .contains(state.complement.value.toLowerCase()) ||
                  state.documentNumber.value.isEmpty
              ? null
              : state.complement.value,
          razonSocial: state.businessName.value.isEmpty
              ? "S/N"
              : state.businessName.value,
          telefonoComprador: state.phoneNumber.value,
          correoElectronico: state.email.value.isNotEmpty?state.email.value:null);
      countryConfig?.setParamsPayment(newPayment);

      Charge charge =
          await _comandaRepository.generatePaymentAttempt(newPayment);
      await _listenPaymentRetail(authState, charge);
      emit(state.copyWith(status: PaymentStatus.processingOrder));
      var success = false;
      for (var i = 0; i < 10; i++) {
        try {
          await _comandaRepository.markPaymentATC(
              state.paymentObj?.uuid ?? "", charge.intentoPago);
          success = true;
          break;
        } catch (e) {
          await Future.delayed(Duration(seconds: 1 * (i + 1)));
          log(e.toString());
        }
      }
      if (!success) {
        return false;
      } else {
        return true;
      }
    }

    emit(state.copyWith(qrLoading: true));
    PaymentAttemptDto newPayment = PaymentAttemptDto(
        uuid: state.paymentObj?.uuid ?? "",
        metodoPago: AppConstants.idPaymentMethodQR,
        nit: state.documentNumber.value.isEmpty
            ? "0"
            : state.documentNumber.value,
        complemento: AppConstants.ciList
                    .contains(state.complement.value.toLowerCase()) ||
                state.documentNumber.value.isEmpty
            ? null
            : state.complement.value,
        razonSocial:
            state.businessName.value.isEmpty ? "S/N" : state.businessName.value,
        telefonoComprador: state.phoneNumber.value,
          correoElectronico: state.email.value.isNotEmpty?state.email.value:null);
    countryConfig?.setParamsPayment(newPayment);

    Charge charge = await _comandaRepository.generatePaymentAttempt(newPayment);
    await _listenPaymentRetail(authState, charge);
    emit(state.copyWith(qrCharge: () => charge, qrLoading: false));
    return true;
  }

  Future<bool> _generateOrderQR(AuthState authState) async {
    if (authState.currentDevice?.config.demo == true) {

      PaymentDto newPayment = _buildPaymentDto(AppConstants.idPaymentMethodPOS);
      Charge charge = await _comandaRepository.generatePayment(
          contribuyenteId: authState.currentContribuyente?.id ?? 0,
          payment: newPayment);
      await _saveAndListenPaymentOrder(authState, charge);
      emit(state.copyWith(status: PaymentStatus.processingOrder));
      var success = false;
      for (var i = 0; i < 10; i++) {
        try {
          await _comandaRepository.markPaymentATC(charge.uuid, null);
          success = true;
          break;
        } catch (e) {
          await Future.delayed(Duration(seconds: 1 * (i + 1)));
          log(e.toString());
        }
      }
      if (!success) {
        return false;
      } else {
        return true;
      }
    }

    emit(state.copyWith(qrLoading: true));
    
    PaymentDto qr = _buildPaymentDto(AppConstants.idPaymentMethodQR);

    Charge charge = await _comandaRepository.generatePayment(
        contribuyenteId: authState.currentContribuyente?.id ?? 0, payment: qr);
    await _saveAndListenPaymentOrder(authState, charge);
    emit(state.copyWith(qrCharge: () => charge, qrLoading: false));
    return true;
  }

  Timer? timerSuccess;
  Future<bool> generateQR(AuthState authState) async {
    try {
      if (_validateInputs() || authState.currentContribuyente?.habilitadoFacturacion!=true) {
        emit(state.copyWith(step: 3));
        if (state.paymentObj?.isComanda == true) {
          return await _generateOrderQR(authState);
        } else {
          return await _generateRetailQR(authState);
        }
      }
      return false;
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(
          qrLoading: false,
          qrCharge: () => null,
          status: PaymentStatus.qrError));
      if(authState.currentContribuyente?.habilitadoFacturacion==true){
        emit(state.copyWith(step: 2, status: PaymentStatus.successGet));
      }
      else{
        emit(state.copyWith(step: 1, status: PaymentStatus.successGet));
      }
      return false;
    }
  }

  Future<bool> generateBREB(AuthState authState) async {
    try {
      if(!_validateInputs()){
        return false;
      }
      emit(state.copyWith(
        status: PaymentStatus.brebLoading,
        brebLoading: true,
        brebCharge: null,
        step: 7,
        paymentType: PaymentType.breb,
      ));

      PaymentDto newPayment =
          _buildPaymentDto(AppConstants.idPaymentMethodBreB);

      Charge charge = await _comandaRepository.generatePayment(
        contribuyenteId: authState.currentContribuyente?.id ?? 0,
        payment: newPayment,
      );

      await _saveAndListenPaymentOrder(authState, charge);

      emit(state.copyWith(
        brebCharge: charge,
        brebLoading: false,
        status: PaymentStatus.successGet,
      ));

      

      return true;
    } catch (e) {
      emit(state.copyWith(
        brebLoading: false,
        status: PaymentStatus.brebError,
        errorDescription: e.toString(),
      ));
      return false;
    }
  }


  _listenPaymentRetail(AuthState authState, Charge charge) async {
    if (isClosed) {
      return false;
    }
    if (qrStream != null) {
      _socketRepository.closeQrListening();
      qrStream?.cancel();
    }
    Timer? timer;

    Timer(
      const Duration(seconds: 15),
      () async {
        if (!isClosed) {
          emit(state.copyWith(qrWait: true));
        }
      },
    );

    qrStream = _socketRepository.listenPayment(charge: charge).listen(
      (event) async {
        if (event is Map && event["statusVenta"] == "success") {
            if (event["uuidFactura"] is String && authState.currentDevice?.config.noPrintRollo!=true) {
              await _printRollo(authState, idInvoice: event["uuidFactura"]);
            }
          if (timer != null) {
            timer!.cancel();
          }
          if (qrStream != null) {
            _socketRepository.closeQrListening();
            qrStream?.cancel();
          }
          emit(state.copyWith(step: 5, status: PaymentStatus.paymentProcessed));
          timerSuccess = Timer(
            const Duration(seconds: 10),
            () async {
              emit(state.copyWith(status: PaymentStatus.successInvoice));
            },
          );
        } else {
          timer = Timer(
            const Duration(seconds: 60),
            () async {
              emit(state.copyWith(step: 5, status: PaymentStatus.paymentProcessed));
              timerSuccess = Timer(
                const Duration(seconds: 10),
                () async {
                  emit(state.copyWith(status: PaymentStatus.successInvoice));
                },
              );
            },
          );
          emit(state.copyWith(status: PaymentStatus.processingInvoice,qrCharge: ()=>null,qrLoading: false));
        }
      },
    );
  }
  Timer? timerManual;
  Timer? timerQR;

  bool isProcessing =false;
  bool activeProcessTimer =false;
  _saveAndListenPaymentOrder(AuthState authState, Charge charge) async {
    if (isClosed) {
      return false;
    }
    if (qrStream != null) {
      _socketRepository.closeQrListening();
      qrStream?.cancel();
    }


    Timer? timeoutTimer = Timer(
        const Duration(minutes: 5),
            () {
          if (!isProcessing && !isClosed) {
            isProcessing = true;
            _socketRepository.closeQrListening();
            qrStream?.cancel();
            timerManual?.cancel();
            timerQR?.cancel();
            emit(state.copyWith(step: 6, status: PaymentStatus.paymentProcessed));
            timerSuccess = Timer(
                const Duration(seconds: 10),
                    () => emit(state.copyWith(status: PaymentStatus.successInvoice))
            );
          }
        }
    );
    timerQR = Timer(
      const Duration(seconds: 15),
          () async {
        if (!isClosed) {
          emit(state.copyWith(qrWait: true));
        }
      },
    );

    timerManual?.cancel();
    timerManual = Timer(
        const Duration(seconds: 10),
            () async{

          if(!isClosed && state.paymentObj?.uuid!=null && !activeProcessTimer){
            activeProcessTimer=true;
            for(var i=0;i<60;i++){
              if(isProcessing || isClosed){
                break;
              }
              try{
                var comanda = await _comandaRepository.getComanda(orderUuid: state.paymentObj!.uuid!);
                if(comanda.factura!=null && !isProcessing){
                  isProcessing=true;
                  if (qrStream != null) {
                    _socketRepository.closeQrListening();
                    qrStream?.cancel();
                  }
                  timerQR?.cancel();
                  timeoutTimer.cancel();
                  num? numero = comanda.numero;
                  if (comanda.custom is Map && (comanda.custom["numeroCustom"] != null)) {
                    numero = comanda.custom["numeroCustom"];
                  }
                  if(comanda.custom is Map && comanda.custom["facturaUuid"] is String){
                    await _printRollo(authState,
                        idInvoice: comanda.custom["facturaUuid"],
                        orderNumber: comanda.numero?.toInt() ?? 0,
                        customOrderNumber: numero?.toInt());
                  } else {
                    await _printRolloOrder(authState,
                        orderNumber: comanda.numero?.toInt() ?? 0,
                        customOrderNumber: numero?.toInt());
                  }
                  emit(state.copyWith(step: 5, status: PaymentStatus.paymentProcessed));
                  timerSuccess = Timer(
                    const Duration(seconds: 10),
                        () async {
                      emit(state.copyWith(status: PaymentStatus.successInvoice));
                    },
                  );
                }
              }
              catch(e){
                log("error obteniendo comanda");
              }
              await Future.delayed(const Duration(seconds: 3));
            }
          }
        }
    );
    qrStream = _socketRepository.listenPayment(charge: charge).listen(
      (event) async {
          if (event is Map && event["statusVenta"] == "success") {
            if(!isProcessing){
              isProcessing=true;
              timerManual?.cancel();
              timerQR?.cancel();
              timeoutTimer.cancel();
              try {
                if (event["uuidFactura"] is String && event["numeroOrden"] is int) {
                  await _printRollo(authState,
                      idInvoice: event["uuidFactura"],
                      orderNumber: event["numeroOrden"],
                      customOrderNumber: event["numeroCustom"] is int
                          ? event["numeroCustom"]
                          : null);
                } else if (event["numeroOrden"] is int) {
                  await _printRolloOrder(authState,
                      orderNumber: event["numeroOrden"],
                      customOrderNumber: event["numeroCustom"] is int
                          ? event["numeroCustom"]
                          : null);
                }
              } catch (_) {}
              if (qrStream != null) {
                _socketRepository.closeQrListening();
                qrStream?.cancel();
              }
              emit(state.copyWith(step: 5, status: PaymentStatus.paymentProcessed));
              timerSuccess = Timer(
                const Duration(seconds: 10),
                    () async {
                  emit(state.copyWith(status: PaymentStatus.successInvoice));
                },
              );
            }
        } else {
            emit(state.copyWith(status: PaymentStatus.processingOrder,qrCharge: ()=>null, qrLoading: false));
        }
      },
    );
  }

  Future<void> queryBusiness({required AuthState authState}) async {
    try{

      if (state.documentNumber.value.length < 3) {
        return;
      }
      emit(state.copyWith(
          documentNumber: state.documentNumber.changeLoading(true)));
      List<Customer> businessList =
          await _businessRepository.queryBusinessSearch(
              query: state.documentNumber.value,
              pais: authState.taxesStrategy.countryCode);
      Customer? find = businessList.firstWhereOrNull(
          (element) => element.nit == state.documentNumber.value);
        if(find!=null){
          countryConfig?.setParamsCustomer(find);
        } 
      emit(state.copyWith(
          businessName: state.businessName.changeValue(find?.razonSocial ?? ""),
          documentNumber: state.documentNumber.changeLoading(false),
          ));
    }
    catch(e){
      emit(state.copyWith(
          documentNumber: state.documentNumber.changeLoading(false)));
    }
  }

  cancelQR(AuthState authState){
    if(authState.currentContribuyente?.habilitadoFacturacion==true){
      emit(state.copyWith(step: 2,qrLoading: false,qrCharge: ()=>null));
    }
    else{
      emit(state.copyWith(step: 1,qrLoading: false,qrCharge: ()=>null));
    }
  }

  cancelBREB(AuthState authState) {
    emit(state.copyWith(
      step: authState.currentContribuyente?.habilitadoFacturacion == true ? 2 : 1,
      brebLoading: false,
      brebCharge: null,
    ));
  }

  _printRolloOrder(AuthState authState,
      {required int orderNumber, int? customOrderNumber}) async {
    var tmp = await PrintTemplate.order80(
        orderNumber,
        customOrderNumber,
        authState.currentContribuyente!,
        authState.currentSucursal!,
        state.paymentObj,
        state.currentCurrency,
              taxesStrategy: authState.taxesStrategy
        );
    var printUtils = PrintUtils();
    await printUtils.print(tmp, authState.currentDevice);
  }

  _printRollo(AuthState authState, {String? idInvoice, Invoice? invoice, int? orderNumber, int? customOrderNumber}) async {
    try{
      List<IziPrintItem> tmp = [];

      if (idInvoice == null && invoice == null && orderNumber == null) {
        return;
      }
      if (idInvoice != null) {
        invoice = await _comandaRepository.getInvoice(idInvoice);
      }
      if(orderNumber!=null){
        tmp = await PrintTemplate.order80(
              orderNumber,
              customOrderNumber,
              authState.currentContribuyente!,
              authState.currentSucursal!,
              state.paymentObj,
              state.currentCurrency,
              taxesStrategy: authState.taxesStrategy
          );
      }
      if(invoice==null){
        var printUtils = PrintUtils();
        await printUtils.print(tmp, authState.currentDevice);
        return;
      }

      if(authState.currentDevice?.config.facturaCompacto==true
      ){
        tmp = await PrintTemplate.printInvoiceCompact(
          authState.currentContribuyente!,
          authState.currentSucursal!,
          invoice,
          orderNumber: orderNumber,
          customOrderNumber: customOrderNumber,
              taxesStrategy: authState.taxesStrategy
        );
      }
      else{
        tmp.add(IziPrintLineWrap(lines: 2));
        if(authState.currentSucursal?.config is Map &&
          (authState.currentSucursal?.config as Map)["tipoFacturaVentas"] == "compacto"
        ){
          tmp.addAll(await PrintTemplate.printInvoiceCompact(
            authState.currentContribuyente!,
            authState.currentSucursal!,
            invoice,
              taxesStrategy: authState.taxesStrategy
          ));
        }
        else{
        tmp.addAll(await PrintTemplate.printInvoice(
            authState.currentContribuyente!, authState.currentSucursal!,invoice,
              taxesStrategy: authState.taxesStrategy));
        }
      }

      var printUtils = PrintUtils();
      await printUtils.print(tmp, authState.currentDevice);
    }
    catch(e){
      log(e.toString());
    }
  }

  double _roundToNDecimals(num num, int n) {
    double multiplier = math.pow(10, n).toDouble();
    return (num * multiplier).round() / multiplier;
  }

  int _getIntFromDecimal(double num) {
    return (num * 100).toInt();
  }

  PaymentDto _buildPaymentDto(int metodoPago){
      PaymentDtoVentaData ventaData = PaymentDtoVentaData(
        complemento: AppConstants.ciList.contains(state.complement.value.toLowerCase()) ||
                  state.documentNumber.value.isEmpty
              ? null
              : state.complement.value,
        nit: state.documentNumber.value.isEmpty ? "0" : state.documentNumber.value,
        razonSocial: state.businessName.value.isEmpty ? "S/N" : state.businessName.value,
        telefonoComprador: state.phoneNumber.value,
        correoElectronico: state.email.value
        );
      countryConfig?.setParamsOrderPayment(ventaData);
      PaymentDto newPayment = PaymentDto(
        ventaData: ventaData,
          orderId: state.paymentObj?.id ?? 0,
          metodoPago: metodoPago);
      return newPayment;
  }


  Future<void> _setParamsCo(Contribuyente contribuyente, Sucursal sucursal)async{

    List<IdentificationType>? listIdentificationType;
    List<IvaResponsability>? listIvaResponsability;
    List<PersonType>? listPersonType;
    List<TaxResponsability>? listTaxResponsability;

    IdentificationType? identificationType;
    IvaResponsability? ivaResponsability;
    PersonType? personType;
    TaxResponsability? taxResponsability;

    final results = await Future.wait([
      _businessRepository.getIdentificationType(),
      _businessRepository.getIvaResponsability(),
      _businessRepository.getPersonType(),
      _businessRepository.getTaxResponsability(),
    ]);

  listIdentificationType   = results[0] as List<IdentificationType>;
  listIvaResponsability    = results[1] as List<IvaResponsability>;
  listPersonType           = results[2] as List<PersonType>;
  listTaxResponsability    = results[3] as List<TaxResponsability>;

    identificationType = listIdentificationType.firstOrNull;
    ivaResponsability = listIvaResponsability.lastOrNull;
    personType = listPersonType.lastOrNull;
    taxResponsability = listTaxResponsability.lastOrNull;
    emit(state.copyWith(paramsCo: ParamsCo(
      identificationType: identificationType?.codigo,
      ivaResponsability: ivaResponsability?.codigo,
      personType: personType?.codigo,
      listIdentificationType: listIdentificationType,
      listIvaResponsability: listIvaResponsability,
      listPersonType: listPersonType,
      listTaxResponsability: listTaxResponsability,
      taxResponsability: taxResponsability?.codigo
    )));
  }

  void _setParamsOrderPaymentCo(PaymentDtoVentaData paymentDtoVentaData)async{
    var identificationType = state.paramsCo?.identificationType;
    var ivaResponsability = state.paramsCo?.ivaResponsability;
    var personType = state.paramsCo?.personType;
    var taxResponsability = state.paramsCo?.taxResponsability;

    if(state.documentNumber.value.isEmpty){
      paymentDtoVentaData.nit = AppConstants.defaultNitCo;
      paymentDtoVentaData.razonSocial = AppConstants.defaultRazonSocialCo;
      identificationType = AppConstants.tipoIdentificacionCo;
      ivaResponsability = AppConstants.responsabilidadIvaCo;
      personType = AppConstants.tipoPersonaCo;
      taxResponsability = AppConstants.responsabilidadFiscalCo;
    }

    if(identificationType ==null || ivaResponsability ==null || personType == null  || taxResponsability == null){
      throw "Parametros incorrectos";
    }

    paymentDtoVentaData.co= PaymentDtoVentaDataCo(
      identificationType:  identificationType,
      ivaResponsability:  ivaResponsability,
      personType:  personType,
      taxResponsability:  taxResponsability,

    );
  }

  void _setParamsOrderPaymentBo(PaymentDtoVentaData paymentDtoVentaData)async{
      var documentType = state.paramsBo?.documentType;
      if (state.documentNumber.value.isEmpty) {
        documentType = state.paramsBo?.documentTypes.first;
      }
      paymentDtoVentaData.tipoDocumento = documentType;
  }

  void _setPaymentCo(PaymentAttemptDto paymentAttemptDto)async{
  }

  void _setParamsCustomerCo(Customer customer)async{
    emit(state.copyWith(
      status: PaymentStatus.setInputs,
      paramsCo: state.paramsCo?.copyWith(
        identificationType: customer.custom?.co?.tipoIdentificacion,
        taxResponsability: customer.custom?.co?.responsabilidadFiscal,
        ivaResponsability: customer.custom?.co?.responsabilidadIva,
        personType: customer.custom?.co?.tipoPersona,
      )
    ));
    emit(state.copyWith(
      status: PaymentStatus.successGet));
  }




  Future _setParamsBo(Contribuyente contribuyente, Sucursal sucursal)async{
    List<DocumentType>? documentTypes;
    DocumentType? documentType;
    documentTypes = await _businessRepository.getDocumentTypes();
    documentType = documentTypes.lastOrNull;
    emit(state.copyWith(paramsBo: ParamsBo(documentType: documentType, documentTypes: documentTypes ?? [])));
  }
  void _setPaymentBo(PaymentAttemptDto paymentAttemptDto)async{

      var documentType = state.paramsBo?.documentType;
      if (state.documentNumber.value.isEmpty) {
        documentType = state.paramsBo?.documentTypes.first;
      }
      paymentAttemptDto.tipoDocumento=documentType?.toJson();
  }

  void _setParamsCustomerBo(Customer customer)async{
  }


  PaymentCountryTaxes? _setCountryConfig(Contribuyente contribuyente){

    if(contribuyente.habilitadoFacturacion==true){
      if(contribuyente.usaSiat==true || (contribuyente.config is Map && contribuyente.config["paisId"] == "BO")){
        countryConfig = PaymentConfig(
          setParams: _setParamsBo,
          setParamsCustomer: _setParamsCustomerBo,
          setParamsOrderPayment: _setParamsOrderPaymentBo,
          setParamsPayment: _setPaymentBo
          );
        return PaymentCountryTaxes.bolivia;
      }
      else if(contribuyente.config is Map && contribuyente.config["paisId"] == "CO"){
        countryConfig = PaymentConfig(
          setParams: _setParamsCo,
          setParamsCustomer: _setParamsCustomerCo,
          setParamsOrderPayment: _setParamsOrderPaymentCo,
          setParamsPayment: _setPaymentCo
          );
        return PaymentCountryTaxes.colombia;
      }
    }
    return null;
  }

  changeInputsBo({
      int? documentType}) {
    if (documentType != null) {
      emit(state.copyWith(
          paramsBo: state.paramsBo?.copyWith(
            documentType: state.paramsBo?.documentTypes.firstWhere(
              (element) => element.codigoClasificador == documentType)
          )));
    }
  }

  changeInputsCo({
      String? personType,
      String? taxResponsability,
      String? identificationType,
      String? ivaResponsability}) {
    if (personType != null) {
      emit(state.copyWith(
          paramsCo: state.paramsCo?.copyWith(
            personType: personType)));
    }
    if (taxResponsability != null) {
      emit(state.copyWith(
          paramsCo: state.paramsCo?.copyWith(
            taxResponsability: taxResponsability)));
    }
    if (identificationType != null) {
      if(identificationType==AppConstants.idNitCo){
        emit(state.copyWith(
          status: PaymentStatus.setInputs,
            paramsCo: state.paramsCo?.copyWith(
              
              identificationType: identificationType,
              ivaResponsability: AppConstants.defaultDataNit["ivaResponsability"],
              personType: AppConstants.defaultDataNit["personType"],
              taxResponsability: AppConstants.defaultDataNit["taxResponsability"]
              )));
        emit(state.copyWith(status: PaymentStatus.successGet));
      }
      else{
        emit(state.copyWith(
          status: PaymentStatus.setInputs,
            paramsCo: state.paramsCo?.copyWith(
              identificationType: identificationType,
              ivaResponsability: AppConstants.defaultDataOther["ivaResponsability"],
              personType: AppConstants.defaultDataOther["personType"],
              taxResponsability: AppConstants.defaultDataOther["taxResponsability"]
              )));
    emit(state.copyWith(status: PaymentStatus.successGet));
      }
    }
    if (ivaResponsability != null) {
      emit(state.copyWith(
          paramsCo: state.paramsCo?.copyWith(
            ivaResponsability: ivaResponsability)));
    }
  }
  cancelPaymentCard(){
    cancelToken.cancel();
    cancelToken = CancelToken();
  }

  Future<void> downloadQrCode() async {
    try {
      final qrUrl = state.qrCharge?.qrUrl;
      if (qrUrl == null) {
        return;
      }

      final dio = Dio();
      final response = await dio.get<List<int>>(
        qrUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';

        if (kIsWeb) {
          final base64data = base64Encode(bytes);
          final a = html.AnchorElement(href: 'data:image/png;base64,$base64data');
          a.setAttribute('download', fileName);
          a.click();
        } else {
          final status = await Permission.storage.request();
          if (status.isGranted) {
            final directory = await getApplicationDocumentsDirectory();
            final file = File('${directory.path}/$fileName');
            await file.writeAsBytes(bytes);
          } else {
          }
        }
      } else {
      }
    } catch (e) {
      log(e.toString());
    }
  }
}
