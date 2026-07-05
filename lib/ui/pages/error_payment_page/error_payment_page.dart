import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';

import 'package:flutter/services.dart';

class ErrorPaymentPage extends StatefulWidget {
  const ErrorPaymentPage({super.key});

  @override
  State<ErrorPaymentPage> createState() => _ErrorPaymentPageState();
}

class _ErrorPaymentPageState extends State<ErrorPaymentPage> {
  List<CardPayment> list = [];
  bool _retrying = false;

  @override
  void initState() {
    _loadList();
    super.initState();
  }

  Future<void> _loadList() async {
    final value = await LocalStorageCardErrors.getErrors();
    final loaded = <CardPayment>[];
    for (var e in value) {
      loaded.add(CardPayment.fromJsonStorage(jsonDecode(e)));
    }
    if (!mounted) return;
    setState(() {
      list = loaded.reversed.toList();
    });
  }

  String _statusLabel(CardPayment cp) {
    switch (cp.retryStatus) {
      case CardPaymentStatus.success:
        return LocaleKeys.errorPayments_status_success.tr();
      case CardPaymentStatus.declined:
        return LocaleKeys.errorPayments_status_declined.tr();
      case CardPaymentStatus.pending:
        return LocaleKeys.errorPayments_status_pending.tr();
      case CardPaymentStatus.unknown:
        return LocaleKeys.errorPayments_status_unknown.tr();
    }
  }

  Color _statusColor(CardPayment cp) {
    switch (cp.retryStatus) {
      case CardPaymentStatus.success:
        return Colors.green;
      case CardPaymentStatus.declined:
        return Colors.red;
      case CardPaymentStatus.pending:
      case CardPaymentStatus.unknown:
        return Colors.orange;
    }
  }

  Future<void> _onRetry(CardPayment cp) async {
    if (_retrying) return;
    // Safety: transactions whose original outcome is unknown (pending/unknown)
    // may already have been charged. Warn the operator before reattempting.
    final needsWarning = cp.retryNeedsWarning;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: IziText.titleMedium(
          color: context.iziColors.dark,
          text: LocaleKeys.errorPayments_retry_confirmTitle.tr(),
        ),
        content: IziText.body(
          color: context.iziColors.dark,
          fontWeight: FontWeight.normal,
          text: needsWarning
              ? LocaleKeys.errorPayments_retry_confirmWarning.tr()
              : LocaleKeys.errorPayments_retry_confirmBody.tr(),
        ),
        actions: [
          IziBtn(
            buttonText: LocaleKeys.errorPayments_retry_cancel.tr(),
            buttonType: ButtonType.terciary,
            buttonSize: ButtonSize.small,
            buttonOnPressed: () => Navigator.of(ctx).pop(false),
          ),
          IziBtn(
            buttonText: LocaleKeys.errorPayments_retry_confirm.tr(),
            buttonType: ButtonType.primary,
            buttonSize: ButtonSize.small,
            buttonOnPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _retrying = true;
    });
    await context
        .read<PaymentBloc>()
        .retryCardPayment(context.read<AuthBloc>().state, cp);
    if (!mounted) return;
    setState(() {
      _retrying = false;
    });
    // Refresh the list so the new attempt's outcome is reflected.
    await _loadList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == PaymentStatus.cardPending) {
          context.read<PageUtilsBloc>().showSnackBar(
                snackBar: SnackBarInfo(
                  text: LocaleKeys.payment_messages_pendingCard.tr(),
                  snackBarType: SnackBarType.warning,
                ),
              );
        } else if (state.status == PaymentStatus.cardError) {
          context.read<PageUtilsBloc>().showSnackBar(
                snackBar: SnackBarInfo(
                  text: LocaleKeys.payment_messages_errorCard.tr(),
                  snackBarType: SnackBarType.error,
                ),
              );
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: IziText.titleSmall(
                                color: context.iziColors.dark,
                                text: "Nº",
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: IziText.titleSmall(
                                color: context.iziColors.dark,
                                text: "Respuesta",
                              ),
                            ),
                            Expanded(
                              child: IziText.titleSmall(
                                color: context.iziColors.dark,
                                text: LocaleKeys.errorPayments_columns_status
                                    .tr(),
                              ),
                            ),
                            Expanded(
                              child: IziText.titleSmall(
                                color: context.iziColors.dark,
                                text: "Fecha",
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: IziText.titleSmall(
                                color: context.iziColors.dark,
                                text: "Tarjeta (U. 4 digitos)",
                              ),
                            ),
                            Expanded(
                              child: IziText.titleSmall(
                                color: context.iziColors.dark,
                                text: LocaleKeys.errorPayments_columns_action
                                    .tr(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ...list.asMap().entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: IziText.titleSmall(
                                    color: context.iziColors.dark,
                                    text: (e.key + 1).toString(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: IziText.titleSmall(
                                    color: context.iziColors.dark,
                                    text: e.value.response,
                                  ),
                                ),
                                Expanded(
                                  child: IziText.titleSmall(
                                    color: _statusColor(e.value),
                                    text: _statusLabel(e.value),
                                  ),
                                ),
                                Expanded(
                                  child: IziText.titleSmall(
                                    color: context.iziColors.dark,
                                    text: "${e.value.date} ${e.value.hour}",
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: IziText.titleSmall(
                                    color: context.iziColors.dark,
                                    text: (e.value.cardNumber?.length ?? 0) > 4
                                        ? e.value.cardNumber!.substring(
                                            e.value.cardNumber!.length - 4,
                                            e.value.cardNumber!.length,
                                          )
                                        : "",
                                  ),
                                ),
                                Expanded(
                                  child: (e.value.canRetry &&
                                          (e.value.amount != null))
                                      ? IziBtn(
                                          buttonText: LocaleKeys
                                              .errorPayments_retry_button
                                              .tr(),
                                          buttonType: ButtonType.primary,
                                          buttonSize: ButtonSize.small,
                                          loading: _retrying,
                                          buttonOnPressed: _retrying
                                              ? null
                                              : () => _onRetry(e.value),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: IziBtn(
                        buttonText: "Cancelar",
                        buttonType: ButtonType.primary,
                        buttonSize: ButtonSize.medium,
                        buttonOnPressed: () {
                          context.read<PageUtilsBloc>().closeScreenActive();
                          GoRouter.of(context).goNamed(LocaleKeys.home);
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: IziBtn(
                        buttonText: "Cerrar Sesión",
                        buttonType: ButtonType.terciary,
                        buttonSize: ButtonSize.medium,
                        buttonOnPressed: () {
                          context.read<PageUtilsBloc>().closeScreenActive();
                          context.read<AuthBloc>().logout();
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: IziBtn(
                        buttonText: "Configuración de POS",
                        buttonType: ButtonType.terciary,
                        buttonSize: ButtonSize.medium,
                        buttonOnPressed: () {
                          GoRouter.of(context).pushNamed("pos_config");
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: IziBtn(
                        buttonText: "Recargar",
                        buttonType: ButtonType.terciary,
                        buttonSize: ButtonSize.medium,
                        buttonOnPressed: () {
                          GoRouter.of(context).goNamed(LocaleKeys.home);
                          context.read<AuthBloc>().verify();
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: IziBtn(
                        buttonText: "Cerrar App",
                        buttonType: ButtonType.terciary,
                        buttonSize: ButtonSize.medium,
                        buttonOnPressed: () {
                          SystemNavigator.pop();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
