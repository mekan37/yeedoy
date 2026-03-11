import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../business/domain/meal_card_asset_mapper.dart';
import '../../../business/domain/meal_card_provider_option.dart';

class MealCardBadge extends StatelessWidget {
  const MealCardBadge({
    super.key,
    required this.provider,
    this.selected = false,
  });

  final MealCardProviderOption provider;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final assetPath = MealCardAssetMapper.assetPathForProvider(provider);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEEF4FF) : const Color(0xFFF7F8FA),
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFE3E5E8),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Image.asset(
        assetPath,
        height: 16,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text(
            provider.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          );
        },
      ),
    );
  }
}

class MealCardBadgeRow extends StatelessWidget {
  const MealCardBadgeRow({
    super.key,
    required this.providers,
    this.maxVisible,
    this.spacing = 6,
    this.runSpacing = 6,
  });

  final List<MealCardProviderOption> providers;
  final int? maxVisible;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();
    final visibleLimit = maxVisible;
    final visibleProviders = visibleLimit == null
        ? providers
        : providers.take(visibleLimit).toList(growable: false);
    final hiddenCount = providers.length - visibleProviders.length;

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (final provider in visibleProviders) MealCardBadge(provider: provider),
        if (hiddenCount > 0) _MealCardOverflowBadge(hiddenCount: hiddenCount),
      ],
    );
  }
}

class _MealCardOverflowBadge extends StatelessWidget {
  const _MealCardOverflowBadge({required this.hiddenCount});

  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: Border.all(color: const Color(0xFFE3E5E8)),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$hiddenCount',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}
