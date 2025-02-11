import 'dart:async';
import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/general/custom_icons/kiosk_hand_icon.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? timer;
  bool errorPressed = false;
  VideoPlayerController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  @override
  void initState() {
    _initVideo();
    super.initState();
  }

  var showVideo = false;

  _initVideo({BuildContext? context}){
    try{

      if(_controller!=null){
        _controller?.pause();
        _controller?.dispose();
      }
      var authState = (context ?? this.context).read<AuthBloc>().state;
      Future.delayed(const Duration(seconds: 30)).then((value) {
        if(!mounted){
          return;
        }


        if (authState.currentDevice?.config.video !=null) {
          _controller = VideoPlayerController.networkUrl(
              Uri.parse(authState.currentDevice?.config.video??""))
            ..setLooping(true)
            ..initialize().then((_) {
              setState(() {
                showVideo = true;
              });
            })..play();
        } else if (authState.video != null) {
          _controller = VideoPlayerController.file(authState.video!)
            ..setLooping(true)
            ..initialize().then((_) {
              setState(() {
                showVideo = true;
              });
            })..play();
        }
      });
    }
    catch(e){
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      return LayoutBuilder(
        builder: (context,layout) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    GoRouter.of(context).goNamed(RoutesKeys.makeOrder);
                    context.read<PageUtilsBloc>().initScreenActive();
                  },
                  child: Image.asset(AssetsKeys.homeGraphic,fit: BoxFit.cover),
                ),
              ),
              if (showVideo && _controller!=null && _controller?.value.isInitialized==true)
                Positioned.fill(
                  child: Listener(
                    onPointerDown: (val){
                      setState(() {
                        showVideo=false;
                        _initVideo(context: context);
                        GoRouter.of(context).goNamed(RoutesKeys.makeOrder);
                        context.read<PageUtilsBloc>().initScreenActive();
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: FittedBox(
                            alignment: Alignment.center,
                            fit: BoxFit.cover,
                            child: SizedBox(
                                height: _controller?.value.size.height,
                                width: _controller?.value.size.width,
                                child:  VideoPlayer(_controller!)
                            ),
                          ),
                        ),
                        Container(
                          color: IziColors.white,
                          padding: const EdgeInsets.all(32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: Image.asset(
                                  AssetsKeys.texasLogoColor,
                                  fit: BoxFit.fitWidth,
                                )
                              ),
                              const SizedBox(width: 32,),
                              Expanded(
                                child: IziText.titleBig(
                                    color: IziColors.primaryDarken,
                                    text: LocaleKeys.home_body_clickToInit.tr(),
                                    fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(width: 16,),
                              const KioskHandIcon(width: 70),

                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )
            ],
          );
        }
      );
    });
  }

}
