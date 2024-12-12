import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
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
    }
    catch(e){
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      return  Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (val){
          setState(() {
            showVideo=false;
            _initVideo(context: context);
            GoRouter.of(context).goNamed(RoutesKeys.makeOrder);
            context.read<PageUtilsBloc>().initScreenActive();
          });
        },
        child: Stack(
              children: [
                const Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: IziColors.primary,
                      ),
                    ),
                  ),
                ),
                if (showVideo && _controller!=null && _controller?.value.isInitialized==true)
                  Positioned.fill(
                    child: FittedBox(
                        alignment: Alignment.center,
                        fit: BoxFit.cover,child: SizedBox(
                        height: _controller?.value.size.height,
                        width: _controller?.value.size.width,child: VideoPlayer(_controller!))),
                  )
              ],
            ),
      );
    });
  }
}
