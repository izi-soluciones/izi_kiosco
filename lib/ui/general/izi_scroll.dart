import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';

class IziScroll extends StatelessWidget {
  final Widget child;
  final ScrollController? scrollController;
  const IziScroll({super.key,required this.child,this.scrollController});

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
        controller: scrollController ?? ScrollController(),
        thickness: 5,
        thumbVisibility: true,
        radius: const Radius.circular(10),
    trackColor: IziColors.white,
    thumbColor: IziColors.grey35,
    child: child);
  }
}
