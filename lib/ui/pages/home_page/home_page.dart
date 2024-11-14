import 'dart:async';
import 'dart:developer';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/general/custom_icons/kiosk_hand_icon.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
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
  _startTimer() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 4), () {
      setState(() {
        errorPressed = true;
      });
    });
  }

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
      Future.delayed(const Duration(seconds: 5)).then((value) {
        if(!mounted){
          return;
        }


        if (kIsWeb && authState.currentDevice?.config.video !=null) {
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
    final ru = ResponsiveUtils(context);
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      return LayoutBuilder(
        builder: (context,layout) {
          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if(context.read<AuthBloc>().state.currentDevice?.config.isRetail==true){

                    GoRouter.of(context).goNamed(RoutesKeys.makeOrderRetail);
                  }
                  else{
                    GoRouter.of(context).goNamed(RoutesKeys.makeOrder);
                  }
                  context.read<PageUtilsBloc>().initScreenActive();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                          onTapDown: (details) {
                            _startTimer();
                          },
                          onTapUp: (details) {
                            timer?.cancel();
                            if (errorPressed) {
                              context.read<PageUtilsBloc>().initScreenActive();
                              GoRouter.of(context)
                                  .pushNamed(RoutesKeys.errorPayments);
                            }
                          },
                          child: IziText.titleBig(
                              color: IziColors.primary,
                              text: LocaleKeys.home_subtitles_iziSlogan.tr(),
                              fontWeight: FontWeight.w400)),
                      const SizedBox(height: 32,),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              flex: 2,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,),
                                child: state.currentContribuyente?.logo != null
                                    ? CachedNetworkImage(
                                        imageUrl:
                                            "${dotenv.env[EnvKeys.apiUrl]}/contribuyentes/${state.currentContribuyente?.id}/logo",
                                        fit: BoxFit.fitHeight,
                                        placeholder: (context, url) =>
                                            const Center(
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: IziColors.dark)),
                                        errorWidget: (context, url, error) {
                                          return const SizedBox.shrink();
                                        },
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            Expanded(
                              flex: 8,
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 30, right: 30, left: 30),
                                  child:SvgPicture.asset(
                                      context.read<AuthBloc>().state.currentDevice?.config.isRetail==true?AssetsKeys.homeTitleRetailSvg:AssetsKeys.homeTitleSvg,
                                    width: ru.width,
                                    fit: BoxFit.contain,

                                  )
                              ),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: AutoSizeText(LocaleKeys.home_body_clickToInit.tr(),minFontSize: 1,style: const TextStyle(
                                  color: IziColors.grey,
                                  fontWeight: FontWeight.w400,
                                ),maxLines: 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IziText.body(
                              color: IziColors.grey35,
                              text: context
                                      .read<AuthBloc>()
                                      .state
                                      .currentDevice
                                      ?.nombre ??
                                  "",
                              fontWeight: FontWeight.w500),
                          const Divider(
                            color: IziColors.grey35,
                            height: 20,
                            thickness: 1,
                          ),
                          SizedBox(
                            height: ru.height*0.03,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AutoSizeText(LocaleKeys.home_body_anIziPlatform.tr(),minFontSize: 1,style: const TextStyle(
                                  color: IziColors.darkGrey,fontWeight: FontWeight.w400
                                ),),
                                Padding(
                                  padding: EdgeInsets.only(left: ru.height*0.005,bottom: ru.height*0.002),
                                  child: const FittedBox(
                                    child: Icon(
                                      IziIcons.izi,
                                      color: IziColors.primary,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: ru.height*0.01,
                          ),
                        ],
                      )
                    ],
                  ),
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
                                child: state.currentContribuyente?.logo != null
                                    ? CachedNetworkImage(
                                  imageUrl:
                                  "${dotenv.env[EnvKeys.apiUrl]}/contribuyentes/${state.currentContribuyente?.id}/logo",
                                  fit: BoxFit.fitHeight,
                                  placeholder: (context, url) =>
                                  const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: IziColors.dark)),
                                  errorWidget: (context, url, error) {
                                    return const SizedBox.shrink();
                                  },
                                )
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(width: 32,),
                              Expanded(
                                child: IziText.titleBig(
                                    color: IziColors.primary,
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
