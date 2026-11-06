import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order_retail/make_order_retail_bloc.dart';
import 'package:izi_kiosco/domain/models/campos_extra.dart';
import 'package:izi_kiosco/ui/general/headers/back_modal_header.dart';

class OrderCamposExtraModal extends StatefulWidget {
  final bool isRetailScan;
  const OrderCamposExtraModal({super.key, this.isRetailScan = false});

  @override
  State<OrderCamposExtraModal> createState() => _OrderCamposExtraModalState();
}

class _OrderCamposExtraModalState extends State<OrderCamposExtraModal> {
  final Map<int, TextEditingController> _controllers = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final campos = widget.isRetailScan
        ? context.read<MakeOrderRetailBloc>().state.camposExtra
        : context.read<MakeOrderBloc>().state.camposExtra;
    for (var c in campos) {
      if (c.tipoCampo != 'select') {
        _controllers[c.id] = TextEditingController(text: c.valor ?? "");
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRetailScan) {
      return BlocBuilder<MakeOrderRetailBloc, MakeOrderRetailState>(
        builder: (context, state) {
          return _buildContent(context, state.camposExtra);
        },
      );
    }
    return BlocBuilder<MakeOrderBloc, MakeOrderState>(
      builder: (context, state) {
        return _buildContent(context, state.camposExtra);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<CamposExtra> camposExtra) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BackModalHeader(
          title: widget.isRetailScan ? "Información adicional" : "Información del pedido",
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 450),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.iziColors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.iziColors.red),
                      ),
                      child: IziText.body(
                        color: context.iziColors.red,
                        text: _errorMessage!,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...camposExtra.map((c) => _buildField(context, c)),
                  const SizedBox(height: 24),
                  IziBtn(
                    buttonText: LocaleKeys.tables_buttons_continue.tr(),
                    buttonType: ButtonType.primary,
                    buttonSize: ButtonSize.medium,
                    buttonOnPressed: () {
                      final error = widget.isRetailScan
                          ? context.read<MakeOrderRetailBloc>().validateCamposExtra()
                          : context.read<MakeOrderBloc>().validateCamposExtra();
                      if (error != null) {
                        setState(() {
                          _errorMessage = error;
                        });
                      } else {
                        Navigator.of(context).pop(true);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(BuildContext context, CamposExtra c) {
    final label = "${c.nombre}${c.isObligatorio ? ' *' : ' (opcional)'}";

    if (c.tipoCampo == 'select') {
      final options = c.values ?? [];
      final Map<String, String> selectOpts = {
        for (var opt in options) opt: opt,
      };

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: IziInput(
          labelInput: label,
          inputHintText: "Seleccione una opción",
          inputType: InputType.select,
          value: c.valor,
          selectOptions: selectOpts,
          onSelected: (val) {
            setState(() {
              _errorMessage = null;
            });
            if (widget.isRetailScan) {
              context.read<MakeOrderRetailBloc>().updateCampoExtra(c.id, val?.toString());
            } else {
              context.read<MakeOrderBloc>().updateCampoExtra(c.id, val?.toString());
            }
          },
        ),
      );
    }

    if (c.tipoCampo == 'fijo') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: IziInput(
          labelInput: label,
          inputHintText: "",
          inputType: InputType.normal,
          value: c.valor ?? "",
          readOnly: true,
        ),
      );
    }

    final controller = _controllers.putIfAbsent(
      c.id,
      () => TextEditingController(text: c.valor ?? ""),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: IziInput(
        labelInput: label,
        inputHintText: "Ingrese ${c.nombre.toLowerCase()}",
        inputType:
            c.tipoCampo == 'number' ? InputType.number : InputType.normal,
        controller: controller,
        onChanged: (val, raw) {
          setState(() {
            _errorMessage = null;
          });
          if (widget.isRetailScan) {
            context.read<MakeOrderRetailBloc>().updateCampoExtra(c.id, val);
          } else {
            context.read<MakeOrderBloc>().updateCampoExtra(c.id, val);
          }
        },
      ),
    );
  }
}
