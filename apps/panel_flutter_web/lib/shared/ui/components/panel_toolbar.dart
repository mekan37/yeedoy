import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/colors.dart';
import 'panel_section_card.dart';

class PanelToolbar extends StatelessWidget {
  const PanelToolbar({
    super.key,
    required this.children,
    this.footer = const <Widget>[],
  });

  final List<Widget> children;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return PanelSectionCard(
      padding: EdgeInsets.all(tokens.space20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 860;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: tokens.space12,
                runSpacing: tokens.space12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: children,
              ),
              if (footer.isNotEmpty) ...[
                SizedBox(height: tokens.space16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    stacked ? tokens.space12 : tokens.space16,
                  ),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      AppColors.primarySoft.withValues(alpha: 0.18),
                      AppColors.cardAlt,
                    ),
                    borderRadius: BorderRadius.circular(tokens.radius20),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.72),
                    ),
                  ),
                  child: Wrap(
                    spacing: tokens.space8,
                    runSpacing: tokens.space8,
                    children: footer,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
