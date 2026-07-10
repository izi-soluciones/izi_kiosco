import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

import 'package:flutter/services.dart';

class ErrorPaymentPage extends StatefulWidget {
  const ErrorPaymentPage({super.key});

  @override
  State<ErrorPaymentPage> createState() => _ErrorPaymentPageState();
}

class _ErrorPaymentPageState extends State<ErrorPaymentPage> {
  List<CardPayment> list = [];
  bool _printingTest = false;
  @override
  void initState() {
    LocalStorageCardErrors.getErrors().then((value) {
      for (var e in value) {
        list.add(CardPayment.fromJsonStorage(jsonDecode(e)));
      }
      list = list.reversed.toList();
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ResponsiveUtils ru = ResponsiveUtils(context);
    return Stack(
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
                      buttonText: _printingTest
                          ? "Imprimiendo..."
                          : "Imprimir prueba",
                      buttonType: ButtonType.terciary,
                      buttonSize: ButtonSize.medium,
                      buttonOnPressed: _printingTest
                          ? null
                          : () async {
                              setState(() => _printingTest = true);
                              try {
                                await PrintUtils().printTest(
                                    device: context
                                        .read<AuthBloc>()
                                        .state
                                        .currentDevice);
                              } finally {
                                if (mounted) {
                                  setState(() => _printingTest = false);
                                }
                              }
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
    );
  }
}
