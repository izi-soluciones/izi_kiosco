import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/pos_config/pos_config_bloc.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

class PosConfigPage extends StatefulWidget {
  const PosConfigPage({super.key});

  @override
  State<PosConfigPage> createState() => _PosConfigPageState();
}

class _PosConfigPageState extends State<PosConfigPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _mqttClientIdController = TextEditingController();
  final TextEditingController _mqttUserNameController = TextEditingController();
  final TextEditingController _mqttPasswordController = TextEditingController();
  final TextEditingController _commerceIdController = TextEditingController();
  final TextEditingController _cajaIdController = TextEditingController();
  
  bool _showEcoPayParams = false;

  @override
  void initState() {
    super.initState();
    final config = context.read<AuthBloc>().state.currentDevice?.config;
    if (config != null) {
      _mqttClientIdController.text = config.mqttClientId ?? '';
      _mqttUserNameController.text = config.mqttUserName ?? '';
      _mqttPasswordController.text = config.mqttPassword ?? '';
      _commerceIdController.text = config.commerceId ?? '';
      _cajaIdController.text = config.cajaId ?? '';
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _mqttClientIdController.dispose();
    _mqttUserNameController.dispose();
    _mqttPasswordController.dispose();
    _commerceIdController.dispose();
    _cajaIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          FocusScope.of(context).unfocus();
          Future.delayed(const Duration(milliseconds: 50), () {
            if (context.mounted) {
              GoRouter.of(context).pop();
            }
          });
        },
        child: Scaffold(
          backgroundColor: context.iziColors.lightGrey30,
          appBar: AppBar(
            title: IziText.titleMedium(
              color: context.iziColors.dark,
              text: "Configuración de POS Izify",
            ),
            backgroundColor: context.iziColors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.iziColors.dark),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (context.mounted) {
                    GoRouter.of(context).pop();
                  }
                });
              },
            ),
          ),
        body: BlocConsumer<PosConfigBloc, PosConfigState>(
          listener: (context, state) {
            if (!context.mounted) return;
            if (state.status == PosConfigStatus.error &&
                state.errorMessage != null) {
              context.read<PageUtilsBloc>().showSnackBar(
                snackBar: SnackBarInfo(
                  text: state.errorMessage!,
                  snackBarType: SnackBarType.error,
                ),
              );
            }
            if (state.status == PosConfigStatus.paired) {
              context.read<PageUtilsBloc>().showSnackBar(
                snackBar: SnackBarInfo(
                  text: "POS Emparejado correctamente",
                  snackBarType: SnackBarType.success,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Paired Device Section ---
                  if (state.pairedDevice != null) ...[
                    IziText.titleSmall(
                      color: context.iziColors.dark,
                      text: "Terminal Emparejado",
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.point_of_sale,
                          color: context.iziColors.primary,
                        ),
                        title: IziText.body(
                          color: context.iziColors.dark,
                          fontWeight: FontWeight.w600,
                          text: state.pairedDevice!.name,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IziText.body(
                                  color: context.iziColors.darkGrey,
                                  fontWeight: FontWeight.normal,
                                  text: state.pairedDevice!.ip,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: state.isHealthy == true
                                      ? context.iziColors.blue
                                      : context.iziColors.red,
                                ),
                              ],
                            ),
                            if (state.healthData != null) ...[
                              const SizedBox(height: 8),
                              IziText.body(
                                color: context.iziColors.darkGrey,
                                fontWeight: FontWeight.normal,
                                maxLines: 5,
                                text: state.healthData!.entries.map((e) => '${e.key}: ${e.value}').join(' | '),
                              ),
                            ]
                          ],
                        ),
                        trailing: SizedBox(
                          width: 120,
                          child: IziBtn(
                            buttonSize: ButtonSize.small,
                            buttonType: ButtonType.secondary,
                            buttonText: "Desvincular",
                            buttonOnPressed: () {
                              context.read<PosConfigBloc>().unpair();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (state.pairedDevice == null) ...[
                    // --- Manual Pairing Section ---
                    IziText.titleSmall(
                      color: context.iziColors.dark,
                      text: "Conexión Manual",
                    ),
                    const SizedBox(height: 12),
                    Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ipController,
                          decoration: InputDecoration(
                            hintText: "Ej: 192.168.1.100",
                            labelText: "IP del POS",
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: context.iziColors.white,
                          ),
                          keyboardType: TextInputType.number,
                          onSubmitted: (_) {
                            if (state.status != PosConfigStatus.pairing) {
                              FocusScope.of(context).unfocus();
                              context
                                  .read<PosConfigBloc>()
                                  .pairManually(
                                    _ipController.text,
                                    mqttClientId: _mqttClientIdController.text,
                                    mqttUserName: _mqttUserNameController.text,
                                    mqttPassword: _mqttPasswordController.text,
                                    commerceId: _commerceIdController.text,
                                    cajaId: _cajaIdController.text,
                                  );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      state.status == PosConfigStatus.pairing
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(),
                            )
                          : IziBtn(
                              buttonSize: ButtonSize.medium,
                              buttonType: ButtonType.primary,
                              buttonText: "Conectar",
                              buttonOnPressed: () {
                                FocusScope.of(context).unfocus();
                                context
                                    .read<PosConfigBloc>()
                                    .pairManually(
                                      _ipController.text,
                                      mqttClientId: _mqttClientIdController.text,
                                      mqttUserName: _mqttUserNameController.text,
                                      mqttPassword: _mqttPasswordController.text,
                                      commerceId: _commerceIdController.text,
                                      cajaId: _cajaIdController.text,
                                    );
                              },
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showEcoPayParams = !_showEcoPayParams;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showEcoPayParams ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: context.iziColors.primary,
                          ),
                          const SizedBox(width: 8),
                          IziText.body(
                            color: context.iziColors.primary,
                            fontWeight: FontWeight.w600,
                            text: "Parámetros Avanzados EcoPay",
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showEcoPayParams) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _mqttClientIdController,
                      decoration: InputDecoration(
                        labelText: "mqttClientId (Ej: CAJA1000023)",
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: context.iziColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mqttUserNameController,
                      decoration: InputDecoration(
                        labelText: "mqttUserName (Ej: 1000023)",
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: context.iziColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mqttPasswordController,
                      decoration: InputDecoration(
                        labelText: "mqttPassword (Ej: PWD023)",
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: context.iziColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commerceIdController,
                      decoration: InputDecoration(
                        labelText: "commerceId (Ej: 22000001)",
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: context.iziColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cajaIdController,
                      decoration: InputDecoration(
                        labelText: "cajaId (Ej: 1)",
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: context.iziColors.white,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // --- Discovery Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IziText.titleSmall(
                        color: context.iziColors.dark,
                        text: "Descubrimiento Automático",
                      ),
                      IziBtn(
                        buttonSize: ButtonSize.small,
                        buttonType: ButtonType.secondary,
                        buttonText:
                            state.status == PosConfigStatus.discovering
                                ? "Buscando..."
                                : "Buscar",
                        buttonOnPressed: () {
                          if (state.status == PosConfigStatus.discovering) {
                            context.read<PosConfigBloc>().endDiscovery();
                          } else {
                            context.read<PosConfigBloc>().beginDiscovery();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.discoveredDevices.isEmpty &&
                      state.status == PosConfigStatus.discovering)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (state.discoveredDevices.isEmpty &&
                      state.status != PosConfigStatus.discovering)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: IziText.body(
                          color: context.iziColors.darkGrey,
                          fontWeight: FontWeight.normal,
                          text: "No se encontraron terminales",
                        ),
                      ),
                    ),
                  ...state.discoveredDevices.map((device) {
                    final isPaired = state.pairedDevice?.ip == device.ip;
                    if (isPaired) return const SizedBox.shrink();

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.point_of_sale,
                          color: context.iziColors.darkGrey,
                        ),
                        title: IziText.body(
                          color: context.iziColors.dark,
                          fontWeight: FontWeight.w600,
                          text: device.name,
                        ),
                        subtitle: IziText.body(
                          color: context.iziColors.darkGrey,
                          fontWeight: FontWeight.normal,
                          text: "${device.ip}:${device.port}",
                        ),
                        trailing: IziBtn(
                          buttonSize: ButtonSize.small,
                          buttonType: ButtonType.primary,
                          buttonText: "Vincular",
                          buttonOnPressed: () {
                            context.read<PosConfigBloc>().pairDevice(device);
                          },
                        ),
                      ),
                    );
                  }),
                  ]
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


