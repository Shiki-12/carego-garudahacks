import 'dart:async';

import 'package:flutter/material.dart';

import '../size_confige.dart';

class DoctorBanner extends StatefulWidget {
  const DoctorBanner({
    Key? key,
  }) : super(key: key);

  @override
  State<DoctorBanner> createState() => _DoctorBannerState();
}

class _DoctorBannerState extends State<DoctorBanner> {
  static const _bannerImages = [
    "asset_feature_banner/1.png",
    "asset_feature_banner/2.png",
    "asset_feature_banner/3.png",
  ];

  late final PageController _pageController;
  Timer? _slideTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;

      final nextIndex = (_currentIndex + 1) % _bannerImages.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: getRelativeHeight(0.31),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _bannerImages.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return Image.asset(
                  _bannerImages[index],
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                );
              },
            ),
            Positioned(
              top: getRelativeHeight(0.030),
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_bannerImages.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isActive
                        ? getRelativeWidth(0.052)
                        : getRelativeWidth(0.018),
                    height: getRelativeWidth(0.018),
                    margin: EdgeInsets.symmetric(
                      horizontal: getRelativeWidth(0.006),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: isActive ? 0.95 : 0.45,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
