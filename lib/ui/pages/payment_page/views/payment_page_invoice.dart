import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_link.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/molecules/izi_phone_code_selector.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/pages/payment_page/modals/card_type_atc_modal.dart';
import 'package:izi_kiosco/ui/pages/payment_page/modals/card_type_izify_modal.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/country_form/payment_page_invoice_form.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_choice_btn.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/dynamic_list.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';


class PaymentPageInvoice extends StatefulWidget {
  final PaymentState state;
  const PaymentPageInvoice({super.key, required this.state});

  @override
  State<PaymentPageInvoice> createState() => _PaymentPageInvoiceState();
}

class _PaymentPageInvoiceState extends State<PaymentPageInvoice> {
  late AuthState authState;
  TextEditingController customerNameController = TextEditingController();
  TextEditingController businessNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  bool showEmail=false;

  @override
  void initState() {
    super.initState();
    authState = context.read<AuthBloc>().state;
  }

  bool get _needsCustomerName => widget.state.paymentObj?.isComanda == true;

  bool get _canInvoice =>
      authState.currentContribuyente?.tieneFacturacion == true;

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IziHeaderKiosk(onPop: () {
          context.read<PaymentBloc>().changeStep(1);
        },hideLogo: true,),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: BlocListener<PaymentBloc, PaymentState>(
                  listener: (context, state) {
                    if (state.customerName.value != customerNameController.text) {
                      customerNameController.text = state.customerName.value;
                    }
                    if (state.businessName.value != businessNameController.text) {
                      businessNameController.text = state.businessName.value;
                    }
                    if (state.email.value != emailController.text) {
                      emailController.text = state.email.value;
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if(ru.isXs())
                        const SizedBox(height: 8,),
                      _canInvoice
                          ? _invoiceQuestion(context, ru)
                          : _title(context, ru,
                              LocaleKeys.payment_titles_orderName.tr()),
                      const SizedBox(height: 32,),
                      if(widget.state.wantsInvoice)
                        _sectionTitle(context,
                            LocaleKeys.payment_titles_customerData.tr()),
                      _customerForm(context, ru),
                      if(widget.state.wantsInvoice)
                        const SizedBox(height: 40,),
                      if(widget.state.wantsInvoice)
                        _sectionTitle(context,
                            LocaleKeys.payment_titles_invoiceData.tr()),
                      if(widget.state.wantsInvoice)
                        _invoiceForm(context, ru),
                      const SizedBox(height: 24,),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _buttons(context, ru)
      ],
    );
  }

