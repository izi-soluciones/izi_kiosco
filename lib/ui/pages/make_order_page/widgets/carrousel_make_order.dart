import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CarrouselMakeOrder extends StatefulWidget {
  final List<String> imageUrls;

  const CarrouselMakeOrder({Key? key, required this.imageUrls}) : super(key: key);

  @override
  State<CarrouselMakeOrder> createState() => _CarrouselMakeOrderState();
}

class _CarrouselMakeOrderState extends State<CarrouselMakeOrder> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.imageUrls.length * 1000;
    _pageController = PageController(initialPage: _currentPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final url in widget.imageUrls) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemBuilder: (context, index) {
        final realIndex = index % widget.imageUrls.length;
        return CachedNetworkImage(
          imageUrl: widget.imageUrls[realIndex],
          fit: BoxFit.cover,
          placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
          const Center(child: Icon(Icons.broken_image, size: 50)),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }
}