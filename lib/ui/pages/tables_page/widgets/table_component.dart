import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';

class TableComponent extends StatelessWidget {
  final double size;
  final Function(TapUpDetails) onPressed;
  final Function(LongPressEndDetails)? onLongPressed;
  final ConsumptionPoint consumptionPoint;
  const TableComponent(
      {super.key,
        required this.onPressed,
        this.onLongPressed,
      required this.consumptionPoint,
      required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(
                  height: 6,
                  width: size,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (consumptionPoint.capacidad >= 1)
                        SizedBox(width: size * 0.3, child: _chair()),
                      if (consumptionPoint.capacidad >= 3)
                        SizedBox(width: size * 0.3, child: _chair()),
                    ],
                  ),
                ),
                SizedBox(
                  height: size-12,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (consumptionPoint.capacidad >= 5)
                              SizedBox(height: size * 0.3, child: _chair()),
                            if (consumptionPoint.capacidad >= 7)
                              SizedBox(height: size * 0.3, child: _chair()),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: size-12,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: onPressed,
                            onLongPressEnd: onLongPressed,
                            child: _table(size-12),
                          ),
                        )
                      ),
                      SizedBox(
                        width: 6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (consumptionPoint.capacidad >= 6)
                              SizedBox(height: size * 0.3, child: _chair()),
                            if (consumptionPoint.capacidad >= 8)
                              SizedBox(height: size * 0.3, child: _chair()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 6,
                  width: size,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (consumptionPoint.capacidad >= 2)
                        SizedBox(width: size * 0.27, child: _chair()),
                      if (consumptionPoint.capacidad >= 4)
                        SizedBox(width: size * 0.27, child: _chair()),
                    ],
                  ),
                ),
              ],
            ),

          ),
          Positioned(
            top: size*0.15,
            right: 1,
            child: CircleAvatar(
              maxRadius: size*0.11,
              backgroundColor: IziColors.secondary,
              child: Icon(IziIcons.more,color: IziColors.white,size: size*0.18,),
            ),
          )
        ],
      ),
    );
  }

  _table(sizeTable) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getBorderColor()),
            color: _getBackgroundColor()),
        padding: const EdgeInsets.all(7.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: (sizeTable-24)*0.3,
              child: AutoSizeText(
                consumptionPoint.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _getTitleColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 1000),
                maxLines: 1,
                maxFontSize: 100,
                minFontSize: 1,
              ),
            ),
            consumptionPoint.loading?
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: size*0.05),
                    child: SizedBox(
                      width: size*0.2,
                        height: size*0.2,
                        child: CircularProgressIndicator(color: _getTitleColor(),strokeWidth: 2,)
                    ),
                  ),
                ):
            consumptionPoint.status == ConsumptionPointStatus.fill
                ? SizedBox(
              height: (sizeTable-24)*0.6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: (sizeTable-24)*0.4,
                        child: AutoSizeText(
                          "${consumptionPoint.cantidadComensales}/${consumptionPoint.capacidad}",
                          style: TextStyle(
                              color: _getNumberColor(),
                              fontWeight: FontWeight.w500,
                              fontSize: 100,),
                          maxLines: 1,
                          minFontSize: 1,
                          maxFontSize: 100,
                        ),
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      SizedBox(
                        width: (sizeTable-24)*0.2,
                        child: FittedBox(
                          child: Icon(IziIcons.user,
                              color: _getNumberColor()),
                        ),
                      )
                    ],
                  ),
                )
                : Container(
                    decoration: BoxDecoration(
                        color: _getNumberBackColor(),
                        shape: BoxShape.circle),
                    height: (sizeTable-24)*0.6,
                    padding: EdgeInsets.all((sizeTable-24)*0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 4,
                        ),
                        AutoSizeText(
                          consumptionPoint.capacidad.toString(),
                          style: TextStyle(
                          color: _getNumberColor(),
                          fontWeight: FontWeight.w500,
                          fontSize: 100),
                          maxLines: 1,
                          minFontSize: 1,
                          maxFontSize: 100,
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        SizedBox(
                          width: (sizeTable-24)*0.2,
                          child: FittedBox(
                            child: Icon(IziIcons.user,
                                color: _getNumberColor()),
                          ),
                        )
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  _chair() {
    return Container(
      decoration: BoxDecoration(
          color: IziColors.grey35, borderRadius: BorderRadius.circular(10)),
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

  Color? _getNumberBackColor() {
    switch (consumptionPoint.status) {
      case ConsumptionPointStatus.available:
        return IziColors.grey25;
      case ConsumptionPointStatus.fill:
        return IziColors.dark;
      default:
        return null;
    }
  }
}
