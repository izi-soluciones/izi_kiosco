import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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


  Widget _invoiceForm(BuildContext context, ResponsiveUtils ru) {
    return ColumnContainer(
      gap: 16,
      children: [
        if (widget.state.usaSiat && ru.isXs())
          IziInput(
            labelInput: LocaleKeys.payment_inputs_documentType_label.tr(),
            inputHintText: "",
            bigLabel: true,
            value: widget.state.documentType?.codigoClasificador,
            inputType: InputType.select,
            inputSize: InputSize.big,
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
                  bigLabel: true,
                  value: widget.state.documentType?.codigoClasificador,
                  inputType: InputType.select,
                  inputSize: InputSize.big,
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
                bigLabel: true,
                inputSize: InputSize.big,
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
                  bigLabel: true,
                  inputSize: InputSize.big,
                  inputType: InputType.normal,
                ),
              ),
          ],
        ),
        IziInput(
          labelInput: LocaleKeys.payment_inputs_businessName_label.tr(),
          inputHintText:
              LocaleKeys.payment_inputs_businessName_placeholder.tr(),
          bigLabel: true,
          inputSize: InputSize.big,
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
          bigLabel: true,
          inputSize: InputSize.big,
          onChanged: (value, valueRaw) {
            context.read<PaymentBloc>().changeInputs(email: value);
          },
          onEditingComplete: () {
            context.read<PaymentBloc>().validateInput(email: true);
          },
          error: _getErrorsEmail(widget.state.email.inputError),
          inputType: InputType.normal,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IziInput(
              labelInput: LocaleKeys.payment_inputs_phoneNumber_label.tr(),
              inputHintText: "",
              bigLabel: true,
              inputSize: InputSize.big,
              onChanged: (value, valueRaw) {
                context.read<PaymentBloc>().changeInputs(phoneNumber: value);
              },
              onEditingComplete: () {
                context.read<PaymentBloc>().validateInput(phoneNumber: true);
              },
              error: _getErrorsPhoneNumber(widget.state.phoneNumber.inputError),
              inputType: InputType.number,
            ),
            IziText.label(color: IziColors.darkGrey, text: LocaleKeys.payment_inputs_phoneNumber_description.tr(), fontWeight: FontWeight.w500),
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
                    buttonText: LocaleKeys.payment_buttons_makeOrder.tr(),
                    buttonType: ButtonType.secondary,
                    buttonSize:
                        ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
                    loading: widget.state.status == PaymentStatus.waitingInvoice,
                    buttonOnPressed: () {
                      context.read<PageUtilsBloc>().lockPage();
                      context
                          .read<PaymentBloc>().
                          generateOrder(authState: context.read<AuthBloc>().state).then((result){
                        if(result==false){
                          context.read<PageUtilsBloc>().unlockPage();
                        }
                      });
                    }),
              ),
            if (ru.gtXs())
              IziBtn(
                  buttonText: LocaleKeys.payment_buttons_makeOrder.tr(),
                  buttonType: ButtonType.secondary,
                  buttonSize: ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
                  loading: widget.state.status == PaymentStatus.waitingInvoice,
                  buttonOnPressed: () {
                    context.read<PageUtilsBloc>().lockPage();
                    context
                        .read<PaymentBloc>()
                        .generateOrder(authState: context.read<AuthBloc>().state).then((result){
                      if(result==false){
                        context.read<PageUtilsBloc>().unlockPage();
                      }
                    });
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
                      context.read<PaymentBloc>().generateOrder(
                          authState: context.read<AuthBloc>().state,
                          noData: true).then((result){
                        if(result==false){
                          context.read<PageUtilsBloc>().unlockPage();
                        }
                      });
                    }),
              ),
            if (ru.gtXs())
              IziBtn(
                  buttonText: LocaleKeys.payment_buttons_generateNoData.tr(),
                  buttonType: ButtonType.outline,
                  buttonSize: ButtonSize.medium,
                  buttonOnPressed: () async{
                    context.read<PageUtilsBloc>().lockPage();
                   context.read<PaymentBloc>().generateOrder(
                        authState: context.read<AuthBloc>().state,
                        noData: true).then((result){
                      if(result==false){
                        context.read<PageUtilsBloc>().unlockPage();
                      }
                    });
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
  String? _getErrorsEmail(InputError? inputError) {
    switch (inputError) {
      case InputError.invalid:
        return LocaleKeys.payment_inputs_email_errors_invalid.tr();
      default:
        return null;
    }
  }

}
