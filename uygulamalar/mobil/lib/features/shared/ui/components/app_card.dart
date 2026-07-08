import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/app_tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final content = Padding(
      padding: padding ?? EdgeInsets.all(tokens.space16),
      child: child,
    );

    final decoration = BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(tokens.radius20),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.08),
          blurRadius: tokens.elevation2,
          offset: const Offset(0, 2),
        ),
      ],
    );

    final ink = Ink(decoration: decoration, child: content);

    final card = onTap == null
        ? Material(color: Colors.transparent, child: ink)
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(tokens.radius20),
              child: ink,
            ),
          );
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: card,
    );
  }
}

