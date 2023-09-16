import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/invoice_dto.dart';
import 'package:izi_kiosco/domain/dto/new_order_dto.dart';
import 'package:izi_kiosco/domain/dto/qr_dto.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/models/economic_activity.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/payment_method.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_symbiotic/izi_symbiotic.dart';
part 'payment_state.dart';
part 'payment_inputs.dart';

class PaymentBloc extends Cubit<PaymentState> {
  final ComandaRepository _comandaRepository;
  StreamSubscription? qrStream;
  final BusinessRepository _businessRepository;
  final SocketRepository _socketRepository;
  PaymentBloc(this._comandaRepository, this._businessRepository,this._socketRepository)
      : super(PaymentState.init());


  final IziSymbiotic iziSymbiotic= IziSymbiotic();



  initOrder(
      {Comanda? order, int? orderId, required AuthState authState}) async {
    try {
      if (order != null || orderId != null) {
        bool usaSiat = false;
        int casaMatrizIndex = authState.currentContribuyente?.sucursales
                ?.indexWhere((element) => element.isCasaMatriz == true) ??
            -1;
        if (casaMatrizIndex != -1) {

          usaSiat = authState.currentContribuyente?.sucursales?[casaMatrizIndex]
                  .config["siat"] !=
              null;
        }
        Comanda defaultOrder =
            order ?? await _comandaRepository.getComanda(orderId: orderId!);

        if(defaultOrder.facturada==1){
          emit(state.copyWith(status: PaymentStatus.errorInvoiced));
          return;
        }


        int indexCurrency = authState.currencies.indexWhere((element) =>
            element.id ==
            authState.currentContribuyente?.config["monedaInventario"]);
        Currency? currentCurrency;
        if (indexCurrency != -1) {
          currentCurrency = authState.currencies.elementAtOrNull(indexCurrency);
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
        int indexCashRegister = cashRegisters.indexWhere((element) =>
            element.userOpen == authState.currentUser?.id &&
            element.userOpen != null);
        CashRegister? currentCashRegister;
        if (indexCashRegister != -1) {
          currentCashRegister =
              cashRegisters.elementAtOrNull(indexCashRegister);
        } else {
          currentCashRegister = cashRegisters.firstOrNull;
        }

        List<PaymentMethod> paymentMethods =
            await _businessRepository.getPaymentMethods();
        List<Payment> payments =
            await _businessRepository.getPayments(orderId: defaultOrder.id);
        List<DocumentType>? documentTypes;
        DocumentType? documentType;
        String? economicActivity;

        if (authState.currentContribuyente?.config?["aERestaurante"] != null) {
          if(authState.currentContribuyente?.config?["aERestaurante"] is num){
            economicActivity =
            authState.currentContribuyente?.config?["aERestaurante"]?.toString();
          }
          else if(authState.currentContribuyente?.config?["aERestaurante"] is String){
            economicActivity =
            authState.currentContribuyente?.config?["aERestaurante"];
          }
          else if(authState.currentContribuyente?.config?["aERestaurante"] is Map &&
              authState.currentContribuyente?.config?["aERestaurante"]?["codigoCaeb"] !=null){

            economicActivity =authState.currentContribuyente?.config?["aERestaurante"]?["codigoCaeb"];
          }
        }
        if (usaSiat) {
          documentTypes = await _businessRepository.getDocumentTypes();
          documentType = documentTypes.firstOrNull;

          if (authState.currentContribuyente?.config?["aERestaurante"] ==
              null) {
            List<EconomicActivity> activities =
                await _businessRepository.getEconomicActivities(
                    contribuyenteId: authState.currentContribuyente?.id ?? 0,
                    sucursalId: authState.currentSucursal?.id ?? 0);
            economicActivity = activities.firstOrNull?.codigoCaeb ?? "";
          }
        } else {
          if (authState.currentContribuyente?.config?["aERestaurante"] ==
              null) {
            economicActivity = authState.currentContribuyente
                    ?.actividadesEconomicas.firstOrNull?["id"] ??
                "";
          }
        }
        int step =0;
        if(payments.isNotEmpty){
          step = 4;
        }
        while(payments.length<2){
          payments.add(Payment());
        }
        emit(state.copyWith(
            status: PaymentStatus.successGet,

              casaMatriz:(casaMatrizIndex != -1)?(authState.currentContribuyente?.sucursales?[casaMatrizIndex]):null,
            order: defaultOrder,
            step: step,
            economicActivity: economicActivity,
            payments: payments,
            usaSiat: usaSiat,
            documentTypes: documentTypes,
            documentType: documentType,
            paymentMethods: paymentMethods,
            discountAmount: defaultOrder.descuentos,
            cashRegisters: cashRegisters,
            currentCurrency: currentCurrency,
            currentCashRegister: currentCashRegister));
      } else {
        emit(state.copyWith(status: PaymentStatus.errorGet));
        emit(state.copyWith(status: PaymentStatus.waitingGet));
      }
    } catch (error) {
      log(error.toString());
      emit(state.copyWith(
          status: PaymentStatus.errorGet, errorDescription: error.toString()));
      emit(state.copyWith(status: PaymentStatus.waitingGet));
    }
  }

  bool _validateCard(){
    emit(state.copyWith(
      firstDigits: state.firstDigits.validateError(),
      lastDigits: state.lastDigits.validateError()
    ));

    if(state.firstDigits.inputError !=null){
      return false;
    }
    if(state.lastDigits.inputError !=null){
      return false;
    }

    return true;
  }
  submitCard(){
    if(_validateCard()){
      emit(state.copyWith(step: 3));
    }
  }
  emitPaymentTotal(int idPaymentMethod,AuthState authState)async {
    try{

      List<Payment> paymentsFirst=List.of(state.payments);
      paymentsFirst[0]=Payment(monto: state.order?.monto??0,loading: true);
      paymentsFirst.removeAt(1);
      emit(state.copyWith(payments: paymentsFirst,step:4));
      var paymentMethod = state.paymentMethods.firstWhere(
              (element) => element.id == idPaymentMethod,
          orElse: () => state.paymentMethods.first);
        Payment payment = Payment();
        payment.monto=(state.order?.monto??0)-state.discountAmount;
        payment.terminosPago = paymentMethod.nombre;
        payment.metodoPago = paymentMethod.id;
        payment.moneda = state.currentCurrency?.id;
        Payment paymentNew = await _comandaRepository.addPayment(payment: payment, orderId: state.order?.id??0, contribuyente:authState.currentContribuyente?.id??0 );

        List<Payment> payments=List.of(state.payments);
        payments[0]=paymentNew;

        emit(state.copyWith(status: PaymentStatus.successPayment,payments: payments));
      emit(state.copyWith(status: PaymentStatus.successGet));
    }
    catch(error){
      emit(state.copyWith(status: PaymentStatus.errorGet, errorDescription: error.toString()));
      emit(state.copyWith(status: PaymentStatus.successGet));
    }
  }
  emitPayment(int index,int idPaymentMethod,AuthState authState)async {
    try{

      Payment? payment = state.payments.elementAtOrNull(index);
      if(payment!=null && payment.monto!=null && payment.id==null){
        List<Payment> paymentsFirst=List.of(state.payments);
        paymentsFirst[index]=Payment(monto: payment.monto,loading: true);
        emit(state.copyWith(payments: paymentsFirst));

        var paymentMethod = state.paymentMethods.firstWhere(
                (element) => element.id == idPaymentMethod,
            orElse: () => state.paymentMethods.first);
        payment.terminosPago = paymentMethod.nombre;
        payment.metodoPago = paymentMethod.id;
        payment.moneda = state.currentCurrency?.id;
        Payment paymentNew = await _comandaRepository.addPayment(payment: payment, orderId: state.order?.id??0, contribuyente:authState.currentContribuyente?.id??0 );


        List<Payment> payments=List.of(state.payments);
        payments[index]=paymentNew;
        emit(state.copyWith(payments: payments,status: PaymentStatus.successPayment));
        emit(state.copyWith(status: PaymentStatus.successGet));
      }
    }
    catch(error){
      Payment? payment = state.payments.elementAtOrNull(index);
      List<Payment> paymentsFirst=List.of(state.payments);
      paymentsFirst[index]=Payment(monto: payment?.monto,loading: false);
      emit(state.copyWith(
          payments: paymentsFirst,
          status: PaymentStatus.errorGet, errorDescription: error.toString()));
      emit(state.copyWith(status: PaymentStatus.successGet));
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
        bool phoneNumber = false
      }) {
    if(phoneNumber){
      emit(state.copyWith(phoneNumber: state.phoneNumber.validateError()));
      return state.phoneNumber.validateError().inputError==null;
    }
    if(firstDigits){
      emit(state.copyWith(firstDigits: state.firstDigits.validateError()));
    }

    if(lastDigits){
      emit(state.copyWith(lastDigits: state.lastDigits.validateError()));
    }

    if(invoiceNumber){
      emit(state.copyWith(invoiceNumber: state.invoiceNumber.validateError()));
    }
    if(authorization){
      emit(state.copyWith(authorization: state.authorization.validateError()));
    }
    if (documentNumber) {
      emit(
          state.copyWith(documentNumber: state.documentNumber.validateError()));
    }
    if (businessName) {
      emit(state.copyWith(businessName: state.businessName.validateError()));
    }
    if (email) {
      emit(state.copyWith(email: state.email.validateError()));
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
        String? phoneNumber
      }) {
    if(phoneNumber !=null){
      emit(state.copyWith(phoneNumber: state.phoneNumber.changeValue(phoneNumber)));
    }
    if(firstDigits !=null){
      emit(state.copyWith(firstDigits: state.firstDigits.changeValue(firstDigits)));
    }
    if(lastDigits !=null){
      emit(state.copyWith(lastDigits: state.lastDigits.changeValue(lastDigits)));
    }
    if(authorization !=null){
      emit(state.copyWith(authorization: state.authorization.changeValue(authorization)));
    }
    if(invoiceNumber !=null){
      emit(state.copyWith(invoiceNumber: state.invoiceNumber.changeValue(invoiceNumber)));
    }
    if (cashRegister != null) {
      emit(state.copyWith(
          currentCashRegister: state.cashRegisters
              .firstWhere((element) => element.id == cashRegister)));
    }

    if(isManual!=null){
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
    if (email != null) {
      emit(state.copyWith(email: state.email.changeValue(email)));
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
    if(state.payments.fold(0, (previousValue, element) => previousValue + (element.id!=null?1:0)) >0){
      emit(state.copyWith(step: 4));
      return;
    }
    emit(state.copyWith(
        step: 0, paymentType: PaymentType.others, cashAmount: 0, qrCharge: ()=>null,qrAmount: 0,qrPaymentKey: -1));
  }

  selectPayment(PaymentType paymentType,AuthState authState) {
    switch (paymentType) {
      case PaymentType.cash:
        if ((state.order?.monto ?? 0) - state.discountAmount == 0) {
          emit(state.copyWith(step: 3, paymentType: paymentType));
          break;
        }
        emit(state.copyWith(step: 2, paymentType: paymentType));
        break;

      case PaymentType.card:
        if(state.usaSiat){
          emit(state.copyWith(step: 6, paymentType: paymentType));
          return;
        }
        emit(state.copyWith(step: 3, paymentType: paymentType));
        break;

      case PaymentType.qr:
        if(authState.currentContribuyente?.configCobros?["QHANTUY"]?["appKey"]!=null){
          emit(state.copyWith(step: 7, qrAmount: (state.order?.monto??0)-state.discountAmount,paymentType: paymentType,qrCharge: ()=>null,qrPaymentKey: -1));
          _generateQR((state.order?.monto??0)-state.discountAmount,authState);
          return;
        }
        emit(state.copyWith(step: 3, paymentType: paymentType));
        break;

      case PaymentType.gitCard:
        emit(state.copyWith(step: 3, paymentType: paymentType));
        break;

      case PaymentType.bankTransfer:
        emit(state.copyWith(step: 3, paymentType: paymentType));
        break;

      default:
    }
  }

  generateQrPartial(num amount,int paymentKey,AuthState authState){
    emit(state.copyWith(step: 7,qrCharge: ()=>null,qrAmount: amount,qrPaymentKey: paymentKey));
    _generateQR(amount, authState,partial: true);
  }

  markPaidQr(){
    emit(state.copyWith(step: 3, paymentType:PaymentType.qr));
  }
  addPayment(){
    List<Payment> payments=List.of(state.payments);
    payments.add(Payment());
    emit(state.copyWith(payments: payments));
  }

  changePaymentAmount(int index,num? amount){
    List<Payment> payments=List.of(state.payments);
    payments[index]=Payment(monto: amount);
    emit(state.copyWith(payments: payments));
  }

  removePayment(int index){
    List<Payment> payments=List.of(state.payments);
    payments.removeAt(index);
    emit(state.copyWith(payments: payments));
  }

  changeDiscountTip({
    num? discount,
    num? tip,
  }) {
    emit(state.copyWith(discountAmount: discount, tipAmount: tip));
  }
  bool _validateInputs(){
    emit(state.copyWith(
        documentNumber: state.documentNumber.validateError(),
        businessName: state.businessName.validateError(),
      email: state.email.validateError(),
      phoneNumber: state.phoneNumber.validateError()

    ));

    if(state.documentNumber.inputError !=null){
      return false;
    }
    if(state.businessName.inputError !=null){
      return false;
    }
    if(state.email.inputError !=null){
      return false;
    }
    if(state.phoneNumber.inputError !=null){
      return false;
    }

    return true;
  }

  _generateQR(num amount,AuthState authState,{bool partial = false}) async {
    QrDto qr = QrDto(
        orderId: state.order?.id??0,
        date: DateTime.now(),
        monto: amount,
        moneda: state.currentCurrency?.simbolo == "Bs"?"BOB":state.currentCurrency?.simbolo ?? "BOB",
        monedaId: state.currentCurrency?.id ?? AppConstants.defaultCurrencyId
    );

    Charge charge = await _comandaRepository.generateQr(contribuyenteId: authState.currentContribuyente?.id??0, qr: qr);

    if(qrStream !=null){
      _socketRepository.closeQrListening();
      qrStream?.cancel();
    }
    qrStream = _socketRepository.listenQr(charge: charge).listen((event) {
      if(partial){
        List<Payment> payments=List.of(state.payments);
        PaymentMethod pm=state.paymentMethods.firstWhere((element) => element.id == AppConstants.idPaymentMethodQR);
        payments[state.qrPaymentKey??0]=Payment(
          id: charge.id,
          fromCharge: true,
          terminosPago: pm.nombre,
          metodoPago: pm.id,
          monto: amount
        );
        emit(state.copyWith(step: 4,payments: payments,qrCharge: ()=>null,qrAmount: 0,qrPaymentKey: -1));
      }
      else{
        List<Payment> payments=List.of(state.payments);
        PaymentMethod pm=state.paymentMethods.firstWhere((element) => element.id == AppConstants.idPaymentMethodQR);
        payments[0]=Payment(
            id: charge.id,
            fromCharge: true,
            terminosPago: pm.nombre,
            metodoPago: pm.id,
            monto: amount
        );
        payments.removeAt(1);
      emit(state.copyWith(step:3,paymentType: PaymentType.qr,payments: payments),);
      }
      _socketRepository.closeQrListening();
      qrStream?.cancel();
      qrStream = null;
    },);
    emit(state.copyWith(qrCharge: ()=>charge));
  }



  Future<bool?> generateOrder({required AuthState authState,bool noData = false})async{
    try{

      if((noData && validateInput(phoneNumber: true) == true) || !noData && _validateInputs()){
        emit(state.copyWith(status: PaymentStatus.waitingInvoice));

        var newOrderDto = NewOrderDto(
            caja: state.order?.caja,
            cantidadComensales: 0,
            nombreMesa: "nombreMesa",
            descuentos: 0,
            emisor: state.order?.emisor??"",
            fecha: DateTime.now(),
            listaItems: [],
            mesa: "mesa",
            paraLlevar: true,

            tipoComanda: AppConstants.restaurantEnv,
            sucursal: state.order?.sucursal??0
        );
        Map custom ={};
        if(state.order?.custom is Map){
          custom=(state.order!.custom  as Map);
        }
        newOrderDto.id=state.order?.id;
        custom["pagadorData"]={
          "tipoDocumento": state.documentType?.codigoClasificador,
          "nit":noData? "0":state.documentNumber.value,
          "complemento":noData?"":state.complement.value,
          "razonSocial":noData?"S/N":state.businessName.value,
          "correoElectronico":noData?"":state.email.value,
          "celular":noData?"":state.phoneNumber.value
        };

        newOrderDto.custom=custom;
        await _comandaRepository.editOrder(newOrder: newOrderDto);
        emit(state.copyWith(step: 8));
        await Future.delayed(const Duration(seconds: 5));
        emit(state.copyWith(status: PaymentStatus.successInvoice));
        return true;
      }
      else{
        return false;
      }
    }
    catch(err){
      log(err.toString());
      emit(state.copyWith(
          status: PaymentStatus.errorGet, errorDescription: err.toString()));
      emit(state.copyWith(status: PaymentStatus.waitingGet));
      return false;
    }
  }
  emitInvoice({bool prefactura = false, required AuthState authState,bool noData = false}) async {
    try{

      if(noData || _validateInputs()){
        emit(state.copyWith(status: prefactura?PaymentStatus.waitingPreInvoice:PaymentStatus.waitingInvoice));

        PaymentMethod? paymentMethod;

        num? pagoEnEfectivo;
        num? pagoEnTarjeta;

        if (state.paymentMethods.isNotEmpty) {
          switch (state.paymentType) {
            case PaymentType.cash:
              pagoEnEfectivo = state.cashAmount;
              paymentMethod = state.paymentMethods.firstWhere(
                      (element) => element.id == AppConstants.idPaymentMethodCash,
                  orElse: () => state.paymentMethods.first);
              break;

            case PaymentType.card:
              pagoEnTarjeta = (state.order?.monto ?? 0) - state.discountAmount;
              paymentMethod = state.paymentMethods.firstWhere(
                      (element) => element.id == AppConstants.idPaymentMethodCard,
                  orElse: () => state.paymentMethods.first);
              break;
            case PaymentType.qr:
              paymentMethod = state.paymentMethods.firstWhere(
                      (element) => element.id == AppConstants.idPaymentMethodQR,
                  orElse: () => state.paymentMethods.first);
              break;
            case PaymentType.gitCard:
              paymentMethod = state.paymentMethods.firstWhere(
                      (element) => element.id == AppConstants.idPaymentMethodGiftCard,
                  orElse: () => state.paymentMethods.first);
              break;
            case PaymentType.bankTransfer:
              paymentMethod = state.paymentMethods.firstWhere(
                      (element) => element.id == AppConstants.idPaymentMethodTransfer,
                  orElse: () => state.paymentMethods.first);
              break;
            default:
              paymentMethod = state.paymentMethods.firstWhere(
                      (element) => element.id == AppConstants.idPaymentMethodOthers,
                  orElse: () => state.paymentMethods.first);
              break;
          }
        }



        InvoiceDto invoice = InvoiceDto(
            actividadEconomica: state.economicActivity,
            caja: state.currentCashRegister?.id ?? 0,
            comprador: state.documentNumber.value,
            moneda: state.currentCurrency,
            descuentos: state.discountAmount,
            customFactura: {},
            fecha: DateTime.now(),
            metodoPago: paymentMethod?.id ?? 1,
            prefactura: prefactura,
            razonSocial: state.businessName.value,
            sucursalDireccion: authState.currentSucursal?.direccion ?? "",
            terminosPago: paymentMethod?.nombre ?? "",
            pagoEnTarjeta: pagoEnTarjeta,
            pagoEnEfectivo: pagoEnEfectivo);

        if (state.usaSiat) {
          invoice.codigoMetodoPago = paymentMethod?.codigoSiat;
          invoice.customFactura?["siat"]={"actividadEconomica":state.economicActivity};
        }

        if(state.email.value.isNotEmpty){
          invoice.correoElectronicoComprador = state.email.value;
        }

        if(state.documentType!=null){
          invoice.documentType =state.documentType;
        }
        if(state.withException){
          invoice.customFactura?["codigoExcepcion"]=1;
        }

        if (state.usaSiat
            && (paymentMethod?.id== AppConstants.idPaymentMethodCard|| paymentMethod?.id==AppConstants.idPaymentMethodOthers)) {
          if (state.firstDigits.value.isNotEmpty && state.lastDigits.value.isNotEmpty) {
            invoice.customFactura?["numeroTarjeta"] = '${state.firstDigits.value}00000000${state.lastDigits.value}';
          }
          else {
            invoice.customFactura?["numeroTarjeta"] =  "1234000000001234";
          }
        }


        if ((paymentMethod?.id== AppConstants.idPaymentMethodCard || paymentMethod?.id== AppConstants.idPaymentMethodQR || paymentMethod?.id== AppConstants.idPaymentMethodTransfer)&&paymentMethod?.id!= AppConstants.idPaymentMethodOthers ) {
          invoice.pagoEnTarjeta = (state.order?.monto??0) - state.discountAmount;
        }

        if(paymentMethod?.id== AppConstants.idPaymentMethodGiftCard){
          invoice.giftCards=(state.order?.monto??0) - state.discountAmount;
        }
        else if(paymentMethod?.id!= AppConstants.idPaymentMethodOthers){
          invoice.giftCards=null;
        }
        if(noData){
          invoice.razonSocial="S/N";
          invoice.comprador = "0";
        }

        if(state.payments.fold(0, (previousValue, element) => previousValue + (element.id!=null?1:0)) >=2){
          invoice.pagoEnTarjeta = 0;
          invoice.pagoEnEfectivo = 0;
          invoice.giftCards = 0;

          var idPaymentMethodSplit=state.payments.firstWhere((element) => element.id!=null,orElse: ()=>Payment()).metodoPago;


          for(var p in state.payments){
            if(p.id!=null){
              if(idPaymentMethodSplit != p.metodoPago){
                idPaymentMethodSplit = AppConstants.idPaymentMethodOthers;
              }
              invoice.pagoEnTarjeta = (invoice.pagoEnTarjeta??0)+(p.metodoPago==AppConstants.idPaymentMethodCard?(p.monto??0):0);
              invoice.pagoEnEfectivo = (invoice.pagoEnEfectivo??0)+(p.metodoPago==AppConstants.idPaymentMethodCash?(p.monto??0):0);
              invoice.giftCards = (invoice.giftCards??0)+(p.metodoPago==AppConstants.idPaymentMethodGiftCard?(p.monto??0):0);
            }
          }

          paymentMethod = state.paymentMethods.firstWhere(
                  (element) => element.id == (idPaymentMethodSplit ?? AppConstants.idPaymentMethodOthers),
              orElse: () => state.paymentMethods.first);

          invoice.metodoPago = paymentMethod.id;
          invoice.terminosPago = paymentMethod.nombre;
          if(state.usaSiat){
            invoice.codigoMetodoPago = paymentMethod.codigoSiat;
            if(invoice.giftCards != 0){
              invoice.codigoMetodoPago = paymentMethod.custom?["siat"]?["codigoGiftCard"] ?? AppConstants.idPaymentMethodGiftCard;
            }
          }
        }

        if(state.isManual){
          invoice.numero = state.invoiceNumber.value;
          invoice.autorizacion = state.authorization.value;
          await _comandaRepository.emitContingencia(invoice: invoice, orderId: state.order?.id ?? 0);
        }
        else{
          await _comandaRepository.emit(invoice: invoice, orderId: state.order?.id ?? 0);
        }
        emit(state.copyWith(status: prefactura?PaymentStatus.successPreInvoice:PaymentStatus.successInvoice));
      }
      else{
        return false;
      }
    }
    catch(error){
      emit(state.copyWith(
          status: PaymentStatus.errorGet, errorDescription: error.toString()));
      emit(state.copyWith(status: PaymentStatus.waitingGet));
    }

  }

  queryBusiness({required String query,required AuthState authState})async{
    emit(state.copyWith(documentNumber: state.documentNumber.changeLoading(true)));
    List<Contribuyente> businessList=await _businessRepository.queryBusinessSearch(query: query, contribuyenteId: authState.currentContribuyente?.id??0);
    emit(state.copyWith(documentNumber: state.documentNumber.changeLoading(false),queryBusinessList: businessList));
  }


  Future<bool> removePaymentRemote(int index)async{
    try{

      Payment? payment = state.payments.elementAtOrNull(index);
      if(payment!=null){
        List<Payment> paymentsFirst=List.of(state.payments);
        paymentsFirst[index]=payment.copyWith(loading: true);
        emit(state.copyWith(payments: paymentsFirst));
        await _comandaRepository.removePayment(paymentId: payment.id??0);


        List<Payment> payments=List.of(state.payments);
        payments.removeAt(index);
        while(payments.length<2){
          payments.add(Payment());
        }

        emit(state.copyWith(payments: payments));
      }
      return true;
    }
    catch(error){
      emit(state.copyWith(
          status: PaymentStatus.errorGet, errorDescription: error.toString()));
      emit(state.copyWith(status: PaymentStatus.waitingGet));
      return false;
    }
  }



}
