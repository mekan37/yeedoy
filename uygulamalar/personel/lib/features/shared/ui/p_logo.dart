import 'package:flutter/material.dart';
import 'package:yeedoy_shared_ui_components/yeedoy_shared_ui_components.dart';

class PLogo extends StatelessWidget {
  const PLogo({super.key, this.size = 40, this.inverse = false});

  final double size;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    return YeedoyLogo(
      size: size,
      textColor: inverse ? Colors.white : AppColors.textStrong,
    );
  }
}
