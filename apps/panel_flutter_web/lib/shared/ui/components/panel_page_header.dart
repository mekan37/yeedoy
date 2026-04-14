import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/colors.dart';
import 'panel_action_button.dart';

class PanelPageHeader extends StatelessWidget {
  const PanelPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.actions = const <Widget>[],
    this.compactActions = const <PanelActionButton>[],
    this.padding,
  });

  final Widget title;
  final String? eyebrow;
  final String? description;
  final List<Widget> actions;
  final List<PanelActionButton> compactActions;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(
            tokens.space20,
            tokens.space16,
            tokens.space20,
            tokens.space16,
          ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 860;
          final actionWidgets = actions.isNotEmpty ? actions : compactActions;
          final titleSize = stacked ? 30.0 : 36.0;
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!.toUpperCase(),
                  style: context.captionStyle.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.primaryDeep,
                  ),
                ),
              if (eyebrow != null) SizedBox(height: tokens.space8),
              Semantics(
                header: true,
                child: DefaultTextStyle(
                  style: context.titleStyle.copyWith(
                    fontSize: titleSize,
                    height: 1.08,
                    letterSpacing: -0.5,
                  ),
                  child: title,
                ),
              ),
              if (description != null) ...[
                SizedBox(height: tokens.space12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    description!,
                    style: context.subtitleStyle.copyWith(
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ],
          );

          final actionWrap = actionWidgets.isEmpty
              ? const SizedBox.shrink()
              : Wrap(
                  spacing: tokens.space8,
                  runSpacing: tokens.space8,
                  alignment: WrapAlignment.end,
                  children: actionWidgets,
                );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                if (actionWidgets.isNotEmpty) ...[
                  SizedBox(height: tokens.space16),
                  actionWrap,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              if (actionWidgets.isNotEmpty) ...[
                SizedBox(width: tokens.space16),
                Flexible(child: actionWrap),
              ],
            ],
          );
        },
      ),
    );
  }
}
