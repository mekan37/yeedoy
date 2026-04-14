import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

class PanelContentSurface extends StatelessWidget {
  const PanelContentSurface({
    super.key,
    required this.child,
    this.maxWidth = 1520,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final resolvedPadding = padding ??
        EdgeInsets.fromLTRB(
          tokens.space24,
          tokens.space20,
          tokens.space24,
          tokens.space24,
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(maxWidth, constraints.maxWidth);
        return Padding(
          padding: resolvedPadding,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
