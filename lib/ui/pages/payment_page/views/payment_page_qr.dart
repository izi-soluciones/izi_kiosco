import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_header.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

import 'package:izi_kiosco/ui/utils/web_image.dart';

class PaymentPageQr extends StatefulWidget {
  final PaymentState state;
  const PaymentPageQr({super.key,required this.state});

  @override
  State<PaymentPageQr> createState() => _PaymentPageQrState();
}

class _PaymentPageQrState extends State<PaymentPageQr> {
  TextEditingController businessNameController = TextEditingController();
  bool businessFocus=false;
  TextEditingController documentNumberController = TextEditingController();
  bool documentNumberFocus=false;
  TextEditingController emailController = TextEditingController();
  bool emailFocus=false;
  TextEditingController phoneController = TextEditingController();
  bool phoneFocus=false;

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              PaymentHeader(
                currency:
                widget.state.currentCurrency?.simbolo ?? AppConstants.defaultCurrency,
                popText: ru.gtXs() ? LocaleKeys.payment_titles_qr.tr() : null,
                amount: (widget.state.order?.monto??0),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 600,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          _invoiceForm(context, ru),
                          const SizedBox(height: 50,),
                          ConstrainedBox(
                              constraints:  const BoxConstraints(
                                  maxWidth: 400
                              ),
                              child: Center(
                                child: widget.state.qrCharge!=null?
                                    _qrWidget():
                                    widget.state.qrLoading?
                                const SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ):const SizedBox.shrink(),
                              )
                          ),
                          const SizedBox(height: 50,),
                        ],
                      )
                  ),
                ),
              ),
            ],
          ),
        ),
        /*if(businessFocus || phoneFocus || emailFocus|| documentNumberFocus)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: (){
              setState(() {
                businessFocus=false;
                phoneFocus=false;
                emailFocus=false;
                documentNumberFocus=false;
              });
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        if(businessFocus || phoneFocus || emailFocus || documentNumberFocus)
          Positioned(
          top: 0,
          child: Container(
            color: IziColors.darkGrey,
            child: VirtualKeyboard(
                height: 300,
                fontSize: 30,
                alwaysCaps: true,
                textColor: Colors.white,
                textController:
                businessFocus?businessNameController:
                phoneFocus? phoneController:
                emailFocus? emailController:
                documentNumberController,
                type: phoneFocus?VirtualKeyboardType.Numeric:VirtualKeyboardType.Alphanumeric,
                onKeyPress: (value){

                }),
          ),
        )*/
      ],
    );
  }


  Widget _qrWidget(){
    if(widget.state.qrCharge?.qrUrl!=null){
      return
        kIsWeb?
        AspectRatio(
            aspectRatio: 1,
            child: WebImage(imageUrl: widget.state.qrCharge!.qrUrl!)
        ):
        Image.network(widget.state.qrCharge!.qrUrl!,fit: BoxFit.fitWidth);
    }
    if(widget.state.qrCharge?.qrBase64!=null){
      return AspectRatio(aspectRatio: 1,child: Image.memory(const Base64Decoder().convert(widget.state.qrCharge!.qrBase64!),fit: BoxFit.fitWidth));
    }
    return const SizedBox.shrink();
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
            readOnly: widget.state.qrCharge!=null,
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
                  readOnly: widget.state.qrCharge!=null,
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
                readOnly: widget.state.qrCharge!=null,
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
                onClick: (){
                  setState(() {
                    businessFocus=false;
                    documentNumberFocus=true;
                    emailFocus=false;
                    phoneFocus=false;
                  });
                },
                controller: documentNumberController,
                loadingAutoComplete: widget.state.documentNumber.loading,
                onSelected: (value) {
                  var business = widget.state.queryBusinessList
                      .firstWhere((element) => element.id == value);
                  context
                      .read<PaymentBloc>()
                      .changeInputs(businessName: business.razonSocial,documentNumber: business.nit);
                  businessNameController.text = business.razonSocial ?? "";
                },
                onEditingComplete: () {
                  context
                      .read<PaymentBloc>()
                      .validateInput(documentNumber: true,businessName: true);
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
                  readOnly: widget.state.qrCharge!=null,
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
          readOnly: widget.state.qrCharge!=null,
          inputSize: InputSize.big,

          onChanged: (value, valueRaw) {
            context.read<PaymentBloc>().changeInputs(businessName: value);
          },
          onEditingComplete: () {
            context
                .read<PaymentBloc>()
                .validateInput(documentNumber: true,businessName: true);
          },
          onClick: (){
            setState(() {
              businessFocus=true;
              documentNumberFocus=false;
              emailFocus=false;
              phoneFocus=false;
            });
          },
          controller: businessNameController,
          value: widget.state.businessName.value,
          error: _getErrorsBusinessName(widget.state.businessName.inputError),
          inputType: InputType.normal,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IziInput(
              labelInput: LocaleKeys.payment_inputs_phoneNumber_label.tr(),
              inputHintText: "",
              bigLabel: true,
              controller: phoneController,
              readOnly: widget.state.qrCharge!=null,
              inputSize: InputSize.big,
              onChanged: (value, valueRaw) {
                context.read<PaymentBloc>().changeInputs(phoneNumber: value);
              },
              onClick: (){
                setState(() {
                  businessFocus=false;
                  documentNumberFocus=false;
                  emailFocus=false;
                  phoneFocus=true;
                });
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
          height: 30,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ru.isXs())
              Flexible(
                child: IziBtn(
                    buttonText: LocaleKeys.payment_buttons_generateQr.tr(),
                    buttonType: ButtonType.secondary,
                    buttonSize:
                    ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
                    loading: widget.state.status == PaymentStatus.waitingInvoice,
                    buttonOnPressed: () {
                      context.read<PaymentBloc>().generateQR(context.read<AuthBloc>().state);
                    }),
              ),
            if (ru.gtXs())
              IziBtn(
                  buttonText: LocaleKeys.payment_buttons_generateQr.tr(),
                  buttonType: ButtonType.secondary,
                  buttonSize: ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
                  loading: widget.state.status == PaymentStatus.waitingInvoice,
                  buttonOnPressed: () {
                    context.read<PaymentBloc>().generateQR(context.read<AuthBloc>().state);
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

}
