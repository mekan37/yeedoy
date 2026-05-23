import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCta,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Semantics(
      container: true,
      label: semanticLabel ?? '$title. $description',
      child: Container(
        padding: EdgeInsets.all(tokens.space16),
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(tokens.radius20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            SizedBox(height: tokens.space12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.titleStyle.copyWith(fontSize: 20),
            ),
            SizedBox(height: tokens.space8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: context.bodyStyle.copyWith(color: AppColors.muted),
            ),
            if (ctaLabel != null && onCta != null) ...[
              SizedBox(height: tokens.space12),
              OutlinedButton(onPressed: onCta, child: Text(ctaLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

