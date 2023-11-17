
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart';
import 'package:izi_kiosco/ui/utils/fake_ui/platform_view_registry.dart';

class WebImage extends StatelessWidget {
  final String imageUrl;
  const WebImage({super.key,required this.imageUrl});


  @override
  Widget build(BuildContext context) {
    platformViewRegistry.registerViewFactory(
      imageUrl,
          (int _) => ImageElement()..src = imageUrl,
    );
    return HtmlElementView(
      viewType: imageUrl,
    );
  }

}