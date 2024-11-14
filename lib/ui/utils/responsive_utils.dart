import 'package:flutter/material.dart';
const xxs=350;
const xs=600;
const sm=960;
const md=1280;
const mdLg=1500;
const lg=1920;
class ResponsiveUtils{
  Size size;

  ResponsiveUtils(BuildContext context):
        size=MediaQuery.of(context).size;
  bool isXXs(){
    return size.width<=xxs;
  }
  bool isXs(){
    return size.width<=xs;
  }
  bool isSm(){
    return size.width>xs&&size.width<=sm;
  }
  bool isMd(){
    return size.width>sm&&size.width<=md;
  }
  bool isMdLg(){
    return size.width>md&&size.width<=mdLg;
  }
  bool isLg(){
    return size.width>md&&size.width<=lg;
  }
  bool isXl(){
    return size.width>lg;
  }
  bool gtXxs(){
    return size.width>xxs;
  }
  bool gtXs(){
    return size.width>xs;
  }
  bool gtSm(){
    return size.width>sm;
  }
  bool gtMd(){
    return size.width>md;
  }
  bool gtLg(){
    return size.width>lg;
  }

  bool lwSm(){
    return size.width<=sm;
  }
  bool lwMd(){
    return size.width<=md;
  }
  bool lwLg(){
    return size.width<=lg;
  }

  bool isVertical(){
    return size.aspectRatio < 1;
  }


  double get width => size.width;
  double get height => size.height;
}

