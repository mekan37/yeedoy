import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/app_tokens.dart';

/// Dark-mode aware shimmer placeholder box.
///
/// Meant to be used inside a shimmer animation wrapper (e.g. the package-level
/// [AppShimmer] from `yeedoy_shared_ui_components`, or the discovery-local
/// `_ShimmerWrapper`). The box renders a solid fill that the parent
/// [ShaderMask] rewrites with a sweeping gradient.
class AppShimmerBox extends StatelessWidget {
  const AppShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;

  /// Defaults to [AppTokens.radius12] when null.
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.border, // opaque — ShaderMask rewrites it
        borderRadius: BorderRadius.circular(borderRadius ?? tokens.radius12),
      ),
    );
  }
}

/// A narrow line placeholder — typically used for text rows inside shimmer.
class AppShimmerLine extends StatelessWidget {
  const AppShimmerLine({
    super.key,
    this.width,
    this.height = 10.0,
  });

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
