import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class IziHeaderKiosk extends StatelessWidget {
  final VoidCallback? onPop;
  final bool hideLogo;
  final bool smallLogo;
  const IziHeaderKiosk({super.key,this.onPop,this.hideLogo=false,this.smallLogo=false});

  @override
  Widget build(BuildContext context) {
    final ru= ResponsiveUtils(context);
    return Container(
      color: ru.isXs()?Colors.white:null,
      height: ru.isXs()?50:(smallLogo?70:140),
      child: Stack(
        children: [
          if(onPop!=null)
          Positioned(
            left: 0,
            child: InkWell(
              onTap: onPop,
              child:  Padding(
                padding: EdgeInsets.all(ru.isXs()?10:20),
                child: Icon(IziIcons.leftB, color: IziColors.grey, size: ru.isXs()?30:50),
              ),
            ),
          ),
          if(!hideLogo)
          Positioned(
            right: 0,
            left: 0,
            bottom: ru.isXs()?10:0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                context.read<AuthBloc>().state.currentContribuyente?.logo != null
                    ? SizedBox(
                    height: ru.isXs()?25:(smallLogo?50:100),
                    child: CachedNetworkImage(
                      imageUrl:
                      "${dotenv.env[EnvKeys.apiUrl]}/contribuyentes/${context.read<AuthBloc>().state.currentContribuyente?.id}/logo",
                      fit: BoxFit.fitHeight,
                      placeholder: (context, url) => const Center(
                          child: SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: IziColors.dark),
                          )),
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
