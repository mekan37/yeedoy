import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import 'app_empty_state.dart';
import 'app_skeleton.dart';

class OwnerPanelFeedback extends StatelessWidget {
  const OwnerPanelFeedback.loading({super.key, this.cardCount = 3})
    : _type = _OwnerPanelFeedbackType.loading,
      icon = null,
      title = null,
      description = null,
      onRetry = null,
      retryLabel = null;

  const OwnerPanelFeedback.empty({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onRetry,
    this.retryLabel,
  }) : _type = _OwnerPanelFeedbackType.empty,
       cardCount = 0;

  const OwnerPanelFeedback.error({
    super.key,
    required this.title,
    required this.description,
    this.onRetry,
    this.retryLabel,
  }) : _type = _OwnerPanelFeedbackType.error,
       icon = Icons.error_outline,
       cardCount = 0;

  final _OwnerPanelFeedbackType _type;
  final IconData? icon;
  final String? title;
  final String? description;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    switch (_type) {
      case _OwnerPanelFeedbackType.loading:
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cardCount,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => const AppSkeletonCard(lines: 3),
        );
      case _OwnerPanelFeedbackType.empty:
      case _OwnerPanelFeedbackType.error:
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AppEmptyState(
              icon: icon!,
              title: title!,
              description: description!,
              ctaLabel: onRetry == null
                  ? null
                  : (retryLabel ?? context.l10n.retry),
              onCta: onRetry,
            ),
          ),
        );
    }
  }
}

enum _OwnerPanelFeedbackType { loading, empty, error }
