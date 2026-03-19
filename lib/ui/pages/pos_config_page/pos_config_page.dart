import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/pos_config/pos_config_bloc.dart';

class PosConfigPage extends StatelessWidget {
  const PosConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PosConfigBloc(context.read<AuthBloc>())..beginDiscovery(),
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
            onPressed: () => GoRouter.of(context).pop(),
          ),
        ),
        body: BlocConsumer<PosConfigBloc, PosConfigState>(
          listener: (context, state) {
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
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IziText.titleMedium(
                        color: context.iziColors.dark,
                        text: "Terminales Disponibles",
                      ),
                      IziBtn(
                        buttonSize: ButtonSize.medium,
                        buttonType: ButtonType.secondary,
                        buttonText: state.status == PosConfigStatus.discovering
                            ? "Buscando..."
                            : "Buscar Terminales",
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
                  const SizedBox(height: 24),
                  if (state.pairedDevice != null) ...[
                    IziText.titleSmall(
                      color: context.iziColors.dark,
                      text: "Terminal Emparejado",
                    ),
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
                        subtitle: Row(
                          children: [
                            IziText.body(
                              color: context.iziColors.darkGrey,
                              fontWeight: FontWeight.normal,
                              text:
                                  "${state.pairedDevice!.ip}:${state.pairedDevice!.port}",
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: state.isHealthy
                                  ? context.iziColors.blue
                                  : context.iziColors.red,
                            ),
                          ],
                        ),
                        trailing: IziBtn(
                          buttonSize: ButtonSize.small,
                          buttonType: ButtonType.secondary,
                          buttonText: "Desvincular",
                          buttonOnPressed: () {
                            context.read<PosConfigBloc>().unpair();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  if (state.discoveredDevices.isEmpty &&
                      state.status == PosConfigStatus.discovering)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (state.discoveredDevices.isEmpty &&
                      state.status != PosConfigStatus.discovering)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: IziText.body(
                          color: context.iziColors.darkGrey,
                          fontWeight: FontWeight.normal,
                          text: "No se encontraron terminales",
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final device = state.discoveredDevices[index];
                        final isPaired = state.pairedDevice?.ip == device.ip;
                        if (isPaired) {
                          return const SizedBox.shrink();
                        }

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
                            trailing:
                                state.status == PosConfigStatus.pairing &&
                                    state.pairedDevice?.ip == device.ip
                                ? const CircularProgressIndicator()
                                : IziBtn(
                                    buttonSize: ButtonSize.small,
                                    buttonType: ButtonType.primary,
                                    buttonText: "Vincular",
                                    buttonOnPressed: () {
                                      context.read<PosConfigBloc>().pairDevice(
                                        device,
                                      );
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
