import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';

/// Returns a ₺ symbol string for the price badge.
///
/// [priceLevel] (DB column) is checked first:
///   'budget' → ₺, 'mid' → ₺₺, 'premium' → ₺₺₺
///
/// Falls back to threshold-based mapping from [cents] (kurus, 1/100 TL)
/// when [priceLevel] is null or unrecognised:
///   < 20 000 → ₺ (< 200 TL), < 45 000 → ₺₺ (200–450 TL), else → ₺₺₺
///
/// Returns null when both inputs are absent/zero — badge is hidden.
String? priceLevelSymbol(String? priceLevel, int? cents) {
  switch (priceLevel) {
    case 'budget':
      return '₺';
    case 'mid':
      return '₺₺';
    case 'premium':
      return '₺₺₺';
    default:
      break;
  }
  if (cents == null || cents <= 0) return null;
  if (cents < 20000) return '₺';
  if (cents < 45000) return '₺₺';
  return '₺₺₺';
}

/// Shows "Açık" (green dot) or "Kapalı" (grey dot).
/// Rendered only when [isOpen] is known — caller guards with a null check
/// on the source `isOpenNow` field.
class OpenStatusBadge extends StatelessWidget {
  const OpenStatusBadge({super.key, required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = isOpen ? AppColors.success : AppColors.muted;
    final label = isOpen ? t.openNow : t.closedNow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows ₺ / ₺₺ / ₺₺₺ price level symbol.
class PriceLevelBadge extends StatelessWidget {
  const PriceLevelBadge({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        symbol,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textStrong,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// A compact horizontal row that shows open/closed status and price level
/// badges side by side. Each badge is independently nullable — if both are
/// absent the row renders nothing (caller guards before placing this widget).
class OpenPriceBadgeRow extends StatelessWidget {
  const OpenPriceBadgeRow({
    super.key,
    required this.isOpenNow,
    required this.priceLevelSymbol,
  });

  final bool? isOpenNow;
  final String? priceLevelSymbol;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (isOpenNow != null) OpenStatusBadge(isOpen: isOpenNow!),
        if (priceLevelSymbol != null) PriceLevelBadge(symbol: priceLevelSymbol!),
      ],
    );
  }
}
