import 'package:flutter/material.dart';

enum DynamicListDirection { column, row }

class DynamicList extends StatelessWidget {
  final DynamicListDirection direction;
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  const DynamicList({super.key,this.mainAxisSize = MainAxisSize.max,this.mainAxisAlignment = MainAxisAlignment.start,this.crossAxisAlignment = CrossAxisAlignment.center, required this.direction,required this.children});

  @override
  Widget build(BuildContext context) {
    if(direction == DynamicListDirection.row){
      return Row(mainAxisSize: mainAxisSize,mainAxisAlignment: mainAxisAlignment,crossAxisAlignment:crossAxisAlignment, children: children,);
    }
    return Column(mainAxisSize: mainAxisSize,mainAxisAlignment: mainAxisAlignment,crossAxisAlignment:crossAxisAlignment, children: children,);
  }
}
