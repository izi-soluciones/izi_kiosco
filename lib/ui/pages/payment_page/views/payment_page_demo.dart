import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';

class PaymentPageDemo extends StatefulWidget {
  final PaymentState state;
  const PaymentPageDemo({super.key, required this.state});

  @override
  State<PaymentPageDemo> createState() => _PaymentPageDemoState();
}

class _PaymentPageDemoState extends State<PaymentPageDemo> {
  bool _loading = false;
  int _remaining = AppConstants.remainingQrTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining <= 0) {
          _remaining = AppConstants.remainingQrTime;
        } else {
          _remaining--;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _amountText => (widget.state.paymentObj?.amount ?? 0).moneyFormat(
        currency: widget.state.currentCurrency?.simbolo ?? "\$",
        digitsTaxes: 2,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const IziHeaderKiosk(onPop: null, hideLogo: true),
        Expanded(child: _body(context)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IziBtn(
                buttonText: LocaleKeys.payment_buttons_proceedPayment.tr(),
                buttonType: ButtonType.primary,
                buttonSize: ButtonSize.large,
                loading: _loading,
                buttonOnPressed: () {
                  setState(() => _loading = true);
                  context.read<PaymentBloc>().confirmDemoPayment();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    switch (widget.state.paymentType) {
      case PaymentType.qr:
        return _qrView(context);
      case PaymentType.card:
        return _cardView(context);
      case PaymentType.breb:
        return _brebView(context);
      default:
        return _defaultView(context);
    }
  }

  // ─── QR dummy view ────────────────────────────────────────────────────────────

  Widget _qrView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IziText.titleMedium(
                color: context.iziColors.dark,
                text: LocaleKeys.payment_titles_qrPayment.tr(),
              ),
              const SizedBox(height: 8),
              IziText.titleSmall(
                textAlign: TextAlign.center,
                color: context.iziColors.dark,
                text: LocaleKeys.payment_subtitles_scanQRtoPay.tr(),
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      AssetsKeys.qrDemoPng,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IziText.body(
                    color: context.iziColors.darkGrey,
                    text: "Tiempo Restante: ",
                    fontWeight: FontWeight.w400,
                  ),
                  IziText.body(
                    color: context.iziColors.primary,
                    text: "${_remaining}s",
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              IziText.titleMedium(
                color: context.iziColors.darkGrey,
                text: "${LocaleKeys.payment_body_total.tr()}: $_amountText",
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Card dummy view ──────────────────────────────────────────────────────────

  Widget _cardView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IziText.titleSmall(
          textAlign: TextAlign.center,
          color: context.iziColors.dark,
          text: LocaleKeys.payment_subtitles_enterYourCard.tr(),
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 32),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: AspectRatio(
              aspectRatio: 1,
              child: SvgPicture.asset(
                AssetsKeys.cardPOSSvg,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        IziText.titleBig(
          color: context.iziColors.darkGrey,
          textAlign: TextAlign.center,
          text: "${LocaleKeys.payment_body_total.tr()}: $_amountText",
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }

  // ─── Bre-B dummy view ─────────────────────────────────────────────────────────

  Widget _brebView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IziText.titleMedium(
                color: context.iziColors.primaryDarken,
                text: "Paga a través de Bre-B",
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      AssetsKeys.qrDemoPng,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IziText.body(
                    color: context.iziColors.darkGrey,
                    text: "Tiempo Restante: ",
                    fontWeight: FontWeight.w400,
                  ),
                  IziText.body(
                    color: context.iziColors.primary,
                    text: "${_remaining}s",
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IziText.titleMedium(
                    color: context.iziColors.darkGrey,
                    text: "Llave: ",
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(width: 8),
                  IziText.titleMedium(
                    color: context.iziColors.darkGrey85,
                    text: "@iztest123456",
                    fontWeight: FontWeight.w500,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IziText.titleMedium(
                    color: context.iziColors.darkGrey,
                    text: "${LocaleKeys.payment_body_total.tr()}: ",
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(width: 8),
                  IziText.titleMedium(
                    color: context.iziColors.darkGrey85,
                    text: _amountText,
                    fontWeight: FontWeight.w500,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              IziText.body(
                color: context.iziColors.darkGrey,
                text:
                    "(Recuerda ingresar el monto exacto para marcar el cobro como pagado)",
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Default / fallback view ──────────────────────────────────────────────────

  Widget _defaultView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IziText.titleBig(
            text: LocaleKeys.demoPayment_title.tr(),
            color: IziColors.dark,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 48),
          IziText.bodyBig(
            text: LocaleKeys.demoPayment_body.tr(),
            color: IziColors.darkGrey,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.normal,
          ),
        ],
      ),
    );
  }
}
