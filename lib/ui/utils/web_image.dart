
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart';
import 'package:fastor_app_ui_widget/fastor_app_ui_widget.dart'  if (dart.library.html)  'dart:ui' as ui;

class WebImage extends StatelessWidget {
  final String imageUrl;
  const WebImage({super.key,required this.imageUrl});


  @override
  Widget build(BuildContext context) {
    // ignore:undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      imageUrl,
          (int _) => ImageElement()..src = imageUrl,
    );
    return HtmlElementView(
      viewType: imageUrl,
    );
  }
}