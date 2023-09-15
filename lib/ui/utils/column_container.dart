import 'package:flutter/material.dart';

class ColumnContainer extends StatelessWidget {
  final double gap;
  final List<Widget> children;
  final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisAlignment? mainAxisAlignment;
  final MainAxisSize? mainAxisSize;
  const ColumnContainer({super.key,
  required this.gap,
  this.mainAxisAlignment,
  this.mainAxisSize,
  this.crossAxisAlignment,
  required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize ?? MainAxisSize.max,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      children: _buildContainer(children, gap),
    );
  }

  _buildContainer(List<Widget> children,double gap){
    List<Widget> list=[];
    for(int i = 0; i<children.length-1;i++){
      list.add(children[i]);
      list.add(SizedBox(height: gap,));
    }
    if(children.isNotEmpty) {
      list.add(children.last);
    }
    return list;
  }
}
