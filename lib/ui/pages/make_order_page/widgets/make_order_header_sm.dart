import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/ui/modals/number_diners_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/make_order_edit_table_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_chip.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class MakeOrderHeaderSm extends StatelessWidget {
  final MakeOrderState state;
  final VoidCallback? onPop;
  const MakeOrderHeaderSm({this.onPop,super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: const Icon(
                      IziIcons.left,
                      size: 25,
                    ),
                    onTap: () {
                      if(onPop!=null){
                        onPop!();
                        return;
                      }
                      GoRouter.of(context).goNamed(RoutesKeys.home);
                    }),
                if (!ru.isXXs())
                  const SizedBox(
                    width: 8,
                  ),
                if (!ru.isXXs())
                  IziText.bodyBig(
                      color: IziColors.dark,
                      text: state.order?.id != null
                          ? LocaleKeys.makeOrder_subtitles_orderNumber
                              .tr(args: [state.order!.numero.toString()])
                          : LocaleKeys.makeOrder_title.tr(),
                      fontWeight: FontWeight.w500)
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MakeOrderChip(
                    icon: IziIcons.restTable,
                    text: _getTableName(),
                    dense: true,
                    onPressed: () {
                      CustomAlerts.defaultAlert(
                          padding: EdgeInsets.zero,
                          dismissible: true,
                          context: context,
                          child: MakeOrderEditTableModal(
                              tables: state.tables,
                              tableSelect: state.tableId))
                          .then((value) {
                        if (value is String) {
                          context.read<MakeOrderBloc>().changeTableId(value);
                        }
                      });
                    }),
                const SizedBox(
                  width: 8,
                ),
                MakeOrderChip(
                    icon: IziIcons.user,
                    text: state.numberDiners != null
                        ? state.numberDiners.toString()
                        : "-",
                    dense: true,
                    onPressed: () {
                      CustomAlerts.defaultAlert(
                          padding: EdgeInsets.zero,
                          dismissible: true,
                          context: context,
                          child: NumberDinersModal(diners: state.numberDiners,))
                          .then((value) {
                        if (value is int) {
                          context.read<MakeOrderBloc>().changeNumberDiners(value);
                        }
                      });
                    }),
              ],
            )
          ],
        ));
  }

  String _getTableName() {
    String name = "-";
    for (var table in state.tables) {
      if (table.id == state.tableId) {
        name = table.nombre;
      }
    }
    return name;
  }
}
