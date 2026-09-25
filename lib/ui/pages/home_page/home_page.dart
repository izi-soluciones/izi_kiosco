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
import 'package:izi_kiosco/app/utils/kiosk_locale.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/home/home_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/general/custom_icons/kiosk_hand_icon.dart';
import 'package:izi_kiosco/ui/general/language_selector.dart';
import 'package:izi_kiosco/ui/general/widgets/password_modal.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VideoPlayerController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  @override
  void initState() {
    _initVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      KioskLocale.reset(
          context, context.read<AuthBloc>().state.currentDevice?.config);
    });
    super.initState();
  }

  var showVideo = false;

  _initVideo({BuildContext? context})async {
    try{

      if(_controller!=null){
        _controller?.pause();
        _controller?.dispose();
      }
      var authState = (context ?? this.context).read<AuthBloc>().state;
      if(!mounted){
        return;
      }
      if(authState.currentDevice?.config.timeVideo!=0){
        await Future.delayed(Duration(seconds: authState.currentDevice?.config.timeVideo ?? AppConstants.timerVideo));
      }

      if(!mounted){
        return;
      }


      if (kIsWeb && authState.currentDevice?.config.video !=null) {
        _controller = VideoPlayerController.networkUrl(
            Uri.parse(authState.currentDevice?.config.video??""))
          ..setLooping(true)
          ..initialize().then((_) {
            if(mounted){
              setState(() {
                showVideo = true;
              });
            }
          })..play();
      } else if (authState.video != null) {
        _controller = VideoPlayerController.file(authState.video!)
          ..setLooping(true)
          ..initialize().then((_) {
            if(mounted){
              setState(() {
                showVideo = true;
              });
            }
          })..play();
      }
    }
    catch(e){
      log(e.toString());
    }
  }

  void _onAttractTap(PointerDownEvent val) {
    // Ignore taps in the top-left config area (200x200)
    if (val.localPosition.dx < 200 && val.localPosition.dy < 200) {
      return;
    }
    setState(() {
      showVideo = false;
      GoRouter.of(context).goNamed(RoutesKeys.makeOrder);
      context
          .read<PageUtilsBloc>()
          .initScreenActive(context.read<AuthBloc>().state);
    });
  }

  bool showError = true;

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
      return previous.currentDevice?.config.idiomaDefecto !=
          current.currentDevice?.config.idiomaDefecto;
    }, listener: (context, state) {
      KioskLocale.reset(context, state.currentDevice?.config);
    }, builder: (context, state) {
      return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [

                    state.currentDevice?.config.timeVideo==0 && state.currentDevice?.config.video != null?
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if(context.read<AuthBloc>().state.currentDevice?.config.isRetail==true && context.read<AuthBloc>().state.currentDevice?.config.isRetailBarcode==true){

                            GoRouter.of(context).goNamed(RoutesKeys.makeOrderRetail);
                          }
                          else{
                            GoRouter.of(context).goNamed(RoutesKeys.makeOrder);
                          }
                          context.read<PageUtilsBloc>().initScreenActive(context.read<AuthBloc>().state);
                        },
                        child: Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: context.iziColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ):GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if(context.read<AuthBloc>().state.currentDevice?.config.isRetail==true && context.read<AuthBloc>().state.currentDevice?.config.isRetailBarcode==true){

                          GoRouter.of(context).goNamed(RoutesKeys.makeOrderRetail);
                        }
                        else{
                          GoRouter.of(context).goNamed(RoutesKeys.makeOrder);
                        }
                        context.read<PageUtilsBloc>().initScreenActive(context.read<AuthBloc>().state);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IziText.titleBig(
                                color: context.iziColors.primary,
                                text: dotenv.env[EnvKeys.brandName]=="iZi"?LocaleKeys.home_subtitles_iziSlogan.tr():LocaleKeys.home_subtitles_izifySlogan.tr(),
                                fontWeight: FontWeight.w400),
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
                                                  Center(
                                                      child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: context.iziColors.dark)),
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
                                          colorFilter: ColorFilter.mode(context.iziColors.primary, BlendMode.srcIn),
                                            AssetsKeys.homeTitleForLocale(
                                                context.locale.languageCode,
                                                retail: context.read<AuthBloc>().state.currentDevice?.config.isRetail==true && context.read<AuthBloc>().state.currentDevice?.config.isRetailBarcode==true),
                                          width: ru.width,
                                          fit: BoxFit.contain,

                                        )
                                    ),
                                  ),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 600),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: AutoSizeText(LocaleKeys.home_body_clickToInit.tr(),minFontSize: 1,maxFontSize: 100,style: TextStyle(
                                        color: context.iziColors.grey,
                                        fontSize: 100,
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
                                    color: context.iziColors.grey35,
                                    text: context
                                            .read<AuthBloc>()
                                            .state
                                            .currentDevice
                                            ?.nombre ??
                                        "",
                                    fontWeight: FontWeight.w500),
                                Divider(
                                  color: context.iziColors.grey35,
                                  height: 20,
                                  thickness: 1,
                                ),
                                SizedBox(
                                  height: ru.height*0.03,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AutoSizeText(LocaleKeys.home_body_anIziPlatform.tr(),minFontSize: 1,style:  TextStyle(
                                        color: context.iziColors.darkGrey,fontWeight: FontWeight.w400
                                      ),),
                                      Padding(
                                        padding: EdgeInsets.only(left: ru.height*0.005,bottom: ru.height*0.002),
                                        child: dotenv.env[EnvKeys.brandName]=="iZi"?FittedBox(
                                          child: Icon(
                                            IziIcons.izi,
                                            color: context.iziColors.primary,
                                            size: 40,
                                          )
                                        ):Image.asset(AssetsKeys.izifyIconH, width: 60,),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: ru.height*0.01,
                                ),
                                const LanguageSelector(),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    if (showVideo && _controller!=null && _controller?.value.isInitialized==true)
                      Positioned.fill(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Listener(
                                onPointerDown: _onAttractTap,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    widgetError(),
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
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              color: context.iziColors.white,
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Listener(
                                    onPointerDown: _onAttractTap,
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
                                             Center(
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: context.iziColors.dark)),
                                            errorWidget: (context, url, error) {
                                              return const SizedBox.shrink();
                                            },
                                          )
                                              : const SizedBox.shrink(),
                                        ),
                                        const SizedBox(width: 32,),
                                        Expanded(
                                          child: IziText.titleBig(
                                              color: context.iziColors.primary,
                                              text: LocaleKeys.home_body_clickToInit.tr(),
                                              fontWeight: FontWeight.w400),
                                        ),
                                        const SizedBox(width: 16,),
                                        const KioskHandIcon(width: 70),

                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Queda fuera del Listener: ese callback se dispara
                                  // aunque el hijo atienda el toque, y lanzaria el pedido.
                                  const LanguageSelector(),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    if (showError)
                    Positioned(child: widgetError()),
                    Positioned(
                      top: 0,
                        left: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                            onLongPress: () async {
                              final pin = context.read<AuthBloc>().state.currentDevice?.config.pin;
                              final correctPin = (pin != null && pin.isNotEmpty) ? pin : '4321';
                              
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => PasswordModal(correctPin: correctPin),
                              );
                              
                              if (result == true) {
                                if (mounted) {
                                  setState(() {
                                    showVideo = false;
                                  });
                                }
                                context.read<PageUtilsBloc>().initScreenActive(context.read<AuthBloc>().state);
                                GoRouter.of(context).goNamed(RoutesKeys.errorPayments);
                              }
                            },
                            child: const SizedBox(width: 200,height: 200,)
                        )
                    )
                  ],
                ),
              ),
            ],
          );
    });
  }
  widgetError(){
    return BlocBuilder<HomeBloc,HomeState>(
        builder: (context,state) {
          if(state.statusServer && state.statusServerPos){
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 16),
            color: context.iziColors.yellow,
            child: Row(
              children: [
                Expanded(
                  child: IziText.body(
                      fontWeight: FontWeight.w600,
                      color: context.iziColors.dark,
                      textAlign: TextAlign.center,
                      text: !state.statusServer
                          ? LocaleKeys.home_messages_serverDown.tr()
                          : LocaleKeys.home_messages_posDisconnected.tr()
                  ),
                ),
                InkWell(
                  onTap: (){
                    setState(() {
                      showError=false;
                    });
                  },
                  child:  Icon(IziIcons.close,color: context.iziColors.dark,),
                ),
              ],
            ),
          );
        }
    );
  }
}
