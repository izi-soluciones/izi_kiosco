part of 'payment_bloc.dart';

enum PaymentStatus {
  waitingInvoice,
  waitingPreInvoice,
  waitingGet,
  waitingQR,
  successGet,
  errorGet,
  successInvoice,
  errorInvoice,
  successPreInvoice,
  successPayment,
  errorInvoiced,
  errorAnnulled,
  errorCashRegisters,
  paymentProcessing,
  paymentProcessed,
  cardProcessing,
  cashRegisterProcessing,
  cardError,
  qrError,
  brebError,
  brebLoading,
  cardProcessed,
  errorActivity,
  markCreateError,
  processingInvoice,
  processingOrder,
  setInputs
}


enum PaymentCountryTaxes {bolivia, colombia}
enum PaymentType { cash, card, qr, bankTransfer, gitCard, others, cashRegister, breb}

class ParamsCo extends Equatable {
  final String? identificationType;
  final String? personType;
  final String? ivaResponsability;
  final String? taxResponsability;
  final List<IdentificationType> listIdentificationType;
  final List<PersonType> listPersonType;
  final List<IvaResponsability> listIvaResponsability;
  final List<TaxResponsability> listTaxResponsability;

  const ParamsCo({
    this.identificationType,
    this.personType,
    this.ivaResponsability,
    this.taxResponsability,
    this.listIdentificationType = const [],
    this.listPersonType = const [],
    this.listIvaResponsability = const [],
    this.listTaxResponsability = const [],
  });

  ParamsCo copyWith({
    String? identificationType,
    String? personType,
    String? ivaResponsability,
    String? taxResponsability,
    List<IdentificationType>? listIdentificationType,
    List<PersonType>? listPersonType,
    List<IvaResponsability>? listIvaResponsability,
    List<TaxResponsability>? listTaxResponsability,
  }) {
    return ParamsCo(
      identificationType: identificationType ?? this.identificationType,
      personType: personType ?? this.personType,
      ivaResponsability: ivaResponsability ?? this.ivaResponsability,
      taxResponsability: taxResponsability ?? this.taxResponsability,
      listIdentificationType: listIdentificationType ?? this.listIdentificationType,
      listPersonType: listPersonType ?? this.listPersonType,
      listIvaResponsability: listIvaResponsability ?? this.listIvaResponsability,
      listTaxResponsability: listTaxResponsability ?? this.listTaxResponsability,
    );
  }

  @override
  List<Object?> get props => [
        identificationType,
        personType,
        ivaResponsability,
        taxResponsability
      ];
}
class ParamsBo extends Equatable {
  final DocumentType? documentType;
  final List<DocumentType> documentTypes;

  const ParamsBo({
    this.documentType,
    this.documentTypes = const [],
  });

  ParamsBo copyWith({
    DocumentType? documentType,
    List<DocumentType>? documentTypes,
  }) {
    return ParamsBo(
      documentType: documentType ?? this.documentType,
      documentTypes: documentTypes ?? this.documentTypes,
    );
  }

  @override
  List<Object?> get props => [documentType];
}

class PaymentState extends Equatable {
  final String? errorDescription;
  final PaymentStatus status;
  final String economicActivity;

  final Sucursal? casaMatriz;

  //INPUTS
  final CashRegister? currentCashRegister;
  final bool withException;
  final bool isManual;
  final InputObj documentNumber;
  final InputObj complement;
  final InputObj businessName;
  final InputObj phoneNumber;
  final InputObj email;


  //VARIABLES
  final num? qrAmount;
  final Charge? qrCharge;
  final bool qrWait;
  final Charge? brebCharge;
  final bool brebLoading;
  final int? qrPaymentKey;

  final bool qrLoading;
  final num tipAmount;
  final num cashAmount;
  final int step;

  final PaymentType paymentType;

  final Currency? currentCurrency;

  final List<Customer> queryBusinessList;

  final PaymentObj? paymentObj;

  final bool usaSiat;


  final ParamsBo? paramsBo;
  final ParamsCo? paramsCo;
  final PaymentCountryTaxes? countryTaxes;

