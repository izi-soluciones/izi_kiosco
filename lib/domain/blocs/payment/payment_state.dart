part of 'payment_bloc.dart';

enum PaymentStatus {
  waitingInvoice,
  waitingPreInvoice,
  waitingGet,
  successGet,
  errorGet,
  successInvoice,
  errorInvoice,
  successPreInvoice,
  successPayment,
  errorInvoiced,
  errorAnnulled,
  errorCashRegisters,
  qrProcessing,
  qrProcessed
}

enum PaymentType { cash, card, qr, bankTransfer, gitCard, others }

class PaymentState extends Equatable {
  final String? errorDescription;
  final PaymentStatus status;
  final String economicActivity;

  final Sucursal? casaMatriz;

  //INPUTS
  final CashRegister? currentCashRegister;
  final bool withException;
  final bool isManual;
  final DocumentType? documentType;
  final InputObj documentNumber;
  final InputObj complement;
  final InputObj businessName;
  final InputObj phoneNumber;


  //VARIABLES
  final num? qrAmount;
  final Charge? qrCharge;
  final int? qrPaymentKey;

  final bool qrLoading;
  final num discountAmount;
  final num tipAmount;
  final num cashAmount;
  final int step;

  final PaymentType paymentType;

  final Currency? currentCurrency;

  final List<CashRegister> cashRegisters;

  final List<PaymentMethod> paymentMethods;
  final List<Payment> payments;
  final List<DocumentType> documentTypes;
  final List<Contribuyente> queryBusinessList;

  final Comanda? order;

  final bool usaSiat;

  const PaymentState(
      {this.order,
      this.errorDescription,
      required this.cashAmount,
      required this.economicActivity,
      required this.currentCurrency,
      required this.paymentType,
      required this.step,
      required this.cashRegisters,
      required this.status,
      required this.casaMatriz,
      this.currentCashRegister,
      required this.isManual,
      required this.documentTypes,
      required this.usaSiat,
      required this.queryBusinessList,
      required this.payments,
      required this.paymentMethods,
      required this.discountAmount,
      required this.tipAmount,
      required this.businessName,
      required this.complement,
      required this.documentNumber,
      this.documentType,
      required this.withException,
      required this.phoneNumber,
        required this.qrLoading,
        this.qrAmount,
        this.qrCharge,
        this.qrPaymentKey});

  factory PaymentState.init() => PaymentState(
      status: PaymentStatus.waitingGet,
      discountAmount: 0,
      cashRegisters: const [],
      cashAmount: 0,
      tipAmount: 0,
      paymentMethods: const [],
      documentTypes: const [],
      economicActivity: "",
      usaSiat: false,
      queryBusinessList: const [],
      payments: [
        Payment(),
        Payment()
      ],
      paymentType: PaymentType.others,
      step: 5,
      isManual: false,
      currentCurrency: null,
      businessName: PaymentInputs.businessNameInput(),
      complement: PaymentInputs.complementInput(),
      documentNumber: PaymentInputs.documentNumberInput(),
      withException: false,
      phoneNumber: PaymentInputs.phoneNumberInput(),
      qrLoading: false,
      casaMatriz: null);

  copyWith(
      {Comanda? order,
      PaymentStatus? status,
      String? errorDescription,
      num? discountAmount,
      int? step,
      num? cashAmount,
      List<CashRegister>? cashRegisters,
      CashRegister? currentCashRegister,
      Currency? currentCurrency,
      PaymentType? paymentType,
      List<Payment>? payments,
      List<DocumentType>? documentTypes,
      List<PaymentMethod>? paymentMethods,
      bool? usaSiat,
      num? tipAmount,
      List<Contribuyente>? queryBusinessList,
      bool? isManual,
      bool? withException,
      DocumentType? documentType,
      InputObj? documentNumber,
      InputObj? complement,
      InputObj? businessName,
      InputObj? email,
      String? economicActivity,
        InputObj? phoneNumber,
        Charge? Function()? qrCharge,
        num? qrAmount,
        int? qrPaymentKey,
        bool? qrLoading,
      Sucursal? casaMatriz}) {
    return PaymentState(
        casaMatriz: casaMatriz ?? this.casaMatriz,
        status: status ?? this.status,
        errorDescription: errorDescription ?? this.errorDescription,
        step: step ?? this.step,
        documentTypes: documentTypes ?? this.documentTypes,
        paymentType: paymentType ?? this.paymentType,
        usaSiat: usaSiat ?? this.usaSiat,
        queryBusinessList: queryBusinessList ?? this.queryBusinessList,
        economicActivity: economicActivity ?? this.economicActivity,
        cashAmount: cashAmount ?? this.cashAmount,
        payments: payments ?? this.payments,
        paymentMethods: paymentMethods ?? this.paymentMethods,
        currentCurrency: currentCurrency ?? this.currentCurrency,
        order: order ?? this.order,
        cashRegisters: cashRegisters ?? this.cashRegisters,
        currentCashRegister: currentCashRegister ?? this.currentCashRegister,
        discountAmount: discountAmount ?? this.discountAmount,
        tipAmount: tipAmount ?? this.tipAmount,
        withException: withException ?? this.withException,
        businessName: businessName ?? this.businessName,
        complement: complement ?? this.complement,
        documentNumber: documentNumber ?? this.documentNumber,
        documentType: documentType ?? this.documentType,
        isManual: isManual ?? this.isManual,
      qrAmount: qrAmount ?? this.qrAmount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      qrCharge: qrCharge !=null?qrCharge() : this.qrCharge,
      qrPaymentKey: qrPaymentKey == -1?null: qrPaymentKey ?? this.qrPaymentKey,
      qrLoading: qrLoading ?? this.qrLoading
    );
  }

  @override
  List<Object?> get props => [
        status,
        step,
        order,
        discountAmount,
        tipAmount,
        currentCurrency,
        cashAmount,
        paymentType,
        currentCashRegister,
        documentTypes,
        withException,
        businessName,
        complement,
        documentNumber,
        documentType,
        isManual,
        queryBusinessList,
    phoneNumber,
    payments,
    qrCharge,
    qrAmount,
    qrPaymentKey,
    qrLoading
      ];
}
