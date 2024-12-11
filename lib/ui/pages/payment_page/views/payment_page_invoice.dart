
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/general/kiosco_numeric_keyboard.dart';
import 'package:izi_kiosco/ui/pages/payment_page/modals/card_type_atc_modal.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/dynamic_list.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';


class PaymentPageInvoice extends StatefulWidget {
  final PaymentState state;
  const PaymentPageInvoice({super.key, required this.state});

  @override
  State<PaymentPageInvoice> createState() => _PaymentPageInvoiceState();
}

class _PaymentPageInvoiceState extends State<PaymentPageInvoice> {
  TextEditingController businessNameController = TextEditingController();
  TextEditingController documentNumberController = TextEditingController();
  TextEditingController complementController = TextEditingController();
  bool documentNumberFocus = false;
  GlobalKey documentNumberKey = GlobalKey();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool phoneFocus = false;
  GlobalKey phoneKey = GlobalKey();

  FocusNode focusPhone = FocusNode();

  int qrLock = 0;
  int qrRemaining = 0;


  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IziHeaderKiosk(onBack: () {
                context.read<PaymentBloc>().changeStep(1);
              }),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      IziText.titleBig(
                          color: IziColors.dark,
                          fontWeight: FontWeight.w600,
                          text: LocaleKeys.payment_titles_invoiceData.tr()),
                      const SizedBox(
                        height: 16,
                      ),
                      IziText.titleSmall(
                          color: IziColors.dark,
                          maxLines: 4,
                          text:
                              "${LocaleKeys.payment_subtitles_beforePaymentNeedData.tr()}:",
                          fontWeight: FontWeight.w500),
                      const SizedBox(
                        height: 32,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 600,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _invoiceForm(context, ru),
                        ],
                      )),
                ),
              ),
              _buttons(context, ru)
            ],
          ),
        ),
        if (phoneFocus || documentNumberFocus)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (phoneFocus) {
                  context.read<PaymentBloc>().validateInput(phoneNumber: true);
                } else {
                  context
                      .read<PaymentBloc>()
                      .queryBusiness(authState: context.read<AuthBloc>().state)
                      .then((value) {
                    context.read<PaymentBloc>().validateInput(
                        documentNumber: true, businessName: true);
                  });
                }
                setState(() {
                  phoneFocus = false;
                  documentNumberFocus = false;
                });
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        if (phoneFocus || documentNumberFocus)
          Positioned(
            top: documentNumberFocus
                ? _getWidgetOffset(documentNumberKey).dy
                : _getWidgetOffset(phoneKey).dy,
            left: documentNumberFocus
                ? _getWidgetOffset(documentNumberKey).dx
                : _getWidgetOffset(phoneKey).dx,
            child: KioscoNumericKeyboard(
                controller: documentNumberFocus
                    ? documentNumberController
                    : phoneController,
                onChanged: () {
                  if (documentNumberFocus) {
                    context.read<PaymentBloc>().changeInputs(
                        documentNumber: documentNumberController.text);
                  } else {
                    context
                        .read<PaymentBloc>()
                        .changeInputs(phoneNumber: phoneController.text);
                  }
                },
                onDone: () {
                  if (phoneFocus) {
                    context
                        .read<PaymentBloc>()
                        .validateInput(phoneNumber: true);
                  } else {
                    context
                        .read<PaymentBloc>()
                        .queryBusiness(
                            authState: context.read<AuthBloc>().state)
                        .then((value) {
                      context.read<PaymentBloc>().validateInput(
                          documentNumber: true, businessName: true);
                    });
                  }
                  setState(() {
                    phoneFocus = false;
                    documentNumberFocus = false;
                  });
                }),
          )
      ],
    );
  }

  Offset _getWidgetOffset(GlobalKey key) {
    RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    var offsetDefault = renderBox.localToGlobal(Offset.zero);
    return Offset(
        offsetDefault.dx, offsetDefault.dy + renderBox.size.height + 4);
  }

  Widget _buttons(BuildContext context, ResponsiveUtils ru) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DynamicList(
          direction: ru.gtSm()
              ? DynamicListDirection.row
              : DynamicListDirection.column,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ru.gtSm())
              Flexible(
                child: IziBtn(
                    buttonText: LocaleKeys.payment_buttons_initAgain.tr(),
                    buttonType: ButtonType.outline,
                    buttonSize: ButtonSize.large,
                    buttonOnPressed: () {_initAgain();}),
              ),
            if (ru.gtSm()) const SizedBox(width: 16),
            Flexible(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  InkWell(
                    onTap: () {
                      _makePayment();
                    },
                    splashColor: IziColors.secondaryDarken,
                    focusColor: IziColors.secondaryDarken,
                    highlightColor: IziColors.secondaryDarken,
                    hoverColor: IziColors.secondaryDarken,
                    borderRadius: BorderRadius.circular(6),
                    child: Ink(
                      decoration: BoxDecoration(
                          color: IziColors.primary,
                          borderRadius: BorderRadius.circular(6)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "${LocaleKeys.payment_body_total.tr()}: ${widget.state.paymentObj?.amount.moneyFormat(currency: widget.state.currentCurrency?.simbolo)}",
                              maxLines: 5,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  height: 1.2,
                                  color: IziColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20),
                            ),
                            Text(
                              LocaleKeys.payment_buttons_proceedPayment.tr(),
                              maxLines: 5,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: IziColors.white, fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                      right: 8,
                      child: Icon(
                        IziIcons.rightB,
                        size: 32,
                        color: IziColors.white,
                      ))
                ],
              ),
            ),
            if (!ru.gtSm()) const SizedBox(height: 16),
            if (!ru.gtSm())
              Flexible(
                child: IziBtn(
                    buttonText: LocaleKeys.payment_buttons_initAgain.tr(),
                    buttonType: ButtonType.outline,
                    buttonSize: ButtonSize.medium,
                    buttonOnPressed: () {_initAgain();}),
              ),
          ]),
    );
  }

  Widget _invoiceForm(BuildContext context, ResponsiveUtils ru) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state.businessName.value != businessNameController.text) {
          businessNameController.text = state.businessName.value;
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IziText.body(
              color: IziColors.darkGrey,
              text: LocaleKeys.payment_inputs_documentNumber_label.tr(),
              fontWeight: FontWeight.w400),
          const SizedBox(
            height: 4,
          ),
          if (widget.state.usaSiat && ru.isXs())
            IziInput(
              inputHintText: "",
              bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
              value: widget.state.documentType?.codigoClasificador,
              inputType: InputType.select,
              inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                  ? InputSize.big
                  : InputSize.normal,
              readOnly: widget.state.qrCharge != null ||
                  widget.state.qrLoading == true,
              onSelected: (value) {
                context.read<PaymentBloc>().changeInputs(documentType: value);
              },
              selectOptions: {
                for (DocumentType type in widget.state.documentTypes)
                  type.codigoClasificador:
                      type.descripcion.split("-").firstOrNull ?? ""
              },
            ),
          if (widget.state.usaSiat && ru.isXs())
            const SizedBox(
              height: 16,
            ),
          RowContainer(
            gap: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.state.usaSiat && ru.gtXs())
                Expanded(
                  flex: 1,
                  child: IziInput(
                    inputHintText: "",
                    bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
                    value: widget.state.documentType?.codigoClasificador,
                    inputType: InputType.select,
                    inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                        ? InputSize.big
                        : InputSize.normal,
                    readOnly: widget.state.qrCharge != null ||
                        widget.state.qrLoading == true,
                    onSelected: (value) {
                      context
                          .read<PaymentBloc>()
                          .changeInputs(documentType: value);
                    },
                    selectOptions: {
                      for (DocumentType type in widget.state.documentTypes)
                        type.codigoClasificador:
                            type.descripcion.split("-").firstOrNull ?? ""
                    },
                  ),
                ),
              Expanded(
                flex: 2,
                child: IziInput(
                  key: documentNumberKey,
                  bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
                  inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                      ? InputSize.big
                      : InputSize.normal,
                  inputMaxLength: 50,
                  readOnly: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
                  suffixWidget: widget.state.documentNumber.loading
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          height: 20,
                          width: 20,
                          child: const CircularProgressIndicator(
                            color: IziColors.darkGrey,
                            strokeWidth: 2,
                          ))
                      : null,
                  onChanged: (value, valueRaw) {
                    if (!(ru.gtMd() || (ru.gtSm() && ru.isVertical()))) {
                      context.read<PaymentBloc>().changeInputs(
                          documentNumber: documentNumberController.text);
                    }
                  },
                  onEditingComplete: () {
                    if (!(ru.gtMd() || (ru.gtSm() && ru.isVertical()))) {
                      context
                          .read<PaymentBloc>()
                          .queryBusiness(
                              authState: context.read<AuthBloc>().state)
                          .then((value) {
                        context.read<PaymentBloc>().validateInput(
                            documentNumber: true, businessName: true);
                      });
                    }
                  },
                  onClick: widget.state.qrCharge == null &&
                          widget.state.qrLoading == false &&
                          (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                      ? () {
                          setState(() {
                            documentNumberFocus = true;
                            phoneFocus = false;
                          });
                        }
                      : null,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[1-9]'))
                  ],
                  controller: documentNumberController,
                  loadingAutoComplete: widget.state.documentNumber.loading,
                  error: _getErrorsDocumentNumber(
                      widget.state.documentNumber.inputError),
                  inputHintText: LocaleKeys
                      .payment_inputs_documentNumber_placeholder
                      .tr(args: [
                    (widget.state.documentType?.descripcion ?? "número")
                        .split("-")
                        .firstOrNull
                        .toString()
                  ]),
                  inputType: InputType.number,
                ),
              ),
              if (widget.state.usaSiat &&
                  widget.state.documentType?.codigoClasificador ==
                      AppConstants.codeCI)
                Expanded(
                  flex: 1,
                  child: IziInput(
                    inputHintText: "",
                    inputMaxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                    ],
                    readOnly: widget.state.qrCharge != null ||
                        widget.state.qrLoading == true,
                    onChanged: (value, valueRaw) {
                      context
                          .read<PaymentBloc>()
                          .changeInputs(complement: value);
                    },
                    bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
                    inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                        ? InputSize.big
                        : InputSize.normal,
                    inputType: InputType.normal,
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          IziInput(
            labelInput: LocaleKeys.payment_inputs_businessName_label.tr(),
            inputHintText:
                LocaleKeys.payment_inputs_businessName_placeholder.tr(),
            inputMaxLength: 150,
            readOnly:
                widget.state.qrCharge != null || widget.state.qrLoading == true,
            inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                ? InputSize.big
                : InputSize.normal,
            onChanged: (value, valueRaw) {
              context.read<PaymentBloc>().changeInputs(businessName: value);
            },
            onEditingComplete: () {
              context
                  .read<PaymentBloc>()
                  .validateInput(documentNumber: true, businessName: true);
            },
            controller: businessNameController,
            value: widget.state.businessName.value,
            error: _getErrorsBusinessName(widget.state.businessName.inputError),
            inputType: InputType.normal,
          ),
          const SizedBox(
            height: 16,
          ),
          IziInput(
            focusNode: focusPhone,
            labelInput: LocaleKeys.payment_inputs_phoneNumber_label.tr(),
            inputHintText:
                LocaleKeys.payment_inputs_phoneNumber_placeholder.tr(),
            bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
            key: phoneKey,
            inputMaxLength: 8,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9]'))
            ],
            controller: phoneController,
            readOnly: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
            inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                ? InputSize.big
                : InputSize.normal,
            onClick: widget.state.qrCharge == null &&
                    widget.state.qrLoading == false &&
                    (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                ? () {
                    setState(() {
                      documentNumberFocus = false;
                      phoneFocus = true;
                    });
                  }
                : null,
            onEditingComplete: () {
              context.read<PaymentBloc>().validateInput(phoneNumber: true);
            },
            onChanged: (value, valueRaw) {
              if(!(ru.gtMd() || (ru.gtSm() && ru.isVertical()))){
                context.read<PaymentBloc>().changeInputs(phoneNumber: value);
              }
            },
            error: _getErrorsPhoneNumber(widget.state.phoneNumber.inputError),
            inputType: InputType.number,
          ),
          const SizedBox(height: 8),
          IziText.label(
              color: IziColors.darkGrey,
              text: LocaleKeys.payment_inputs_phoneNumber_description.tr(),
              fontWeight: FontWeight.w500,
              maxLines: 3),
        ],
      ),
    );
  }

  _paymentCard() {
    if (context.read<AuthBloc>().state.currentDevice?.config.ipLinkser !=
        null) {
      _paymentCardLinkser(context);
    } else if (context.read<AuthBloc>().state.currentDevice?.config.ipAtc !=
        null) {
      _paymentCardATC(context);
    }
  }

  _paymentCardLinkser(BuildContext context) async {
    context.read<PageUtilsBloc>().closeScreenActive();
    var status = await context
        .read<PaymentBloc>()
        .makeCardPayment(context.read<AuthBloc>().state, linkser: true);
    if (!mounted) {
      return;
    }
    if (!status) {
      context.read<PageUtilsBloc>().initScreenActive();
    }
  }

  _paymentCardATC(BuildContext context) async {
    CustomAlerts.defaultAlert(
            context: context,
            dismissible: true,
            defaultScroll: false,
            child: CardTypeAtcModal(
                amount: (widget.state.paymentObj?.amount ?? 0)))
        .then((value) async {
      if (value is int) {
        context.read<PageUtilsBloc>().closeScreenActive();
        var status = await context.read<PaymentBloc>().makeCardPayment(
            context.read<AuthBloc>().state,
            atc: true,
            contactless: value == 1 ? false : true);
        if (!mounted) {
          return;
        }
        if (!status) {
          context.read<PageUtilsBloc>().initScreenActive();
        }
      }
    });
  }

  String? _getErrorsDocumentNumber(InputError? inputError) {
    switch (inputError) {
      case InputError.required:
        return LocaleKeys.payment_inputs_documentNumber_errors_required.tr();
      default:
        return null;
    }
  }

  String? _getErrorsBusinessName(InputError? inputError) {
    switch (inputError) {
      case InputError.required:
        return LocaleKeys.payment_inputs_businessName_errors_required.tr();
      default:
        return null;
    }
  }

  String? _getErrorsPhoneNumber(InputError? inputError) {
    switch (inputError) {
      case InputError.required:
        return LocaleKeys.payment_inputs_phoneNumber_errors_required.tr();
      case InputError.invalid:
        return LocaleKeys.payment_inputs_phoneNumber_errors_invalid.tr();
      default:
        return null;
    }
  }

  _initAgain(){
    phoneController.text = "";
    businessNameController.text = "";
    documentNumberController.text = "";
    complementController.text = "";
    context.read<PaymentBloc>().changeInputs(
      phoneNumber: "",
      documentNumber: "",
      businessName: "",
      complement: ""
    );
    setState(() {});
  }

  _makePayment(){
    switch(widget.state.paymentType){
      case PaymentType.qr:
        context.read<PaymentBloc>().generateQR(context.read<AuthBloc>().state);
        break;
      case PaymentType.card:
        _paymentCard();
        break;
      default:
        break;
    }
  }
}
