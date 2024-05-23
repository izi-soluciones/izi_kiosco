import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/ui/general/kiosco_numeric_keyboard.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

import 'package:izi_kiosco/ui/utils/web_image.dart';

class PaymentPageQr extends StatefulWidget {
  final PaymentState state;
  const PaymentPageQr({super.key, required this.state});

  @override
  State<PaymentPageQr> createState() => _PaymentPageQrState();
}

class _PaymentPageQrState extends State<PaymentPageQr> {
  TextEditingController businessNameController = TextEditingController();
  TextEditingController documentNumberController = TextEditingController();
  bool documentNumberFocus = false;
  GlobalKey documentNumberKey = GlobalKey();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool phoneFocus = false;
  GlobalKey phoneKey = GlobalKey();

  int qrLock = 0;
  int qrRemaining = 0;

  @override
  void dispose() {
    timerLock?.cancel();
    timerRemaining?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              /*PaymentHeader(
                currency: widget.state.currentCurrency?.simbolo ??
                    AppConstants.defaultCurrency,
                popText: ru.gtXs() ? LocaleKeys.payment_titles_qr.tr() : null,
                amount: (widget.state.order?.monto ?? 0),
              ),*/
              SizedBox(
                height: 140,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: InkWell(
                        onTap: () {
                          context.read<PaymentBloc>().changeStep(4);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Icon(IziIcons.leftB, color: IziColors.grey, size: 50),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 0,
                      left: 0,
                      bottom: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          context.read<AuthBloc>().state.currentContribuyente?.logo != null
                              ? SizedBox(
                              height: 100,
                              child: CachedNetworkImage(
                                imageUrl:
                                "${dotenv.env[EnvKeys.apiUrl]}/contribuyentes/${context.read<AuthBloc>().state.currentContribuyente?.id}/logo",
                                fit: BoxFit.fitHeight,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: IziColors.dark)),
                                errorWidget: (context, url, error) {
                                  return const SizedBox.shrink();
                                },
                              ))
                              : const SizedBox.shrink(),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 600,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              IziText.titleMedium(color: IziColors.dark, text: LocaleKeys.payment_subtitles_payAndInvoiced.tr()),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Row(
                            children: [
                              IziText.body(color: IziColors.dark, text: "${LocaleKeys.payment_body_beforePayment.tr()}:", fontWeight: FontWeight.w500),
                            ],
                          ),
                          const SizedBox(
                            height: 32,
                          ),
                          _invoiceForm(context, ru),
                          const SizedBox(
                            height: 30,
                          ),
                          if (widget.state.qrCharge != null)
                            IziText.titleSmall(
                                color: IziColors.dark,
                                text: LocaleKeys.payment_subtitles_scanQrToPay
                                    .tr(),
                                fontWeight: FontWeight.w400),
                          if (widget.state.qrCharge != null)
                            const SizedBox(
                              height: 16,
                            ),
                          ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: (ru.width/2)>400?400:(ru.width/2)),
                              child: Center(
                                child: widget.state.qrCharge != null &&
                                        !widget.state.qrLoading
                                    ? _qrWidget()
                                    : widget.state.qrLoading
                                        ? const Padding(
                                          padding: EdgeInsets.only(bottom: 30),
                                          child: SizedBox(
                                              height: 40,
                                              width: 40,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                              ),
                                            ),
                                        )
                                        : const SizedBox.shrink(),
                              )),
                          if (widget.state.qrCharge != null)
                            const SizedBox(
                              height: 10,
                            ),

                          if (widget.state.qrCharge != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IziText.body(
                                    color: IziColors.darkGrey,
                                    text: "Tiempo Restante: ",
                                    fontWeight: FontWeight.w400),
                                IziText.body(
                                    color: IziColors.primary,
                                    text: "${qrRemaining}s",
                                    fontWeight: FontWeight.w400),
                              ],
                            ),
                          const SizedBox(
                            height: 8,
                          ),
                          IziText.titleMedium(color: IziColors.darkGrey, text: "${ LocaleKeys.payment_body_total.tr()}: ${(widget.state.order?.monto ?? 0).moneyFormat(currency: widget.state.currentCurrency?.simbolo)}",fontWeight: FontWeight.w600),
                          const SizedBox(
                            height: 50,
                          ),
                          if (widget.state.qrCharge != null)
                            IziText.body(
                                color: IziColors.grey,
                                text:
                                    LocaleKeys.payment_body_cantPayWithQR.tr(),
                                fontWeight: FontWeight.w400),

                          if(widget.state.qrWait)
                          Padding(
                            padding: const EdgeInsets.only(top: 32.0),
                            child: IziText.titleSmall(maxLines: 5,textAlign: TextAlign.center,color: IziColors.secondaryDarken, text: "Si ya hiciste el pago, espera unos segundos a que recibamos la confirmación", fontWeight: FontWeight.w500),
                          ),

                        ],
                      )),
                ),
              ),
            ],
          ),
        ),
        if (phoneFocus || documentNumberFocus)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if(phoneFocus){
                  context
                      .read<PaymentBloc>()
                      .validateInput(phoneNumber: true);
                }
                else{
                  context
                      .read<PaymentBloc>()
                      .queryBusiness(authState: context.read<AuthBloc>().state).then((value) {
                    context
                        .read<PaymentBloc>()
                        .validateInput(documentNumber: true, businessName: true);
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
                  if(documentNumberFocus){
                    context.read<PaymentBloc>().changeInputs(
                        documentNumber: documentNumberController.text);
                  }
                  else{
                    context.read<PaymentBloc>().changeInputs(
                        phoneNumber: phoneController.text);
                  }
                },
                onDone: () {
                  if(phoneFocus){
                    context
                        .read<PaymentBloc>()
                        .validateInput(phoneNumber: true);
                  }
                  else{
                    context
                        .read<PaymentBloc>()
                        .queryBusiness(authState: context.read<AuthBloc>().state).then((value) {
                      context
                          .read<PaymentBloc>()
                          .validateInput(documentNumber: true, businessName: true);
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

  Timer? timerRemaining;
  _initTimeRemaining() {
    setState(() {
      qrRemaining = AppConstants.remainingQrTime;
    });
    timerRemaining?.cancel();
    timerRemaining = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (qrRemaining <= 0) {
        _initTimeRemaining();
      } else {
        setState(() {
          qrRemaining--;
        });
      }
    });
  }

  Timer? timerLock;
  _lockQr() {
    setState(() {
      qrLock = AppConstants.regenerateQrTime;
    });
    timerLock = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (qrLock <= 0) {
        timer.cancel();
      } else {
        setState(() {
          qrLock--;
        });
      }
    });
  }

  Widget _qrWidget() {
    if (widget.state.qrCharge?.qrUrl != null) {
      return kIsWeb
          ? AspectRatio(
              aspectRatio: 1,
              child: WebImage(imageUrl: widget.state.qrCharge!.qrUrl!))
          : Image.network(widget.state.qrCharge!.qrUrl!, fit: BoxFit.fitWidth);
    }
    if (widget.state.qrCharge?.qrBase64 != null) {
      return AspectRatio(
          aspectRatio: 1,
          child: Image.memory(
            const Base64Decoder().convert(widget.state.qrCharge!.qrBase64!),
            fit: BoxFit.fitWidth,
            gaplessPlayback: true,
          ));
    }
    return const SizedBox.shrink();
  }

  Widget _invoiceForm(BuildContext context, ResponsiveUtils ru) {
    return BlocListener<PaymentBloc,PaymentState>(
      listener: (context, state) {
        if(state.businessName.value!=businessNameController.text){
          businessNameController.text=state.businessName.value;
        }
      },
      child: ColumnContainer(
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
              readOnly: widget.state.qrCharge != null || widget.state.qrLoading==true,
              onSelected: (value) {
                context.read<PaymentBloc>().changeInputs(documentType: value);
              },
              selectOptions: {
                for (DocumentType type in widget.state.documentTypes)
                  type.codigoClasificador: type.descripcion.split("-").firstOrNull??""
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
                    readOnly: widget.state.qrCharge != null || widget.state.qrLoading==true,
                    onSelected: (value) {
                      context
                          .read<PaymentBloc>()
                          .changeInputs(documentType: value);
                    },
                    selectOptions: {
                      for (DocumentType type in widget.state.documentTypes)
                        type.codigoClasificador: type.descripcion.split("-").firstOrNull??""
                    },
                  ),
                ),
              Expanded(
                flex: 2,
                child: IziInput(
                  key: documentNumberKey,
                  labelInput: LocaleKeys.payment_inputs_documentNumber_label.tr(),
                  bigLabel: true,
                  inputSize: InputSize.big,
                  readOnly: true,
                  suffixWidget: widget.state.documentNumber.loading?Container(padding: const EdgeInsets.symmetric(horizontal: 12),alignment: Alignment.center,height: 20,width:20,child: const CircularProgressIndicator(color: IziColors.darkGrey,strokeWidth: 2,)):null,
                  onChanged: (value, valueRaw) {
                  },
                  onClick: widget.state.qrCharge == null && widget.state.qrLoading==false
                      ? () {
                          setState(() {
                            documentNumberFocus = true;
                            phoneFocus = false;
                          });
                        }
                      : null,
                  controller: documentNumberController,
                  loadingAutoComplete: widget.state.documentNumber.loading,
                  error: _getErrorsDocumentNumber(
                      widget.state.documentNumber.inputError),
                  inputHintText:
                      LocaleKeys.payment_inputs_documentNumber_placeholder.tr(args: [(widget.state.documentType?.descripcion??"número").split("-").firstOrNull.toString()]),
                  inputType: InputType.number,
                ),
              ),
              if (widget.state.usaSiat && widget.state.documentType?.codigoClasificador==AppConstants.codeCI)
                Expanded(
                  flex: 1,
                  child: IziInput(
                    labelInput: LocaleKeys.payment_inputs_complement_label.tr(),
                    inputHintText: "",
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),],
                    readOnly: widget.state.qrCharge != null || widget.state.qrLoading==true,
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
            readOnly: widget.state.qrCharge != null || widget.state.qrLoading==true,
            inputSize: InputSize.big,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IziInput(
                labelInput: LocaleKeys.payment_inputs_phoneNumber_label.tr(),
                inputHintText: LocaleKeys.payment_inputs_phoneNumber_placeholder.tr(),
                bigLabel: true,
                key: phoneKey,
                controller: phoneController,
                readOnly: true,
                inputSize: InputSize.big,
                onClick: widget.state.qrCharge == null && widget.state.qrLoading==false
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
                error: _getErrorsPhoneNumber(widget.state.phoneNumber.inputError),
                inputType: InputType.number,
              ),
              const SizedBox(height: 4),
              IziText.label(
                  color: IziColors.darkGrey,
                  text: LocaleKeys.payment_inputs_phoneNumber_description.tr(),
                  fontWeight: FontWeight.w500,
                  maxLines: 3),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          if(widget.state.paymentType==PaymentType.qr)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (ru.isXs())
                Flexible(
                  child: IziBtn(
                      buttonText: widget.state.qrCharge != null
                          ? "${LocaleKeys.payment_buttons_regenerateQR.tr()} ${qrLock > 0 ? qrLock : ""}"
                          : LocaleKeys.payment_buttons_generateQr.tr(),
                      buttonType: ButtonType.secondary,
                      buttonSize:
                          ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
                      loading:
                          widget.state.status == PaymentStatus.waitingInvoice,
                      buttonOnPressed: qrLock > 0 || widget.state.qrLoading
                          ? null
                          : () async {
                              var res = await context
                                  .read<PaymentBloc>()
                                  .generateQR(context.read<AuthBloc>().state);
                              if (res) {
                                _lockQr();
                                _initTimeRemaining();
                              }
                            }),
                ),
              if (ru.gtXs())
                IziBtn(
                    buttonText: widget.state.qrCharge != null
                        ? "${LocaleKeys.payment_buttons_regenerateQR.tr()} ${qrLock > 0 ? qrLock : ""}"
                        : LocaleKeys.payment_buttons_generateQr.tr(),
                    buttonType: ButtonType.secondary,
                    buttonSize: ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
                    loading: widget.state.status == PaymentStatus.waitingInvoice,
                    buttonOnPressed: qrLock > 0 || widget.state.qrLoading
                        ? null
                        : () async {
                            var res = await context
                                .read<PaymentBloc>()
                                .generateQR(context.read<AuthBloc>().state);
                            if (res) {
                              _lockQr();
                              _initTimeRemaining();
                            }
                          }),
            ],
          ),
          if(widget.state.paymentType==PaymentType.card)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (ru.isXs())
                Flexible(
                  child: IziBtn(
                      buttonText: LocaleKeys.payment_buttons_paymentWithCardPOs.tr(),
                      buttonType: ButtonType.primary,
                      buttonSize:
                      ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
                      buttonOnPressed: () async {
                        context.read<PageUtilsBloc>().closeScreenActive();
                        await context
                            .read<PaymentBloc>()
                            .makeCardPayment(context.read<AuthBloc>().state);
                      }),
                ),
              if (ru.gtXs())
                IziBtn(
                    buttonText: LocaleKeys.payment_buttons_paymentWithCardPOs.tr(),
                    buttonType: ButtonType.primary,
                    buttonSize:
                    ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
                    buttonOnPressed: () async {
                      context.read<PageUtilsBloc>().closeScreenActive();
                      await context
                          .read<PaymentBloc>()
                          .makeCardPayment(context.read<AuthBloc>().state);
                    }),
            ],
          ),
        ],
      ),
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
