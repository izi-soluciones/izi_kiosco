import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/invoice_dto.dart';
import 'package:izi_kiosco/domain/dto/new_order_dto.dart';
import 'package:izi_kiosco/domain/dto/qr_dto.dart';
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
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
part 'payment_state.dart';
part 'payment_inputs.dart';

class PaymentBloc extends Cubit<PaymentState> {
  final ComandaRepository _comandaRepository;
  StreamSubscription? qrStream;
  final BusinessRepository _businessRepository;
  final SocketRepository _socketRepository;
  PaymentBloc(this._comandaRepository, this._businessRepository,this._socketRepository)
      : super(PaymentState.init());




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
        int indexCashRegister = cashRegisters.indexWhere((element) => element.id == authState.currentDevice?.caja);
        CashRegister? currentCashRegister;
        if (indexCashRegister != -1) {
          currentCashRegister =
              cashRegisters.elementAtOrNull(indexCashRegister);
        } else {

          emit(state.copyWith(status: PaymentStatus.errorCashRegisters));
          emit(state.copyWith(status: PaymentStatus.waitingGet));
          return;
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

        List<PaymentMethod> paymentMethods=await _businessRepository.getPaymentMethods();
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

        if (authState.currentContribuyente?.config?["aERestaurante"] ==
            null) {
          return emit(state.copyWith(status: PaymentStatus.errorActivity));
        }

        emit(state.copyWith(
            status: PaymentStatus.successGet,

              casaMatriz:(casaMatrizIndex != -1)?(authState.currentContribuyente?.sucursales?[casaMatrizIndex]):null,
            order: defaultOrder,
            step: 4,
            economicActivity: economicActivity,
            paymentMethods: paymentMethods,
            currentCurrency: currentCurrency,
            usaSiat: usaSiat,
            documentTypes: documentTypes,
            documentType: documentType,
            discountAmount: defaultOrder.descuentos,
            cashRegisters: cashRegisters,
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

    if (documentNumber) {
      emit(
          state.copyWith(documentNumber: state.documentNumber.validateError(valueRequired: state.businessName.value)));
    }
    if (businessName) {
      emit(state.copyWith(businessName: state.businessName.validateError(valueRequired: state.documentNumber.value)));
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


  selectPayment(PaymentType paymentType,AuthState authState) async {
    try{
      if(paymentType==PaymentType.cashRegister){
        emit(state.copyWith(status: PaymentStatus.cashRegisterProcessing));
        Comanda comanda = await _comandaRepository.markAsCreated(state.order?.id??0);
        if(comanda.numero is int){
          _printRolloOrder(authState, orderNumber: (comanda.numero as int), customOrderNumber: comanda.custom is Map && comanda.custom["numeroCustom"] is int?comanda.custom["numeroCustom"]:null);
        }
        emit(state.copyWith(step:2,status: PaymentStatus.cardSuccess,paymentType: paymentType));
        timerSuccess=Timer(const Duration(seconds: 10),() async{
          emit(state.copyWith(status: PaymentStatus.successInvoice));
        },);
        return;
      }
      emit(state.copyWith(paymentType: paymentType,step: 1));
    }
    catch(e){
      log(e.toString());
      emit(state.copyWith(status: PaymentStatus.markCreateError));
      emit(state.copyWith(status: PaymentStatus.successGet));
    }
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
        documentNumber: state.documentNumber.validateError(valueRequired: state.businessName.value),
        businessName: state.businessName.validateError(valueRequired: state.documentNumber.value),
      phoneNumber: state.phoneNumber.validateError()

    ));

    if(state.documentNumber.inputError !=null){
      return false;
    }
    if(state.businessName.inputError !=null){
      return false;
    }
    if(state.phoneNumber.inputError !=null){
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

  Future<void> makeCardPayment(AuthState authState)async{
    if(_validateInputs()){
      try{
        emit(state.copyWith(status: PaymentStatus.cardProcessing));
        CardPayment cardPayment =await _comandaRepository.callCardPayment(amount: 1);
        emit(state.copyWith(status: PaymentStatus.paymentProcessing));
        var success = false;
        for(int i=0;i<5;i++){
          if(await emitInvoice(authState: authState,cardDigits: cardPayment.cardNumber)){
          //if(await emitInvoice(authState: authState,cardDigits: "1234000000001234")){
            success = true;
            break;
          }
        }
        if(!success){
          await LocalStorageCardErrors.saveCardErrors(jsonEncode(cardPayment.toJson()));
          emit(state.copyWith(step:3,status: PaymentStatus.cardSuccess));
          timerSuccess=Timer(const Duration(seconds: 30),() async{
            emit(state.copyWith(status: PaymentStatus.successInvoice));
          },);
        }
        else{
          emit(state.copyWith(step:2,status: PaymentStatus.cardSuccess));
          timerSuccess=Timer(const Duration(seconds: 10),() async{
            emit(state.copyWith(status: PaymentStatus.successInvoice));
          },);
        }

      }
      catch(e){
        log(e.toString());
        emit(state.copyWith(status: PaymentStatus.cardError));
        emit(state.copyWith(status: PaymentStatus.successGet));
      }
    }

  }


  Timer? timerSuccess;
  Future<bool> generateQR(AuthState authState) async {
    try{
      if(_validateInputs()){

        emit(state.copyWith(qrLoading: true));
        QrDto qr = QrDto(
            orderId: state.order?.id??0,
            date: DateTime.now(),
            monto: state.order?.monto??0,
            moneda: state.currentCurrency?.simbolo == "Bs"?"BOB":state.currentCurrency?.simbolo ?? "BOB",
            monedaId: state.currentCurrency?.id ?? AppConstants.defaultCurrencyId
        );

        Charge charge = await _comandaRepository.generateQr(contribuyenteId: authState.currentContribuyente?.id??0, qr: qr);
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

        var documentType=state.documentType;
        if(state.documentNumber.value.isEmpty && state.usaSiat){
          documentType=state.documentTypes.first;
        }
        custom["pagadorData"]={
          "tipoDocumento": documentType,
          "nit":state.documentNumber.value.isEmpty? "0":state.documentNumber.value,
          "complemento":state.complement.value,
          "razonSocial":state.businessName.value.isEmpty?"S/N":state.businessName.value,
          "telefonoComprador":state.phoneNumber.value
        };

        newOrderDto.custom=custom;
        await _comandaRepository.editOrder(newOrder: newOrderDto);
        if(isClosed){
          return false;
        }
        if(qrStream !=null){
          _socketRepository.closeQrListening();
          qrStream?.cancel();
        }
        Timer? timer;
        qrStream = _socketRepository.listenQr(charge: charge).listen((event) async{
          if(event is Map && event["statusVenta"]=="success"){
            try{
              if(event["numeroOrden"] is int){
                await _printRolloOrder(authState, orderNumber: event["numeroOrden"],customOrderNumber: event["numeroCustom"] is int?event["numeroCustom"]:null);
              }
              if(event["idFactura"] is int){
                await _printRollo(authState, idInvoice: event["idFactura"]);
              }
            }
            catch(_){}
            if(timer!=null){
              timer!.cancel();
            }
            if(qrStream !=null){
              _socketRepository.closeQrListening();
              qrStream?.cancel();
            }
            emit(state.copyWith(step:2,status: PaymentStatus.qrProcessed));
            timerSuccess=Timer(const Duration(seconds: 10),() async{
              emit(state.copyWith(status: PaymentStatus.successInvoice));
            },);
          }
          else{
            timer=Timer(const Duration(seconds: 60),() async{
              emit(state.copyWith(step:2,status: PaymentStatus.qrProcessed));
              timerSuccess=Timer(const Duration(seconds: 10),() async{
                emit(state.copyWith(status: PaymentStatus.successInvoice));
              },);
            },);
            emit(state.copyWith(status: PaymentStatus.paymentProcessing));
          }
          /*
          _socketRepository.closeQrListening();
          qrStream?.cancel();
          qrStream = null;
          emit(state.copyWith(status: PaymentStatus.qrProcessing));
          bool generateOrderResult = false;
          for(int i=0;i<5;i++){
            generateOrderResult=await generateOrder(authState: authState);
            if(generateOrderResult){
              break;
            }
          }
          bool emitOrderResult = false;
          for(int i=0;i<5;i++){
            emitOrderResult=await emitInvoice(authState: authState);
            if(emitOrderResult){
              break;
            }
          }

          if(!emitOrderResult || !generateOrderResult){
            emit(state.copyWith(status: PaymentStatus.errorInvoice,step: 3));
            return;
          }
            emit(state.copyWith(step:2,status: PaymentStatus.qrProcessed));
          await Future.delayed(const Duration(seconds: 5));
          emit(state.copyWith(status: PaymentStatus.successInvoice));*/
        },);
        emit(state.copyWith(qrCharge: ()=>charge,qrLoading: false));
        return true;
      }
      return false;
    }
    catch(e){
      log(e.toString());
      emit(state.copyWith(qrLoading: false,qrCharge: ()=>null));
      return false;
    }
  }



  Future<bool> generateOrder({required AuthState authState})async{
    try{

      if(_validateInputs()){
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
          "tipoDocumento": state.documentType,
          "nit":state.documentNumber.value.isEmpty? "0":state.documentNumber.value,
          "complemento":state.complement.value,
          "razonSocial":state.businessName.value.isEmpty?"S/N":state.businessName.value,
          "telefonoComprador":state.phoneNumber.value
        };

        newOrderDto.custom=custom;
        await _comandaRepository.editOrder(newOrder: newOrderDto);
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

  Future<bool> emitInvoice({bool prefactura = false, required AuthState authState,String? cardDigits}) async {
    try{


      emit(state.copyWith(status: prefactura?PaymentStatus.waitingPreInvoice:PaymentStatus.waitingInvoice));

        PaymentMethod? paymentMethod;

        if (state.paymentMethods.isNotEmpty) {
              paymentMethod = state.paymentMethods.firstWhere(
                      (element) => element.id == AppConstants.idPaymentMethodCard,
                  orElse: () => state.paymentMethods.first);
        }



        InvoiceDto invoice = InvoiceDto(
            actividadEconomica: state.economicActivity,
            caja: state.currentCashRegister?.id ?? 0,
            comprador: state.documentNumber.value.isEmpty?"0":state.documentNumber.value,
            moneda: state.currentCurrency,
            descuentos: state.discountAmount,
            customFactura: {},
            fecha: DateTime.now(),
            metodoPago: paymentMethod?.id ?? 1,
            prefactura: prefactura,
            razonSocial: state.businessName.value.isEmpty?"S/N":state.businessName.value,
            sucursalDireccion: authState.currentSucursal?.direccion ?? "",
            terminosPago: paymentMethod?.nombre ?? "",);

        if (state.usaSiat) {
          invoice.codigoMetodoPago = paymentMethod?.codigoSiat;
          invoice.customFactura?["siat"]={"actividadEconomica":state.economicActivity};
        }
        if (state.usaSiat
            && (paymentMethod?.id== AppConstants.idPaymentMethodCard|| paymentMethod?.id==AppConstants.idPaymentMethodOthers)) {
          if (cardDigits!=null && cardDigits.length>=8) {
            invoice.customFactura?["numeroTarjeta"] = '${cardDigits.substring(0,4)}00000000${cardDigits.substring(cardDigits.length-4,cardDigits.length)}';
          }
          else {
            invoice.customFactura?["numeroTarjeta"] =  "1234000000001234";
          }
        }

        invoice.customFactura?["telefonoComprador"]=state.phoneNumber.value;
        invoice.customFactura?["codigoExcepcion"] = 1;


        if(state.documentType!=null){
          invoice.documentType =state.documentType;
        }
        if(state.documentNumber.value.isEmpty && state.usaSiat){
          invoice.documentType =state.documentTypes.first;
        }
        if(state.withException){
          invoice.customFactura?["codigoExcepcion"]=1;
        }

        Invoice invoiceRes = await _comandaRepository.invoicePreOrder(invoice: invoice, orderId: state.order?.id ?? 0);

        if(invoiceRes.numeroOrden!=null){
          await _printRolloOrder(authState, orderNumber: invoiceRes.numeroOrden!,customOrderNumber: invoiceRes.numeroCustom);
        }
        if(invoiceRes.id !=null){
          await _printRollo(authState, invoice: invoiceRes);
        }

        return true;
    }
    catch(error){
      log(error.toString());
      return false;
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

  _printRolloOrder(AuthState authState,{required int orderNumber,int? customOrderNumber})async{
    var tmp = await PrintTemplate.order80(orderNumber,customOrderNumber,authState.currentContribuyente!, authState.currentSucursal!);
    var printUtils = PrintUtils();
    await printUtils.print(tmp);
  }
  _printRollo(AuthState authState,{int? idInvoice,Invoice? invoice})async{
    if(idInvoice==null && invoice==null){
      return;
    }
    if(idInvoice!=null){
      invoice = await _comandaRepository.getInvoice(idInvoice);
    }
    var tmp = await PrintTemplate.invoice80(invoice!, authState.currentContribuyente!, authState.currentSucursal!);
    var printUtils = PrintUtils();
    await printUtils.print(tmp);
  }



}