  const PaymentState(
      {
      this.errorDescription,
        required this.paymentObj,
      required this.cashAmount,
      required this.economicActivity,
      required this.currentCurrency,
      required this.paymentType,
      required this.step,
      required this.status,
      required this.casaMatriz,
      this.currentCashRegister,
      this.paramsBo,
      this.paramsCo,
      required this.isManual,
      required this.usaSiat,
      required this.queryBusinessList,
      required this.tipAmount,
      required this.businessName,
      required this.email,
      required this.complement,
      required this.documentNumber,
      required this.withException,
      required this.phoneNumber,
        required this.qrLoading,
        this.qrAmount,
        this.qrCharge,
        this.qrWait = false,
        this.brebCharge,
        this.brebLoading = false,
        this.countryTaxes,
        this.qrPaymentKey});

  factory PaymentState.init() => PaymentState(
      status: PaymentStatus.waitingGet,
      paymentObj: null,
      cashAmount: 0,
      tipAmount: 0,
      economicActivity: "",
      usaSiat: false,
      queryBusinessList: const [],
      paymentType: PaymentType.others,
      step: 5,
      isManual: false,
      currentCurrency: null,
      email: PaymentInputs.emailInput(),
      businessName: PaymentInputs.businessNameInput(),
      complement: PaymentInputs.complementInput(),
      documentNumber: PaymentInputs.documentNumberInput(),
      withException: false,
      phoneNumber: PaymentInputs.phoneNumberInput(),
      qrLoading: false,
      brebCharge: null,
      brebLoading: false,
      casaMatriz: null);

  copyWith(
      {
      PaymentStatus? status,
      String? errorDescription,
      int? step,
      num? cashAmount,
      List<CashRegister>? cashRegisters,
      CashRegister? currentCashRegister,
      Currency? currentCurrency,
      PaymentType? paymentType,
      List<Payment>? payments,
      List<PaymentMethod>? paymentMethods,
      bool? usaSiat,
      num? tipAmount,
      List<Customer>? queryBusinessList,
      bool? isManual,
      bool? withException,
      InputObj? documentNumber,
      InputObj? complement,
      InputObj? businessName,
      InputObj? email,
      String? economicActivity,
        InputObj? phoneNumber,
        Charge? Function()? qrCharge,
        num? qrAmount,
        int? qrPaymentKey,
        bool? qrWait,
        bool? qrLoading,
        Charge? brebCharge,
        bool? brebLoading,
      Sucursal? casaMatriz,
        ParamsBo? paramsBo,
        ParamsCo? paramsCo,
        PaymentCountryTaxes? countryTaxes,
      PaymentObj? paymentObj}) {
    return PaymentState(
        casaMatriz: casaMatriz ?? this.casaMatriz,
        status: status ?? this.status,
        errorDescription: errorDescription ?? this.errorDescription,
        step: step ?? this.step,
        paymentType: paymentType ?? this.paymentType,
        usaSiat: usaSiat ?? this.usaSiat,
        queryBusinessList: queryBusinessList ?? this.queryBusinessList,
        economicActivity: economicActivity ?? this.economicActivity,
        cashAmount: cashAmount ?? this.cashAmount,
        currentCurrency: currentCurrency ?? this.currentCurrency,
        currentCashRegister: currentCashRegister ?? this.currentCashRegister,
        tipAmount: tipAmount ?? this.tipAmount,
        withException: withException ?? this.withException,
        businessName: businessName ?? this.businessName,
        email: email ?? this.email,
        complement: complement ?? this.complement,
        documentNumber: documentNumber ?? this.documentNumber,

        paramsBo: paramsBo ?? this.paramsBo,
        paramsCo: paramsCo ?? this.paramsCo,
        isManual: isManual ?? this.isManual,
      qrAmount: qrAmount ?? this.qrAmount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      qrCharge: qrCharge !=null?qrCharge() : this.qrCharge,
      qrPaymentKey: qrPaymentKey == -1?null: qrPaymentKey ?? this.qrPaymentKey,
      qrLoading: qrLoading ?? this.qrLoading,
      qrWait: qrWait ?? this.qrWait,
      brebCharge: brebCharge ?? this.brebCharge,
      brebLoading: brebLoading ?? this.brebLoading,
      paymentObj: paymentObj ?? this.paymentObj,
      countryTaxes: countryTaxes ?? this.countryTaxes
    );
  }

  @override
  List<Object?> get props => [
        status,
        step,
        paymentObj,
        tipAmount,
        currentCurrency,
        cashAmount,
        paymentType,
        currentCashRegister,
        withException,
        businessName,
        email,
        complement,
        documentNumber,
        paramsBo,
        paramsCo,
        isManual,
    qrWait,
        queryBusinessList,
    phoneNumber,
    qrCharge,
    qrAmount,
    qrPaymentKey,
    qrLoading
      ];
}
