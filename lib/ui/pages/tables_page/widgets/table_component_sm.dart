import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';

class TableComponentSm extends StatelessWidget {
  final Function(TapUpDetails) onPressed;
  final Function(LongPressEndDetails)? onLongPressed;
  final ConsumptionPoint consumptionPoint;
  const TableComponentSm({super.key,required this.consumptionPoint,required this.onLongPressed,required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onPressed,
        onLongPressEnd: onLongPressed,
        child: Stack(
          children: [
            Positioned(
              right: 20,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _getBorderColor()),
                    color: _getBackgroundColor()),
                child: Stack(
                  children: [
                    IziText.title(color: _getTitleColor(), text:consumptionPoint.nombre,mobile: true),
                    Row(

                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if(consumptionPoint.loading)
                          Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: _getTitleColor(),strokeWidth: 2,)
                            ),
                          ),

                        if(!consumptionPoint.loading)
                        Icon(IziIcons.user,
                          color: _getNumberColor(),size: 18,),

                        if(!consumptionPoint.loading)
                        const SizedBox(width: 4,),

                        if(!consumptionPoint.loading)
                        IziText.bodyBig(color: _getNumberColor(), text:"${consumptionPoint.status==ConsumptionPointStatus.fill?"${consumptionPoint.cantidadComensales}/":""}${consumptionPoint.capacidad}",fontWeight: FontWeight.w500),

                        const SizedBox(width: 20,)
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 0,
              child: Padding(
                padding: EdgeInsets.only(top: 6.0),
                child: CircleAvatar(
                  maxRadius: 20,
                  backgroundColor: IziColors.secondary,
                  child: Icon(IziIcons.more,color: IziColors.white,size: 35,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Color _getBackgroundColor() {
    switch (consumptionPoint.status) {
      case ConsumptionPointStatus.available:
        return IziColors.lightGrey;
      case ConsumptionPointStatus.fill:
        return IziColors.dark;
    }
  }

  Color _getBorderColor() {
    switch (consumptionPoint.status) {
      case ConsumptionPointStatus.available:
        return IziColors.secondary;
      case ConsumptionPointStatus.fill:
        return IziColors.dark;
    }
  }

  Color _getTitleColor() {
    switch (consumptionPoint.status) {
      case ConsumptionPointStatus.available:
        return IziColors.dark;
      case ConsumptionPointStatus.fill:
        return IziColors.white;
    }
  }

  Color _getNumberColor() {
    switch (consumptionPoint.status) {
      case ConsumptionPointStatus.available:
        return IziColors.darkGrey;
      case ConsumptionPointStatus.fill:
        return IziColors.white;
    }
  }

}
