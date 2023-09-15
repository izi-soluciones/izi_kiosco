import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:lottie/lottie.dart';
import 'package:just_audio/just_audio.dart';

class SplashPage extends StatefulWidget {
  final player = AudioPlayer();
  SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {

    if(!kIsWeb){
      widget.player.setAsset(AssetsKeys.iziSound).then(
              (duration)async{
            await widget.player.play();
            widget.player.dispose();
          }
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size=MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: IziColors.lightGrey30,
        body: Stack(
            children: _buildItems(size)
        )
    );
  }

  List<Widget> _buildItems(Size size){
    final random = Random();
    List<Widget> items=[];
    for(int i=0;i<(size.width>700?20:15);i++){
      items.add(
          Positioned(
              left: random.nextInt(size.width.toInt()>2000?2000:size.width.toInt())*1.0,
              bottom: random.nextInt(size.height.toInt()>2000?2000:size.height.toInt())*1.0,
              child: Icon(IziIcons.plusB,color: [IziColors.redLighten,IziColors.redLighten50,IziColors.secondaryLighten,IziColors.secondaryLighten60][random.nextInt(4)],)
          )
      );
    }

    items.add(
      Positioned.fill(
        child: Center(
          child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: IziColors.lightGrey30,
                  borderRadius: BorderRadius.circular(108)
              ),
              child: Lottie.asset(AssetsKeys.splashScreenJson,width: 108,repeat: false,)
          ),
        ),
      ),
    );

    return items;
  }
}