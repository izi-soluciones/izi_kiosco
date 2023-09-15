import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';

class ListBuilderConstructor extends StatelessWidget {
  final ScrollController controller;
  final Widget Function(BuildContext, int) itemBuilder;
  final int count;
  final double gap;
  final VoidCallback? onRefresh;
  final EdgeInsetsGeometry padding;
  const ListBuilderConstructor(
      {Key? key,
      required this.controller,
        this.gap=0,
      required this.itemBuilder,
      required this.count,
      this.onRefresh,
      required this.padding
      })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size=MediaQuery.of(context).size;
    return RefreshIndicator(
      onRefresh: ()async{
        await Future.delayed(const Duration(milliseconds: 100));
        onRefresh!=null?onRefresh!():null;
      },
      notificationPredicate: onRefresh==null?(_)=>false:(_)=>true,

      color: IziColors.darkGrey,
      child: Scrollbar(
        controller: controller,
        thickness: 5,
        radius: const Radius.circular(10),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
              controller: controller,
              cacheExtent: size.height,
              itemBuilder: itemBuilder,
              padding: padding,
              itemCount: count,
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: gap);
              },
          ),
      ),
    );
  }
}
