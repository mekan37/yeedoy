import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(width: tokens.space8),
            Expanded(
              child: Text(
                title,
                style: context.titleStyle.copyWith(fontSize: 20),
              ),
            ),
            ...?(trailing == null ? null : [trailing!]),
          ],
        ),
        if (subtitle != null) ...[SizedBox(height: tokens.space8), subtitle!],
      ],
    );
  }
}