  Widget _title(BuildContext context, ResponsiveUtils ru, String text) {
    return ru.isXs()
        ? IziText.titleMedium(
            color: context.iziColors.dark,
            fontWeight: FontWeight.w600,
            maxLines: 3,
            textAlign: TextAlign.center,
            text: text)
        : IziText.titleBig(
            color: context.iziColors.dark,
            fontWeight: FontWeight.w600,
            maxLines: 3,
            textAlign: TextAlign.center,
            text: text);
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IziText.titleSmall(
              color: context.iziColors.dark,
              text: text,
              maxLines: 2,
              fontWeight: FontWeight.w600),
          const SizedBox(height: 8,),
          Divider(height: 1, thickness: 1, color: context.iziColors.grey25),
        ],
      ),
    );
  }

  Widget _invoiceQuestion(BuildContext context, ResponsiveUtils ru) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(context, ru, LocaleKeys.payment_titles_needInvoice.tr()),
        const SizedBox(height: 16,),
        Row(
          children: [
            Expanded(
              child: PaymentChoiceBtn(
                  text: LocaleKeys.payment_buttons_invoiceNo.tr(),
                  selected: !widget.state.wantsInvoice,
                  big: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      showEmail = false;
                    });
                    context.read<PaymentBloc>().changeWantsInvoice(false);
                  }),
            ),
            const SizedBox(width: 16,),
            Expanded(
              child: PaymentChoiceBtn(
                  text: LocaleKeys.payment_buttons_invoiceYes.tr(),
                  selected: widget.state.wantsInvoice,
                  big: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    context.read<PaymentBloc>().changeWantsInvoice(true);
                  }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _customerForm(BuildContext context, ResponsiveUtils ru) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if(_needsCustomerName)
          IziInput(
            labelInput: LocaleKeys.payment_inputs_customerName_label.tr(),
            inputHintText:
                LocaleKeys.payment_inputs_customerName_placeholder.tr(),
            inputMaxLength: PaymentInputs.customerNameMaxLength,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) =>
                  newValue.copyWith(
                      text: PaymentInputs.normalizeCustomerName(newValue.text))),
              FilteringTextInputFormatter.allow(PaymentInputs.customerNameCharacters)
            ],
            bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
            textCapitalization: TextCapitalization.words,
            readOnly:
                widget.state.qrCharge != null || widget.state.qrLoading == true,
            inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                ? InputSize.big
                : InputSize.normal,
            onChanged: (value, valueRaw) {
              context.read<PaymentBloc>().changeInputs(customerName: value);
            },
            onEditingComplete: () {
              context.read<PaymentBloc>().validateInput(customerName: true);
            },
            controller: customerNameController,
            value: widget.state.customerName.value,
            error: _getErrorsCustomerName(widget.state.customerName.inputError),
            inputType: InputType.normal,
          ),
        if(_needsCustomerName)
          const SizedBox(height: 8,),
        if(_needsCustomerName)
          IziText.label(
              color: context.iziColors.darkGrey,
              text: LocaleKeys.payment_inputs_customerName_description.tr(),
              fontWeight: FontWeight.w500,
              maxLines: 3),
        if(_needsCustomerName)
          const SizedBox(height: 16,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))?26.0:22),
              child: IziPhoneCodeSelector(
                  inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                      ? InputSize.big
                      : InputSize.normal,
                  favoriteCountries: AppConstants.favoriteCountriesPhone,
                  countries: AppConstants.countriesPhone,
                  phonePrefix: widget.state.phonePrefix, onChanged: (value){
                    context.read<PaymentBloc>().changeInputs(phonePrefix: value);
                    context.read<PaymentBloc>().validateInput(phoneNumber: true);
                }),
            ),
            Expanded(
              child: IziInput(
                labelInput: LocaleKeys.payment_inputs_phoneNumber_label.tr(),
                inputHintText: LocaleKeys.payment_inputs_phoneNumber_placeholder.tr(),
                bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
                inputMaxLength: PaymentInputs.phoneMaxLength,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                ],
                controller: phoneController,
                inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                    ? InputSize.big
                    : InputSize.normal,
                onEditingComplete: () {
                  context.read<PaymentBloc>().validateInput(phoneNumber: true);
                },
                onChanged: (value, valueRaw) {
                  final phone = PaymentInputs.limit(value, PaymentInputs.phoneMaxLength);
                  if (phone != value) {
                    phoneController.text = phone;
                  }
                  context.read<PaymentBloc>().changeInputs(phoneNumber: phone);
                },
                error: _getErrorsPhoneNumber(widget.state.phoneNumber.inputError),
                inputType: ((ru.gtSm() && ru.isVertical()))?InputType.keyboard:InputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        IziText.label(
            color: context.iziColors.darkGrey,
            text: widget.state.wantsInvoice
                ? LocaleKeys.payment_inputs_phoneNumber_description.tr()
                : LocaleKeys.payment_inputs_phoneNumber_descriptionOrder.tr(),
            fontWeight: FontWeight.w500,
            maxLines: 3),
      ],
    );
  }

  Widget _invoiceForm(BuildContext context, ResponsiveUtils ru) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentPageInvoiceForm(paymentState: widget.state),
        const SizedBox(
          height: 16,
        ),
        IziInput(
          labelInput: LocaleKeys.payment_inputs_businessName_label.tr(),
          inputHintText:
              LocaleKeys.payment_inputs_businessName_placeholder.tr(),
          inputMaxLength: PaymentInputs.businessNameMaxLength,
          inputFormatters: [
            FilteringTextInputFormatter.deny(PaymentInputs.outsideBasicPlane),
            FilteringTextInputFormatter.deny(PaymentInputs.invisibleCharacters)
          ],
          bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
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
        if(!showEmail)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ru.gtSm()?
              IziLinkBig(linkText: LocaleKeys.payment_links_addEmail.tr(), linkOnPressed: (){
                setState(() {
                  showEmail=true;
                });
              }, linkColor: context.iziColors.primary):
              IziLink(linkText: LocaleKeys.payment_links_addEmail.tr(), linkOnPressed: (){
                setState(() {
                  showEmail=true;
                });}, linkColor: context.iziColors.primary)
            ],
          ),
        if(showEmail)
        IziInput(
          labelInput: LocaleKeys.payment_inputs_email_label.tr(),
          inputHintText: LocaleKeys.payment_inputs_email_placeholder.tr(),
          inputMaxLength: PaymentInputs.emailInputMaxLength,
          inputFormatters: [
            FilteringTextInputFormatter.deny(PaymentInputs.whitespace)
          ],
          bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
          readOnly:
              widget.state.qrCharge != null || widget.state.qrLoading == true,
          inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
              ? InputSize.big
              : InputSize.normal,
          onChanged: (value, valueRaw) {
            context.read<PaymentBloc>().changeInputs(email: value);
          },
          onEditingComplete: () {
            context
                .read<PaymentBloc>()
                .validateInput(email: true);
          },
          controller: emailController,
          value: widget.state.email.value,
          error: _getErrorsEmail(widget.state.email.inputError),
          inputType: InputType.email,
        ),
      ],
    );
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
                    splashColor: context.iziColors.secondaryDarken,
                    focusColor: context.iziColors.secondaryDarken,
                    highlightColor: context.iziColors.secondaryDarken,
                    hoverColor: context.iziColors.secondaryDarken,
                    borderRadius: BorderRadius.circular(6),
                    child: Ink(
                      decoration: BoxDecoration(
                          color: context.iziColors.secondary,
                          borderRadius: BorderRadius.circular(6)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "${LocaleKeys.payment_body_total.tr()}: ${widget.state.paymentObj?.amount.moneyFormat(currency: widget.state.currentCurrency?.simbolo, digitsTaxes: authState.taxesStrategy.decimals)}",
                              maxLines: 5,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  height: 1.2,
                                  color: context.iziColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20),
                            ),
                            Text(
                              LocaleKeys.payment_buttons_proceedPayment.tr(),
                              maxLines: 5,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: context.iziColors.white, fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                      right: 8,
                      child: Icon(
                        IziIcons.rightB,
                        size: 32,
                        color: context.iziColors.white,
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

  _paymentCard() {
    if (widget.state.izifyPosIp != null) {
      _paymentCardIzify(context);
    } else if (authState.currentDevice?.config.ipLinkser != null) {
      _paymentCardLinkser(context);
    } else if (authState.currentDevice?.config.ipAtc != null) {
      _paymentCardATC(context);
    }
  }

  _paymentCardIzify(BuildContext context) async {
    CustomAlerts.defaultAlert(
            context: context,
            dismissible: true,
            defaultScroll: false,
            child: CardTypeIzifyModal(
                amount: (widget.state.paymentObj?.amount ?? 0)))
        .then((value) async {
      if (value is String) {
        context.read<PageUtilsBloc>().closeScreenActive();
        var status = await context.read<PaymentBloc>().makeCardPayment(
            authState,
            izify: true,
            cardType: value);
        if (!mounted) {
          return;
        }
        if (!status) {
          context.read<PageUtilsBloc>().initScreenActiveInvoiced(authState);
        }
      }
    });
  }

  _paymentCardLinkser(BuildContext context) async {
    context.read<PageUtilsBloc>().closeScreenActive();
    var status = await context
        .read<PaymentBloc>()
        .makeCardPayment(authState, linkser: true);
    if (!mounted) {
      return;
    }
    if (!status) {
      context.read<PageUtilsBloc>().initScreenActiveInvoiced(authState);
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
            authState,
            atc: true,
            contactless: value == 1 ? false : true);
        if (!mounted) {
          return;
        }
        if (!status) {
          context.read<PageUtilsBloc>().initScreenActiveInvoiced(authState);
        }
      }
    });
  }

  String? _getErrorsCustomerName(InputError? inputError) {
    switch (inputError) {
      case InputError.required:
        return LocaleKeys.payment_inputs_customerName_errors_required.tr();
      case InputError.min:
        return LocaleKeys.payment_inputs_customerName_errors_min.tr();
      case InputError.max:
        return LocaleKeys.payment_inputs_customerName_errors_max.tr();
      case InputError.invalid:
        return LocaleKeys.payment_inputs_customerName_errors_invalid.tr();
      default:
        return null;
    }
  }

  String? _getErrorsBusinessName(InputError? inputError) {
    switch (inputError) {
      case InputError.required:
        return LocaleKeys.payment_inputs_businessName_errors_required.tr();
      case InputError.min:
        return LocaleKeys.payment_inputs_businessName_errors_min.tr();
      case InputError.max:
        return LocaleKeys.payment_inputs_businessName_errors_max.tr();
      default:
        return null;
    }
  }


  String? _getErrorsEmail(InputError? inputError) {
    switch (inputError) {
      case InputError.max:
        return LocaleKeys.payment_inputs_email_errors_max.tr();
      case InputError.invalid:
        return LocaleKeys.payment_inputs_email_errors_invalid.tr();
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
    customerNameController.text = "";
    emailController.text = "";
    context.read<PaymentBloc>().changeInputs(
      phoneNumber: "",
      documentNumber: "",
      businessName: "",
      customerName: "",
      email: "",
      complement: ""
    );
    setState(() {
      showEmail = false;
    });
  }

  _makePayment(){
    switch(widget.state.paymentType){
      case PaymentType.qr:
        context.read<PaymentBloc>().generateQR(authState);
        break;
      case PaymentType.card:
        _paymentCard();
        break;
      case PaymentType.breb:
        context.read<PaymentBloc>().generateBREB(authState);
        break;
      default:
        break;
    }
  }
}
