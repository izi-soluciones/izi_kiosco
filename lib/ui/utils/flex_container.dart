import 'package:flutter/material.dart';

enum FlexDirection { column, row }

class FlexContainer extends StatelessWidget {
  final FlexDirection flexDirection;
  final double gapH;
  final double gapV;
  final List<Widget> children;
  final WrapCrossAlignment crossAxisAlignment;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final EdgeInsetsGeometry? padding;
  const FlexContainer(
      {super.key,
      required this.flexDirection,
        this.padding,
      this.gapH = 0,
      this.gapV = 0,
        this.crossAxisAlignment = WrapCrossAlignment.start,
        this.alignment = WrapAlignment.start,
        this.runAlignment = WrapAlignment.start,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Wrap(

        direction:
            flexDirection == FlexDirection.row ? Axis.horizontal : Axis.vertical,
        spacing: flexDirection == FlexDirection.row ? gapH : gapV,
        runSpacing: flexDirection == FlexDirection.row ? gapH : gapV,
        crossAxisAlignment: crossAxisAlignment,
        alignment: alignment,
        runAlignment: runAlignment,


        children: children,

      ),
    );
  }
}
