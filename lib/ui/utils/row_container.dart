import 'package:flutter/material.dart';

class RowContainer extends StatelessWidget {
  final double gap;
  final List<Widget> children;
  final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisAlignment? mainAxisAlignment;
  final MainAxisSize? mainAxisSize;
  const RowContainer({super.key,
  required this.gap,
  this.mainAxisAlignment,
  this.mainAxisSize,
  this.crossAxisAlignment,
  required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: mainAxisSize ?? MainAxisSize.max,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      children: _buildRow(children, gap),
    );
  }

  _buildRow(List<Widget> children,double gap){
    List<Widget> list=[];
    for(int i = 0; i<children.length-1;i++){
      list.add(children[i]);
      list.add(SizedBox(width: gap,));
    }
    if(children.isNotEmpty) {
      list.add(children.last);
    }
    return list;
  }
}
