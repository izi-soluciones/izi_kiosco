import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_checkbox.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_checkbox_label.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/molecules/izi_switch.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_header.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
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
  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Column(
      children: [
        PaymentHeader(
          onPop: () {
            context.read<PaymentBloc>().backReset();
          },
          currency: widget.state.currentCurrency?.simbolo ??
              AppConstants.defaultCurrency,
          popText: ru.gtXs() ? LocaleKeys.payment_titles_checkIn.tr() : null,
          widget: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                IziIcons.dashboard,
                size: 34,
                color: IziColors.darkGrey,
              ),
              IziText.title(
                  color: IziColors.dark,
                  text: LocaleKeys.payment_subtitles_invoiceData.tr(),
                  textAlign: TextAlign.center)
            ],
          ),
        ),
        Expanded(
          child: IziScroll(
            scrollController: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: _invoiceForm(context, ru)),
              ),
            ),
          ),
        )
      ],
    );
  }

  String _selectPaymentTypeValue(PaymentType paymentType) {
    switch (paymentType) {
      case PaymentType.cash:
        return LocaleKeys.payment_buttons_cash.tr();

      case PaymentType.card:
        return LocaleKeys.payment_buttons_card.tr();

      case PaymentType.qr:
        return LocaleKeys.payment_buttons_qr.tr();

      case PaymentType.gitCard:
        return LocaleKeys.payment_buttons_giftCard.tr();

      case PaymentType.bankTransfer:
        return LocaleKeys.payment_buttons_bankTransfer.tr();

      case PaymentType.others:
        return LocaleKeys.payment_buttons_others.tr();
    }
  }

  Widget _invoiceForm(BuildContext context, ResponsiveUtils ru) {
    TextEditingController textEditingController = TextEditingController(
        text: _selectPaymentTypeValue(widget.state.paymentType));
    return ColumnContainer(
      gap: 16,
      children: [
        IziInput(
          labelInput: LocaleKeys.payment_inputs_paymentType_label.tr(),
          inputHintText: "",
          controller: textEditingController,
          readOnly: true,
          bigLabel: ru.gtXs(),
          inputType: InputType.normal,
        ),
        IziInput(
          labelInput: LocaleKeys.payment_inputs_cashRegister_label.tr(),
          inputHintText: "",
          bigLabel: ru.gtXs(),
          value: widget.state.currentCashRegister?.id,
          inputType: InputType.select,
          onSelected: (value) {
            context.read<PaymentBloc>().changeInputs(cashRegister: value);
          },
          selectOptions: {
            for (CashRegister cash in widget.state.cashRegisters)
              cash.id: cash.nombre
          },
        ),
        if (widget.state.usaSiat)
          IziCheckboxLabel(
            onPressCheckbox: () {
              context
                  .read<PaymentBloc>()
                  .changeInputs(withException: !widget.state.withException);
            },
            checkboxType: widget.state.withException
                ? CheckboxType.checkboxChecked
                : CheckboxType.checkboxDefault,
            checkboxLabelTitle:
                LocaleKeys.payment_inputs_withException_label.tr(),
          ),
        if (widget.state.usaSiat && ru.isXs())
          IziInput(
            labelInput: LocaleKeys.payment_inputs_documentType_label.tr(),
            inputHintText: "",
            bigLabel: ru.gtXs(),
            value: widget.state.documentType?.codigoClasificador,
            inputType: InputType.select,
            onSelected: (value) {
              context
                  .read<PaymentBloc>()
                  .changeInputs(documentType: value);
            },
            selectOptions: {
              for (DocumentType type in widget.state.documentTypes)
                type.codigoClasificador: type.descripcion
            },
          ),
        RowContainer(
          gap: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.state.usaSiat && ru.gtXs())
              Expanded(
                flex: 1,
                child: IziInput(
                  labelInput: LocaleKeys.payment_inputs_documentType_label.tr(),
                  inputHintText: "",
                  bigLabel: ru.gtXs(),
                  value: widget.state.documentType?.codigoClasificador,
                  inputType: InputType.select,
                  onSelected: (value) {
                    context
                        .read<PaymentBloc>()
                        .changeInputs(documentType: value);
                  },
                  selectOptions: {
                    for (DocumentType type in widget.state.documentTypes)
                      type.codigoClasificador: type.descripcion
                  },
                ),
              ),
            Expanded(
              flex: 2,
              child: IziInput(
                labelInput: LocaleKeys.payment_inputs_documentNumber_label.tr(),
                bigLabel: ru.gtXs(),
                onChanged: (value, valueRaw) {
                  context
                      .read<PaymentBloc>()
                      .changeInputs(documentNumber: value);
                  if (value.length >= 3) {
                    context.read<PaymentBloc>().queryBusiness(
                        authState: context.read<AuthBloc>().state,
                        query: value);
                  }
                },
                loadingAutoComplete: widget.state.documentNumber.loading,
                onSelected: (value) {
                  var business = widget.state.queryBusinessList
                      .firstWhere((element) => element.id == value);
                  context
                      .read<PaymentBloc>()
                      .changeInputs(businessName: business.razonSocial);
                  businessNameController.text = business.razonSocial ?? "";
                },
                onEditingComplete: () {
                  context
                      .read<PaymentBloc>()
                      .validateInput(documentNumber: true);
                },
                selectOptions: {
                  for (Contribuyente c in widget.state.queryBusinessList)
                    c.id: "${c.nit} - ${c.razonSocial}"
                },
                error: _getErrorsDocumentNumber(
                    widget.state.documentNumber.inputError),
                inputHintText:
                    LocaleKeys.payment_inputs_documentNumber_placeholder.tr(),
                inputType: InputType.autocomplete,
              ),
            ),
            if (widget.state.usaSiat)
              Expanded(
                flex: 1,
                child: IziInput(
                  labelInput: LocaleKeys.payment_inputs_complement_label.tr(),
                  inputHintText: "",
                  onChanged: (value, valueRaw) {
                    context.read<PaymentBloc>().changeInputs(complement: value);
                  },
                  bigLabel: ru.gtXs(),
                  inputType: InputType.normal,
                ),
              ),
          ],
        ),
        IziInput(
          labelInput: LocaleKeys.payment_inputs_businessName_label.tr(),
          inputHintText:
              LocaleKeys.payment_inputs_businessName_placeholder.tr(),
          bigLabel: ru.gtXs(),
          onChanged: (value, valueRaw) {
            context.read<PaymentBloc>().changeInputs(businessName: value);
          },
          onEditingComplete: () {
            context.read<PaymentBloc>().validateInput(businessName: true);
          },
          controller: businessNameController,
          value: widget.state.businessName.value,
          error: _getErrorsBusinessName(widget.state.businessName.inputError),
          inputType: InputType.normal,
        ),
        IziInput(
          labelInput: LocaleKeys.payment_inputs_email_label.tr(),
          inputHintText: LocaleKeys.payment_inputs_email_placeholder.tr(),
          bigLabel: ru.gtXs(),
          onChanged: (value, valueRaw) {
            context.read<PaymentBloc>().changeInputs(email: value);
          },
          onEditingComplete: () {
            context.read<PaymentBloc>().validateInput(email: true);
          },
          error: _getErrorsEmail(widget.state.email.inputError),
          inputType: InputType.normal,
        ),
        Row(
          children: [
            IziSwitch(
              large: ru.gtXs(),
                label: LocaleKeys.payment_inputs_isManual_label.tr(),
                value: widget.state.isManual,
                onChanged: (value) {
                  context.read<PaymentBloc>().changeInputs(isManual: value);
                }),
          ],
        ),
        if (widget.state.isManual)
          RowContainer(
            gap: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: IziInput(
                  labelInput: LocaleKeys.payment_inputs_invoiceNumber_label.tr(),
                  inputHintText: "",
                  bigLabel: ru.gtXs(),
                  onChanged: (value, valueRaw) {
                    context.read<PaymentBloc>().changeInputs(invoiceNumber: value);
                  },
                  onEditingComplete: () {
                    context.read<PaymentBloc>().validateInput(invoiceNumber: true);
                  },
                  error: _getErrorsInvoiceNumber(widget.state.invoiceNumber.inputError),
                  inputType: InputType.normal,
                ),
              ),
              Expanded(
                child: IziInput(
                  labelInput: LocaleKeys.payment_inputs_authorization_label.tr(),
                  inputHintText: "**************",
                  bigLabel: ru.gtXs(),
                  onChanged: (value, valueRaw) {
                    context.read<PaymentBloc>().changeInputs(authorization: value);
                  },
                  onEditingComplete: () {
                    context.read<PaymentBloc>().validateInput(authorization: true);
                  },
                  error: _getErrorsAuthorization(widget.state.authorization.inputError),
                  inputType: InputType.normal,
                ),
              ),
            ],
          ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ru.isXs())
              Flexible(
                child: IziBtn(
                    buttonText: LocaleKeys.payment_buttons_generateInvoice.tr(),
                    buttonType: ButtonType.secondary,
                    buttonSize:
                        ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
                    loading: widget.state.status == PaymentStatus.waitingInvoice,
                    buttonOnPressed: () {
                      context.read<PageUtilsBloc>().lockPage();
                      context
                          .read<PaymentBloc>()
                          .emitInvoice(authState: context.read<AuthBloc>().state);
                    }),
              ),
            if (ru.gtXs())
              IziBtn(
                  buttonText: LocaleKeys.payment_buttons_generateInvoice.tr(),
                  buttonType: ButtonType.secondary,
                  buttonSize: ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
                  loading: widget.state.status == PaymentStatus.waitingInvoice,
                  buttonOnPressed: () {
                    context.read<PageUtilsBloc>().lockPage();
                    context
                        .read<PaymentBloc>()
                        .emitInvoice(authState: context.read<AuthBloc>().state);
                  }),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ru.isXs())
              Flexible(
                child: IziBtn(
                    buttonText:
                        widget.state.casaMatriz?.config?["nombrePreFactura"] ??
                            LocaleKeys.payment_buttons_defaultPreInvoice.tr(),
                    buttonType: ButtonType.primary,
                    buttonSize: ButtonSize.medium,
                    loading:
                        widget.state.status == PaymentStatus.waitingPreInvoice,
                    buttonOnPressed: () {
                      context.read<PageUtilsBloc>().lockPage();
                      context.read<PaymentBloc>().emitInvoice(
                          authState: context.read<AuthBloc>().state,
                          prefactura: true);
                    }),
              ),
            if (ru.gtXs())
              IziBtn(
                  buttonText:
                      widget.state.casaMatriz?.config?["nombrePreFactura"] ??
                          LocaleKeys.payment_buttons_defaultPreInvoice.tr(),
                  buttonType: ButtonType.primary,
                  buttonSize: ButtonSize.medium,
                  loading:
                      widget.state.status == PaymentStatus.waitingPreInvoice,
                  buttonOnPressed: () {
                    context.read<PageUtilsBloc>().lockPage();
                    context.read<PaymentBloc>().emitInvoice(
                        authState: context.read<AuthBloc>().state,
                        prefactura: true);
                  }),
          ],
        ),
        const SizedBox(
          height: 30,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ru.isXs())
              Flexible(
                child: IziBtn(
                    buttonText: LocaleKeys.payment_buttons_generateNoData.tr(),
                    buttonType: ButtonType.outline,
                    buttonSize: ButtonSize.medium,
                    buttonOnPressed: () {
                      context.read<PageUtilsBloc>().lockPage();
                      context.read<PaymentBloc>().emitInvoice(
                          authState: context.read<AuthBloc>().state,
                          noData: true);
                    }),
              ),
            if (ru.gtXs())
              IziBtn(
                  buttonText: LocaleKeys.payment_buttons_generateNoData.tr(),
                  buttonType: ButtonType.outline,
                  buttonSize: ButtonSize.medium,
                  buttonOnPressed: () {
                    context.read<PageUtilsBloc>().lockPage();
                    context.read<PaymentBloc>().emitInvoice(
                        authState: context.read<AuthBloc>().state,
                        noData: true);
                  }),
          ],
        ),
      ],
    );
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

  String? _getErrorsEmail(InputError? inputError) {
    switch (inputError) {
      case InputError.invalid:
        return LocaleKeys.payment_inputs_email_errors_invalid.tr();
      default:
        return null;
    }
  }

  String? _getErrorsAuthorization(InputError? inputError){

    switch (inputError) {
      case InputError.required:
        return LocaleKeys.payment_inputs_authorization_errors_required.tr();
      default:
        return null;
    }
  }
  String? _getErrorsInvoiceNumber(InputError? inputError){

    switch (inputError) {
      case InputError.required:
        return LocaleKeys.payment_inputs_invoiceNumber_errors_required.tr();
      default:
        return null;
    }
  }
}
