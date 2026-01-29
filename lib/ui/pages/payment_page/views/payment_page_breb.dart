import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';

class PaymentPageBREB extends StatefulWidget {
  final PaymentState state;
  const PaymentPageBREB({super.key, required this.state});

  @override
  State<PaymentPageBREB> createState() => _PaymentPageBREBState();
}

class _PaymentPageBREBState extends State<PaymentPageBREB> {
  late AuthState authState;
  int remaining = 0;
  bool showWaitMessage = false;
  Timer? timerRemaining;
  Timer? timerWait;

  void _initTimeRemaining() {
    setState(() {
      remaining = AppConstants.remainingQrTime;
    });
    timerRemaining?.cancel();
    timerRemaining = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (remaining <= 0) {
        _initTimeRemaining();
      } else {
        setState(() {
          remaining--;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    authState = context.read<AuthBloc>().state;
    _initTimeRemaining();
    timerWait = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          showWaitMessage = true;
        });
      }
    });
  }

  @override
  void dispose() {
    timerRemaining?.cancel();
    timerWait?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charge = widget.state.brebCharge;
    final hasKey = (charge?.cobroKeyValue ?? '').isNotEmpty;

    final amountText = (widget.state.paymentObj?.amount ?? 0).moneyFormat(
      currency: widget.state.currentCurrency?.simbolo,
      digitsTaxes: authState.taxesStrategy.decimals,
    );

    final isLoading = widget.state.brebLoading || !hasKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IziHeaderKiosk(
          onPop: () => context.read<PaymentBloc>().cancelBREB(authState),
          hideLogo: true,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: isLoading
                    ? const SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          IziText.titleMedium(
                            color: context.iziColors.primaryDarken,
                            text: "Paga a través de Bre-B",
                          ),
                          const SizedBox(height: 24),

                          // Ícono de breb forzado
                          Align(
                            alignment: Alignment.center,
                            child: Icon(
                              IziIcons.cash,
                              color: context.iziColors.primary,
                              size: 150,
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
                                text: "${remaining}s",
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
                              const SizedBox(height: 8),
                              IziText.titleMedium(
                                color: context.iziColors.darkGrey85,
                                text: charge?.cobroKeyValue ?? "",
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
                                text: LocaleKeys.payment_body_total.tr() + ": ",
                                fontWeight: FontWeight.w700,
                              ),
                              const SizedBox(height: 8),
                              IziText.titleMedium(
                                color: context.iziColors.darkGrey85,
                                text: amountText,
                                fontWeight: FontWeight.w500,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          IziText.body(
                            color: context.iziColors.darkGrey,
                            text:
                                "(Recuerda ingresar el monto exacto para marcar el cobro como pagado)",
                            fontWeight: FontWeight.w400,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 50),

                          if (showWaitMessage)
                            Padding(
                              padding: const EdgeInsets.only(top: 32.0),
                              child: IziText.titleSmall(
                                maxLines: 5,
                                textAlign: TextAlign.center,
                                color: context.iziColors.secondaryDarken,
                                text:
                                    "Si ya hiciste el pago, espera unos segundos a que recibamos la confirmación",
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
