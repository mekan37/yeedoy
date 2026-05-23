import 'package:flutter/material.dart';

import '../../../../uygulama/tema/renkler.dart';
import '../../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../../features/shared/ui/tasarim_sistemi.dart';

class BusinessHeaderCompact extends StatelessWidget {
  const BusinessHeaderCompact({
    super.key,
    required this.isOpenNow,
    required this.closingTimeText,
    required this.averagePriceText,
    required this.topItemsText,
    required this.lastVerifiedText,
    required this.onDirectionsTap,
    required this.onMenuTap,
  });

  final bool? isOpenNow;
  final String closingTimeText;
  final String averagePriceText;
  final String topItemsText;
  final String lastVerifiedText;
  final VoidCallback onDirectionsTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final statusLabel = switch (isOpenNow) {
      true => t.businessStatusOpen,
      false => t.businessStatusClosed,
      null => t.unknown,
    };
    final statusColor = switch (isOpenNow) {
      true => AppColors.success,
      false => AppColors.danger,
      null => AppColors.muted,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                label: t.businessHeaderStatusClosingLabel,
                value: '$statusLabel • $closingTimeText',
                valueColor: statusColor,
              ),
              _InfoPill(
                label: t.businessHeaderAveragePriceLabel,
                value: averagePriceText,
              ),
              _InfoPill(
                label: t.businessHeaderPopularItemLabel,
                value: topItemsText,
              ),
              _InfoPill(
                label: t.businessHeaderLastVerificationLabel,
                value: lastVerifiedText,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDirectionsTap,
                  icon: const Icon(Icons.directions_outlined),
                  label: Text(t.businessHeaderDirectionsAction),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMenuTap,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(t.menu),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textStrong,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}


