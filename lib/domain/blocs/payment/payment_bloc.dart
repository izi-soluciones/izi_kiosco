import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/new_order_dto.dart';
import 'package:izi_kiosco/domain/dto/payment_attempt_dto.dart';
import 'package:izi_kiosco/domain/dto/payment_dto.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/payment_method.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
part 'payment_state.dart';
part 'payment_inputs.dart';

class PaymentBloc extends Cubit<PaymentState> {
  final ComandaRepository _comandaRepository;
  StreamSubscription? qrStream;
  final BusinessRepository _businessRepository;
  final SocketRepository _socketRepository;
  PaymentBloc(
      this._comandaRepository, this._businessRepository, this._socketRepository)
      : super(PaymentState.init());

  initOrder(
      {required PaymentObj paymentObj, required AuthState authState}) async {
    try {
      bool usaSiat = false;
      int casaMatrizIndex = authState.currentContribuyente?.sucursales
              ?.indexWhere((element) =>
                  element.id == authState.currentDevice?.sucursal) ??
          -1;
      if (casaMatrizIndex != -1) {
        usaSiat = authState.currentContribuyente?.sucursales?[casaMatrizIndex]
                .config["siat"] !=
            null;
      }

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

      List<DocumentType>? documentTypes;
      DocumentType? documentType;

      if (usaSiat) {
        documentTypes = await _businessRepository.getDocumentTypes();
        documentType = documentTypes.lastOrNull;
      }
      int indexCurrency = authState.currencies.indexWhere((element) =>
          element.id ==
          authState.currentContribuyente?.config["monedaInventario"]);
      Currency? currentCurrency;
      if (indexCurrency != -1) {
        currentCurrency = authState.currencies.elementAtOrNull(indexCurrency);
      }

      List<PaymentMethod> paymentMethods =
          await _businessRepository.getPaymentMethods();
      String? economicActivity;

      if (authState.currentContribuyente?.config?["aERestaurante"] != null) {
        if (authState.currentContribuyente?.config?["aERestaurante"] is num) {
          economicActivity = authState
              .currentContribuyente?.config?["aERestaurante"]
              ?.toString();
        } else if (authState.currentContribuyente?.config?["aERestaurante"]
            is String) {
          economicActivity =
              authState.currentContribuyente?.config?["aERestaurante"];
        } else if (authState.currentContribuyente?.config?["aERestaurante"]
                is Map &&
            authState.currentContribuyente?.config?["aERestaurante"]
                    ?["codigoCaeb"] !=
                null) {
          economicActivity = authState
              .currentContribuyente?.config?["aERestaurante"]?["codigoCaeb"];
        }
      }

      if (authState.currentContribuyente?.config?["aERestaurante"] == null) {
        return emit(state.copyWith(status: PaymentStatus.errorActivity));
      }

      emit(state.copyWith(
          status: PaymentStatus.successGet,
          casaMatriz: (casaMatrizIndex != -1)
              ? (authState.currentContribuyente?.sucursales?[casaMatrizIndex])
              : null,
          step: 1,
          economicActivity: economicActivity,
          paymentMethods: paymentMethods,
          currentCurrency: currentCurrency,
          usaSiat: usaSiat,
          paymentObj: paymentObj,
          documentTypes: documentTypes,
          documentType: documentType,
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
  }

  changeInputs(
      {int? cashRegister,
      bool? withException,
      bool? isManual,
      int? documentType,
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
    if (cashRegister != null) {
      emit(state.copyWith(
          currentCashRegister: state.cashRegisters
              .firstWhere((element) => element.id == cashRegister)));
    }

    if (isManual != null) {
      emit(state.copyWith(isManual: isManual));
    }

    if (withException != null) {
      emit(state.copyWith(withException: withException));
    }

    if (documentType != null) {
      emit(state.copyWith(
          documentType: state.documentTypes.firstWhere(
              (element) => element.codigoClasificador == documentType)));
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
    if (state.payments.fold(
            0,
            (previousValue, element) =>
                previousValue + (element.id != null ? 1 : 0)) >
        0) {
      emit(state.copyWith(step: 4));
      return;
    }
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
            await _comandaRepository.markAsCreated(state.paymentObj?.id ?? 0);
        if (comanda.custom is Map && comanda.custom["simphony"]?["header"]?["checkNumber"]!=null) {
          _printRolloOrder(authState,
              orderNumber: (comanda.custom["simphony"]["header"]["checkNumber"] as int),
              customOrderNumber:null,errorSimphony: comanda.custom["errorSimphony"]==true,eatOut: true);
        }
        emit(state.copyWith(
            step: comanda.custom is Map && comanda.custom["errorSimphony"]==true?6:5,
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
      emit(state.copyWith(
          paymentType: paymentType,
          step: 2,
          qrWait: false,
          qrLoading: false,
          qrCharge: () => null));
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(status: PaymentStatus.markCreateError));
      emit(state.copyWith(status: PaymentStatus.successGet));
    }
  }

  markPaidQr() {
    emit(state.copyWith(step: 3, paymentType: PaymentType.qr));
  }

  addPayment() {
    List<Payment> payments = List.of(state.payments);
    payments.add(Payment());
    emit(state.copyWith(payments: payments));
  }

  changePaymentAmount(int index, num? amount) {
    List<Payment> payments = List.of(state.payments);
    payments[index] = Payment(monto: amount);
    emit(state.copyWith(payments: payments));
  }

  removePayment(int index) {
    List<Payment> payments = List.of(state.payments);
    payments.removeAt(index);
    emit(state.copyWith(payments: payments));
  }

  bool _validateInputs() {
    emit(state.copyWith(
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

    return true;
  }

  @override
  Future<void> close() async {
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

      var documentType = state.documentType;
      if (state.documentNumber.value.isEmpty && state.usaSiat) {
        documentType = state.documentTypes.first;
      }
      PaymentAttemptDto newPayment = PaymentAttemptDto(
          uuid: state.paymentObj?.uuid ?? "",
          metodoPago: AppConstants.idPaymentMethodPOS,
          tipoDocumento: documentType?.toJson() ?? {},
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
          telefonoComprador: state.phoneNumber.value);

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
              amount: (state.paymentObj?.amount ?? 0).moneyFormat(),
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
          await _comandaRepository.markPaymentATC(charge.token ?? '',
              state.paymentObj?.uuid ?? "", charge.intentoPago);
          success = true;
          break;
        } catch (e) {
          await Future.delayed(Duration(seconds: 1 * (i + 1)));
          log(e.toString());
        }
      }
      if (!success) {
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
      emit(state.copyWith(status: PaymentStatus.cardError,step: 2));
      emit(state.copyWith(status: PaymentStatus.successGet));
      return false;
    }
  }

  Future<bool> _makeCardOrderPayment(AuthState authState,
      {bool atc = false, bool linkser = false, bool contactless = true}) async {
    try {
      emit(state.copyWith(step: 4));
      PaymentDto newPayment = PaymentDto(
          orderId: state.paymentObj?.id ?? 0,
          date: DateTime.now(),
          monto: state.paymentObj?.amount ?? 0,
          metodoPago: AppConstants.idPaymentMethodPOS,
          moneda: state.currentCurrency?.simbolo == "Bs"
              ? "BOB"
              : state.currentCurrency?.simbolo ?? "BOB",
          monedaId:
              state.currentCurrency?.id ?? AppConstants.defaultCurrencyId);

      Charge charge = await _comandaRepository.generatePayment(
          contribuyenteId: authState.currentContribuyente?.id ?? 0,
          payment: newPayment);
      await _saveAndListenPaymentOrder(authState, charge);
      CardPayment cardPayment;

      emit(state.copyWith(status: PaymentStatus.cardProcessing));
      if (linkser) {
        cardPayment = await _comandaRepository.callCardPayment(
            amount: _getIntFromDecimal(
                _roundToNDecimals(state.paymentObj?.amount ?? 0, 2)),
            ip: authState.currentDevice!.config.ipLinkser!);
      } else {
        try {
          cardPayment = await _comandaRepository.callCardPaymentATC(
              amount: (state.paymentObj?.amount ?? 0).moneyFormat(),
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
          await _comandaRepository.markPaymentATC(
              charge.token ?? '', charge.uuid, null);
          success = true;
          break;
        } catch (e) {
          await Future.delayed(Duration(seconds: 1 * (i + 1)));
          log(e.toString());
        }
      }
      if (!success) {
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
      emit(state.copyWith(status: PaymentStatus.cardError,step: 2));
      emit(state.copyWith(status: PaymentStatus.successGet));
      return false;
    }
  }

  Future<bool> makeCardPayment(AuthState authState,
      {bool atc = false, bool linkser = false, bool contactless = true}) async {
    if (_validateInputs() &&
        (atc || linkser) &&
        state.paymentObj?.isComanda == true) {
      return await _makeCardOrderPayment(authState,
          atc: atc, contactless: contactless, linkser: linkser);
    } else if (_validateInputs() &&
        (atc || linkser) &&
        state.paymentObj?.isComanda == false) {
      return await _makeCardRetailPayment(authState,
          atc: atc, contactless: contactless, linkser: linkser);
    }
    return false;
  }

  Future<bool> _generateRetailQR(AuthState authState) async {
    if (authState.currentDevice?.config.demo == true) {

      var documentType = state.documentType;
      if (state.documentNumber.value.isEmpty && state.usaSiat) {
        documentType = state.documentTypes.first;
      }
      PaymentAttemptDto newPayment = PaymentAttemptDto(
          uuid: state.paymentObj?.uuid ?? "",
          metodoPago: AppConstants.idPaymentMethodPOS,
          tipoDocumento: documentType?.toJson() ?? {},
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
          telefonoComprador: state.phoneNumber.value);

      Charge charge =
          await _comandaRepository.generatePaymentAttempt(newPayment);
      await _listenPaymentRetail(authState, charge);
      emit(state.copyWith(status: PaymentStatus.processingOrder));
      var success = false;
      for (var i = 0; i < 10; i++) {
        try {
          await _comandaRepository.markPaymentATC(charge.token ?? '',
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
    var documentType = state.documentType;
    if (state.documentNumber.value.isEmpty && state.usaSiat) {
      documentType = state.documentTypes.first;
    }
    PaymentAttemptDto newPayment = PaymentAttemptDto(
        uuid: state.paymentObj?.uuid ?? "",
        metodoPago: AppConstants.idPaymentMethodQR,
        tipoDocumento: documentType?.toJson() ?? {},
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
        telefonoComprador: state.phoneNumber.value);

    Charge charge = await _comandaRepository.generatePaymentAttempt(newPayment);
    await _listenPaymentRetail(authState, charge);
    emit(state.copyWith(qrCharge: () => charge, qrLoading: false));
    return true;
  }

  Future<bool> _generateOrderQR(AuthState authState) async {
    if (authState.currentDevice?.config.demo == true) {
      PaymentDto newPayment = PaymentDto(
          orderId: state.paymentObj?.id ?? 0,
          date: DateTime.now(),
          monto: state.paymentObj?.amount ?? 0,
          metodoPago: AppConstants.idPaymentMethodPOS,
          moneda: state.currentCurrency?.simbolo == "Bs"
              ? "BOB"
              : state.currentCurrency?.simbolo ?? "BOB",
          monedaId:
              state.currentCurrency?.id ?? AppConstants.defaultCurrencyId);

      Charge charge = await _comandaRepository.generatePayment(
          contribuyenteId: authState.currentContribuyente?.id ?? 0,
          payment: newPayment);
      await _saveAndListenPaymentOrder(authState, charge);
      emit(state.copyWith(status: PaymentStatus.processingOrder));
      var success = false;
      for (var i = 0; i < 10; i++) {
        try {
          await _comandaRepository.markPaymentATC(
              charge.token ?? '', charge.uuid, null);
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
    PaymentDto qr = PaymentDto(
        orderId: state.paymentObj?.id ?? 0,
        date: DateTime.now(),
        metodoPago: AppConstants.idPaymentMethodQR,
        monto: state.paymentObj?.amount ?? 0,
        moneda: state.currentCurrency?.simbolo == "Bs"
            ? "BOB"
            : state.currentCurrency?.simbolo ?? "BOB",
        monedaId: state.currentCurrency?.id ?? AppConstants.defaultCurrencyId);

    Charge charge = await _comandaRepository.generatePayment(
        contribuyenteId: authState.currentContribuyente?.id ?? 0, payment: qr);
    await _saveAndListenPaymentOrder(authState, charge);
    emit(state.copyWith(qrCharge: () => charge, qrLoading: false));
    return true;
  }

  Timer? timerSuccess;
  Future<bool> generateQR(AuthState authState) async {
    try {
      if (_validateInputs()) {
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
      emit(state.copyWith(step: 2, status: PaymentStatus.successGet));
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
          try {
            if (event["idFactura"] is int) {
              await _printRollo(authState, idInvoice: event["idFactura"]);
            }
          } catch (_) {}
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

  _saveAndListenPaymentOrder(AuthState authState, Charge charge) async {
    var newOrderDto = NewOrderDto(
        caja: 0,
        cantidadComensales: 0,
        nombreMesa: "nombreMesa",
        descuentos: 0,
        emisor: "",
        fecha: DateTime.now(),
        listaItems: [],
        deviceId: authState.currentDevice?.id ?? 0,
        mesa: "mesa",
        paraLlevar: true,
        tipoComanda: AppConstants.restaurantEnv,
        sucursal: 0);
    Map custom = {};
    if (state.paymentObj?.custom is Map) {
      custom = state.paymentObj!.custom;
    }
    newOrderDto.id = state.paymentObj?.id;

    var documentType = state.documentType;
    if (state.documentNumber.value.isEmpty && state.usaSiat) {
      documentType = state.documentTypes.first;
    }
    custom["pagadorData"] = {
      "tipoDocumento": documentType?.toJson(),
      "nit":
          state.documentNumber.value.isEmpty ? "0" : state.documentNumber.value,
      "complemento":
          AppConstants.ciList.contains(state.complement.value.toLowerCase()) ||
                  state.documentNumber.value.isEmpty
              ? null
              : state.complement.value,
      "razonSocial":
          state.businessName.value.isEmpty ? "S/N" : state.businessName.value,
      "telefonoComprador": state.phoneNumber.value
    };
    newOrderDto.clienteNombre =
        state.businessName.value.isNotEmpty ? state.businessName.value : null;

    newOrderDto.custom = custom;
    await _comandaRepository.editOrder(newOrder: newOrderDto);
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
          try {
            if (event["numeroOrden"] is int) {
              await _printRolloOrder(authState,
                  orderNumber: event["numeroOrden"],
                  customOrderNumber: event["numeroCustom"] is int
                      ? event["numeroCustom"]
                      : null, errorSimphony: event["errorSimphony"] is bool?event["errorSimphony"]:false, eatOut: false);
            }
            if (kIsWeb) {
              await Future.delayed(const Duration(milliseconds: 1500));
            }
            if (event["idFactura"] is int) {
              await _printRollo(authState, idInvoice: event["idFactura"]);
            }
          } catch (_) {}
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
            const Duration(seconds: 300),
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
          emit(state.copyWith(status: PaymentStatus.processingOrder,qrCharge: ()=>null, qrLoading: false));
        }
      },
    );
  }

  Future<void> queryBusiness({required AuthState authState}) async {
    if (state.documentNumber.value.length < 3) {
      return;
    }
    emit(state.copyWith(
        documentNumber: state.documentNumber.changeLoading(true)));
    List<Contribuyente> businessList =
        await _businessRepository.queryBusinessSearch(
            query: state.documentNumber.value,
            contribuyenteId: authState.currentContribuyente?.id ?? 0);
    Contribuyente? find = businessList.firstWhereOrNull(
        (element) => element.nit == state.documentNumber.value);
    emit(state.copyWith(
        businessName: state.businessName.changeValue(find?.razonSocial ?? ""),
        documentNumber: state.documentNumber.changeLoading(false)));
  }

  cancelQR(){
    emit(state.copyWith(step: 2,qrLoading: false,qrCharge: ()=>null));
  }

  _printRolloOrder(AuthState authState,
      {required int orderNumber, int? customOrderNumber, bool? errorSimphony, required bool eatOut}) async {
    var tmp = await PrintTemplate.order80(
        orderNumber,
        customOrderNumber,
        authState.currentContribuyente!,
        authState.currentSucursal!,
        state.paymentObj,
        errorSimphony ?? false,
    eatOut);
    var printUtils = PrintUtils();
    await printUtils.print(tmp);
  }

  _printRollo(AuthState authState, {int? idInvoice, Invoice? invoice}) async {
    if (idInvoice == null && invoice == null) {
      return;
    }
    if (idInvoice != null) {
      invoice = await _comandaRepository.getInvoice(idInvoice);
    }
    var tmp = await PrintTemplate.invoice80(
        invoice!, authState.currentContribuyente!, authState.currentSucursal!);
    var printUtils = PrintUtils();
    await printUtils.print(tmp);
  }

  double _roundToNDecimals(num num, int n) {
    double multiplier = math.pow(10, n).toDouble();
    return (num * multiplier).round() / multiplier;
  }

  int _getIntFromDecimal(double num) {
    return (num * 100).toInt();
  }
}
