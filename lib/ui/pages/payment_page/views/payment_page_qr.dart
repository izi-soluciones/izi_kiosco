import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/web_image.dart';

class PaymentPageQR extends StatefulWidget {
  final PaymentState state;
  const PaymentPageQR({super.key, required this.state});

  @override
  State<PaymentPageQR> createState() => _PaymentPageQRState();
}

class _PaymentPageQRState extends State<PaymentPageQR> {
  int qrRemaining = 0;
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

  @override
  void initState() {
    _initTimeRemaining();
    super.initState();
  }

  @override
  void dispose() {
    timerRemaining?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IziHeaderKiosk(onBack: () {
          context.read<PaymentBloc>().cancelQR();
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      IziText.titleMedium(
                          color: IziColors.dark,
                          text: LocaleKeys.payment_titles_qrPayment.tr()),
                      const SizedBox(
                        height: 32,
                      ),
                      IziText.titleSmall(
                          textAlign: TextAlign.center,
                          color: IziColors.dark,
                          text: LocaleKeys.payment_subtitles_scanQRtoPay.tr(),
                          fontWeight: FontWeight.w500),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16,),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600),
            child: widget.state.qrCharge != null && !widget.state.qrLoading
                ? _qrWidget()
                : widget.state.qrLoading
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 30),
                        child: Center(
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
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
                  IziText.titleMedium(
                      color: IziColors.darkGrey,
                      text:
                          "${LocaleKeys.payment_body_total.tr()}: ${(widget.state.paymentObj?.amount ?? 0).moneyFormat(currency: widget.state.currentCurrency?.simbolo)}",
                      fontWeight: FontWeight.w600),
                  const SizedBox(
                    height: 50,
                  ),
                  if (widget.state.qrWait)
                    Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: IziText.titleSmall(
                          maxLines: 5,
                          textAlign: TextAlign.center,
                          color: IziColors.secondaryDarken,
                          text:
                              "Si ya hiciste el pago, espera unos segundos a que recibamos la confirmación",
                          fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _qrWidget() {
    if (widget.state.qrCharge?.qrUrl != null) {
      return kIsWeb
          ? Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                  aspectRatio: 1,
                  child: WebImage(imageUrl: widget.state.qrCharge!.qrUrl!, )),
            ),
          )
          : Image.network(widget.state.qrCharge!.qrUrl!, fit: BoxFit.contain);
    }
    if (widget.state.qrCharge?.qrBase64 != null) {
      return AspectRatio(
          aspectRatio: 1,
          child: Image.memory(
            const Base64Decoder().convert(widget.state.qrCharge!.qrBase64!),
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ));
    }
    return const SizedBox.shrink();
  }
}
