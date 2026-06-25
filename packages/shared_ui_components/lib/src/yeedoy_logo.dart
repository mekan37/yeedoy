import 'package:flutter/material.dart';

import 'brand_assets.dart';

class YeedoyLogo extends StatelessWidget {
  const YeedoyLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.textColor,
  });

  final double size;
  final bool showText;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final asset = showText ? BrandAssets.wordmark : BrandAssets.mark;
    final aspectRatio = showText ? 1677 / 524 : 1.0;
    final width = showText ? size * aspectRatio : size;

    return Semantics(
      label: 'Yeedoy',
      image: true,
      child: Image.asset(
        asset,
        package: 'yeedoy_shared_ui_components',
        width: width,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}
