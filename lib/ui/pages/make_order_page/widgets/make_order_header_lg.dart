import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

class MakeOrderHeaderLg extends StatelessWidget {
  final VoidCallback? onPop;
  final Widget? icon;
  const MakeOrderHeaderLg({super.key,this.onPop,this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          if(onPop!=null)
          Positioned(
            left: 0,
            child: InkWell(
              onTap: onPop,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Icon(IziIcons.leftB, color: IziColors.grey, size: 50),
              ),
            ),
          ),

          Positioned(
            right: 0,
            left: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                context.read<AuthBloc>().state.currentContribuyente?.logo != null
                    ? SizedBox(
                    height: 100,
                    child: icon ?? CachedNetworkImage(
                      imageUrl:
                      "${dotenv.env[EnvKeys.apiUrl]}/contribuyentes/${context.read<AuthBloc>().state.currentContribuyente?.id}/logo",
                      fit: BoxFit.fitHeight,
                      placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: IziColors.dark)),
                      errorWidget: (context, url, error) {
                        return const SizedBox.shrink();
                      },
                    ))
                    : const SizedBox.shrink(),
              ],
            ),
          )
        ],
      ),
    );
  }
}
