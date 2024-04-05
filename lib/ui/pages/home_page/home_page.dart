import 'dart:async';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
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


        if (kIsWeb && authState.currentDevice?.config["video"] is String) {
          _controller = VideoPlayerController.networkUrl(
              Uri.parse(authState.currentDevice?.config["video"]))
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  GoRouter.of(context).goNamed(RoutesKeys.makeOrder);
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
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 200,
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
                                const SizedBox(
                                  height: 60,
                                ),
                                Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 30, right: 30, left: 30),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _textBig(LocaleKeys.home_body_order.tr()),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _textBig(
                                                  LocaleKeys.home_body_and.tr(),
                                                  fontWeight: FontWeight.w200),
                                              const SizedBox(
                                                width: 16,
                                              ),
                                              _textBig(
                                                  LocaleKeys.home_body_pay.tr()),
                                            ],
                                          ),
                                          _textBig(LocaleKeys.home_body_here.tr()),
                                        ],
                                      ),
                                    ),
                                    const Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Padding(
                                          padding: EdgeInsets.only(),
                                          child: KioskHandIcon(width: 100),
                                        )),
                                  ],
                                ),
                                const SizedBox(
                                  height: 40,
                                ),
                                IziText.titleBig(
                                    color: IziColors.grey,
                                    text: LocaleKeys.home_body_clickToInit.tr(),
                                    fontWeight: FontWeight.w400),
                              ],
                            ),
                          ),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IziText.titleMedium(
                                  color: IziColors.darkGrey,
                                  text: LocaleKeys.home_body_anIziPlatform.tr(),
                                  fontWeight: FontWeight.w400),
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 8),
                                child: Icon(
                                  IziIcons.izi,
                                  color: IziColors.primary,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 40,
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

  Widget _textBig(String text, {FontWeight? fontWeight}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
          height: 0.95,
          fontWeight: fontWeight ?? FontWeight.w800,
          color: IziColors.primary,
          fontSize: 128),
    );
  }
}
