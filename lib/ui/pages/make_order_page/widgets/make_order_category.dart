import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';

class MakeOrderCategory extends StatelessWidget {
  final String title;
  final int count;
  final bool active;
  final VoidCallback onPressed;
  final bool small;
  final IconData? icon;
  final String? image;
  const MakeOrderCategory({super.key,this.image,this.small=false,required this.onPressed,required this.title,required this.count,required this.active,required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Ink(
        width: 150,
        height: 150,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: active? IziColors.secondary:IziColors.primary,
          borderRadius: BorderRadius.circular(8)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon!=null?Icon(icon,color: IziColors.white,size: 40,weight: 1):
            Expanded(child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                color: IziColors.white,
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: image!=null?CachedNetworkImage(
                imageUrl: image!,
                fit: BoxFit.fitHeight,
                placeholder: (context, url) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2,color: IziColors.dark));
                },
                errorWidget: (context, url, error)  {
                  return Image.asset(AssetsKeys.texasGraphic,fit: BoxFit.cover,);
                },
              ):
              Image.asset(AssetsKeys.texasGraphic,fit: BoxFit.fitHeight,),
            )),
            SizedBox(height: icon==null?4:8,),
            IziText.body(color: IziColors.white,textAlign: TextAlign.center, text: title, fontWeight: FontWeight.w600,maxLines: 3),
          ],
        ),
      ),
    );
  }

}
