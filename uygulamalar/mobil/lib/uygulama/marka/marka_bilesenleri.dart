import 'package:flutter/material.dart';
import 'package:yeedoy_shared_ui_components/yeedoy_shared_ui_components.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.height = 28, this.inverse = false});

  final double height;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    return YeedoyLogo(
      size: height,
      textColor: inverse ? Colors.white : AppColors.textStrong,
    );
  }
}

class BrandMascot extends StatelessWidget {
  const BrandMascot({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return YeedoyLogo(size: size, showText: false);
  }
}


