import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';

class TrustScoreIndicator extends StatelessWidget {
  const TrustScoreIndicator({
    super.key,
    required this.score,
    this.size = 96,
    this.showLabel = true,
  });

  final int score;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final safeScore = score.clamp(0, 100);
    final color = _colorForScore(safeScore);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: safeScore / 100,
                strokeWidth: 7,
                color: color,
                backgroundColor: AppColors.border,
              ),
              Text(
                '$safeScore%',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            t.trustScore,
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Color _colorForScore(int value) {
    if (value >= 80) return AppColors.success;
    if (value >= 50) return AppColors.warning;
    return AppColors.danger;
  }
}
