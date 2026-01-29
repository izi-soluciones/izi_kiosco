import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

class MakeOrderCategory extends StatelessWidget {
  final String title;
  final int count;
  final bool active;
  final VoidCallback onPressed;
  final bool small;
  final IconData icon;
  final bool isHorizontal;
  const MakeOrderCategory({super.key,this.isHorizontal=false,this.small=false,required this.onPressed,required this.title,required this.count,required this.active,required this.icon});

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.read<AuthBloc>().state;
    final bgColor = authState.currentDevice?.config.kioskColors.categoryBgColor ?? context.iziColors.dark;
    final textColor = authState.currentDevice?.config.kioskColors.categoryTextColor ?? context.iziColors.white;
    return InkWell(
      onTap: onPressed,
      child: Ink(
        padding: isHorizontal?const EdgeInsets.symmetric(horizontal: 16,vertical: 8):const EdgeInsets.fromLTRB(32,10,32,5),
        decoration: BoxDecoration(
          color: active? bgColor:context.iziColors.grey25,
          borderRadius: BorderRadius.circular(8)
        ),
        child: isHorizontal?
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,color: active?textColor:context.iziColors.dark,size: 24,weight: 1),
            const SizedBox(width: 16,),
            IziText.bodyBig(color: active?textColor:context.iziColors.dark,textAlign: TextAlign.center, text: title, fontWeight: FontWeight.w600,maxLines: 3),
          ],
        ):
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,color: active?textColor:context.iziColors.dark,size: 40,weight: 1),
            IziText.body(color: active?textColor:context.iziColors.dark,textAlign: TextAlign.center, text: title, fontWeight: FontWeight.w600,maxLines: 3),
          ],
        ),
      ),
    );
  }

}
