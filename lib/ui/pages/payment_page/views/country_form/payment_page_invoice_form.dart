import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/models/identification_type.dart';
import 'package:izi_kiosco/domain/models/iva_responsability.dart';
import 'package:izi_kiosco/domain/models/person_type.dart';
import 'package:izi_kiosco/domain/models/tax_responsability.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class PaymentPageInvoiceForm extends StatefulWidget {
  final PaymentState paymentState;
  const PaymentPageInvoiceForm({super.key, required this.paymentState});

  @override
  State<PaymentPageInvoiceForm> createState() => _PaymentPageInvoiceFormState();
}

class _PaymentPageInvoiceFormState extends State<PaymentPageInvoiceForm> {

  TextEditingController documentNumberController = TextEditingController();
  TextEditingController complementController = TextEditingController();

  TextEditingController personTypeController = TextEditingController();
  TextEditingController identificationTypeController = TextEditingController();
  TextEditingController ivaResponsabilityController = TextEditingController();
  TextEditingController taxResponsabilityController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    ResponsiveUtils ru = ResponsiveUtils(context);
    return BlocListener<PaymentBloc,PaymentState>(listener: (context, state) {
      if(state.status==PaymentStatus.setInputs){ 
        documentNumberController.text=state.documentNumber.value;
        complementController.text=state.complement.value;

        personTypeController.text=state.paramsCo?.listPersonType.firstWhereOrNull((element) => element.codigo==state.paramsCo?.personType)?.nombre ?? "";
        identificationTypeController.text=state.paramsCo?.listIdentificationType.firstWhereOrNull((element) => element.codigo==state.paramsCo?.identificationType)?.nombre ?? "";
        ivaResponsabilityController.text=state.paramsCo?.listIvaResponsability.firstWhereOrNull((element) => element.codigo==state.paramsCo?.ivaResponsability)?.nombre ?? "";
        taxResponsabilityController.text=state.paramsCo?.listTaxResponsability.firstWhereOrNull((element) => element.codigo==state.paramsCo?.taxResponsability)?.nombre ?? "";

      }
      },
      child: Builder(builder: (_) {
          if(widget.paymentState.countryTaxes==PaymentCountryTaxes.bolivia){
            return _bo(ru,context);
          }
          if(widget.paymentState.countryTaxes==PaymentCountryTaxes.colombia){
            return _co(ru,context);
          }
          return _documentNumber(ru,context);
      },),
    );
  }

  _documentType(ResponsiveUtils ru, BuildContext context){
    return IziInput(
        inputHintText: "",
        bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
        value: widget.paymentState.paramsBo?.documentType?.codigoClasificador,
        inputType: InputType.select,
        inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
            ? InputSize.big
            : InputSize.normal,
        readOnly: widget.paymentState.qrCharge != null ||
            widget.paymentState.qrLoading == true,
        onSelected: (value) {
          context.read<PaymentBloc>().changeInputsBo(documentType: value);
        },
        selectOptions: {
          for (DocumentType type in widget.paymentState.paramsBo?.documentTypes ??[])
            type.codigoClasificador:
                type.descripcion.split("-").firstOrNull ?? ""
        },
      );
  }

  Widget _documentNumber(ResponsiveUtils ru,BuildContext context){
    return IziInput(
                  bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
                  inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
                      ? InputSize.big
                      : InputSize.normal,
                  inputMaxLength: 50,
                  suffixWidget: widget.paymentState.documentNumber.loading
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
                      context.read<PaymentBloc>().changeInputs(
                          documentNumber: documentNumberController.text);
                  },
                  onEditingComplete: () {
                      context
                          .read<PaymentBloc>()
                          .queryBusiness(
                              authState: context.read<AuthBloc>().state)
                          .then((value) {
                        context.read<PaymentBloc>().validateInput(
                            documentNumber: true, businessName: true);
                      });
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[1-9]'))
                  ],
                  controller: documentNumberController,
                  loadingAutoComplete: widget.paymentState.documentNumber.loading,
                  error: _getErrorsDocumentNumber(
                      widget.paymentState.documentNumber.inputError),
                  inputHintText: LocaleKeys
                      .payment_inputs_documentNumber_placeholder
                      .tr(args: [
                    (widget.paymentState.paramsBo?.documentType?.descripcion ?? "número")
                        .split("-")
                        .firstOrNull
                        .toString()
                  ]),
                  inputType: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))?InputType.keyboard:InputType.number,
                );
  }

  Widget _bo(ResponsiveUtils ru, BuildContext context){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        IziText.body(
            color: IziColors.darkGrey,
            text: LocaleKeys.payment_inputs_documentNumber_label.tr(),
            fontWeight: FontWeight.w400),
            const SizedBox(
              height: 4,
            ),
        if (ru.isXs())
         _documentType(ru, context),
        if (ru.isXs())
          const SizedBox(
            height: 16,
          ),
          RowContainer(
            gap: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ru.gtXs())
                Expanded(
                  flex: 1,
                  child: _documentType(ru, context)
                ),
              Expanded(
                flex: 2,
                child: _documentNumber(ru, context)
              ),
              if (
                  widget.paymentState.paramsBo?.documentType?.codigoClasificador ==
                      AppConstants.codeCI)
                Expanded(
                  flex: 1,
                  child: IziInput(
                    inputHintText: "",
                    inputMaxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                    ],
                    readOnly: widget.paymentState.qrCharge != null ||
                        widget.paymentState.qrLoading == true,
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

  Widget _co(ResponsiveUtils ru, BuildContext context){
    return Column(
      children: [

        IziText.body(
            color: IziColors.darkGrey,
            text: LocaleKeys.payment_inputs_documentNumber_label.tr(),
            fontWeight: FontWeight.w400),
        const SizedBox(
          height: 4,
        ),
        _documentNumber(ru, context),
            const SizedBox(
              height: 16,
            ),

        IziInput(
          controller: identificationTypeController,
          inputHintText: "",
          bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
          value: widget.paymentState.paramsCo?.identificationType,
          inputType: InputType.select,
          inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
              ? InputSize.big
              : InputSize.normal,
          readOnly: widget.paymentState.qrCharge != null ||
              widget.paymentState.qrLoading == true,
          onSelected: (value) {
            context.read<PaymentBloc>().changeInputsCo(identificationType: value);
          },
          selectOptions: {
            for (IdentificationType type in widget.paymentState.paramsCo?.listIdentificationType ??[])
              type.codigo:
                  type.nombre
          },
        ),
            const SizedBox(
              height: 16,
            ),


        IziInput(
          controller: ivaResponsabilityController,
          inputHintText: "",
          bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
          value: widget.paymentState.paramsCo?.ivaResponsability,
          inputType: InputType.select,
          inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
              ? InputSize.big
              : InputSize.normal,
          readOnly: widget.paymentState.qrCharge != null ||
              widget.paymentState.qrLoading == true,
          onSelected: (value) {
            context.read<PaymentBloc>().changeInputsCo(ivaResponsability: value);
          },
          selectOptions: {
            for (IvaResponsability type in widget.paymentState.paramsCo?.listIvaResponsability ??[])
              type.codigo:
                 type.nombre
          },
        ),
            const SizedBox(
              height: 16,
            ),

        IziInput(
          controller: personTypeController,
          inputHintText: "",
          bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
          value: widget.paymentState.paramsCo?.personType,
          inputType: InputType.select,
          inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
              ? InputSize.big
              : InputSize.normal,
          readOnly: widget.paymentState.qrCharge != null ||
              widget.paymentState.qrLoading == true,
          onSelected: (value) {
            context.read<PaymentBloc>().changeInputsCo(personType: value);
          },
          selectOptions: {
            for (PersonType type in widget.paymentState.paramsCo?.listPersonType ??[])
              type.codigo:
                  type.nombre
          },
        ),
            const SizedBox(
              height: 16,
            ),

        IziInput(
          controller: taxResponsabilityController,
          inputHintText: "",
          bigLabel: (ru.gtMd() || (ru.gtSm() && ru.isVertical())),
          value: widget.paymentState.paramsCo?.taxResponsability,
          inputType: InputType.select,
          inputSize: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))
              ? InputSize.big
              : InputSize.normal,
          readOnly: widget.paymentState.qrCharge != null ||
              widget.paymentState.qrLoading == true,
          onSelected: (value) {
            context.read<PaymentBloc>().changeInputsCo(taxResponsability: value);
          },
          selectOptions: {
            for (TaxResponsability type in widget.paymentState.paramsCo?.listTaxResponsability ??[])
              type.codigo:
                  type.nombre
          },
        ),
      ],
    );

  }
}