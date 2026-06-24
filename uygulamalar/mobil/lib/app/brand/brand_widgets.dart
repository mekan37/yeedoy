import 'package:flutter/material.dart';
import 'package:yeedoy_shared_ui_components/brand_assets.dart';

import '../../core/constants/app_strings.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.height = 28, this.inverse = false});

  final double height;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Text(
          AppStrings.appName,
          style: TextStyle(
            color: inverse ? Colors.white : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class BrandMascot extends StatelessWidget {
  const BrandMascot({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
