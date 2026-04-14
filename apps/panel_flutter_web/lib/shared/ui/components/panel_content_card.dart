import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/colors.dart';
import 'app_card.dart';

class PanelContentCard extends StatelessWidget {
  const PanelContentCard({
    super.key,
    required this.child,
    this.title,
    this.description,
    this.trailing,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? description;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return AppCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || description != null || trailing != null) ...[
            Container(
              padding: EdgeInsets.only(bottom: tokens.space16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.72),
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 720;
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: context.titleStyle.copyWith(fontSize: 18),
                        ),
                      if (description != null) ...[
                        SizedBox(height: tokens.space4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Text(description!, style: context.captionStyle),
                        ),
                      ],
                    ],
                  );
                  if (stacked || trailing == null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading,
                        if (trailing != null) ...[
                          SizedBox(height: tokens.space12),
                          trailing!,
                        ],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: heading),
                      SizedBox(width: tokens.space16),
                      Flexible(child: trailing!),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: tokens.space16),
          ],
          child,
        ],
      ),
    );
  }
}
