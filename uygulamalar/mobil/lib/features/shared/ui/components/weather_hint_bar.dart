import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/weather/weather_hint_provider.dart';

class WeatherHintBar extends ConsumerWidget {
  const WeatherHintBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weatherHintDataProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final t = context.l10n;
        final icon = _iconFor(data.weatherCode);
        final headline = _headlineText(t, data.kind);
        final hint = _hintForData(data);
        final tempText = data.temperatureC == null
            ? ''
            : ' \u00B7 ${data.temperatureC!.round()}\u00B0C';
        final text = '$headline$tempText \u00B7 $hint';

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: compact ? 18 : 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _headlineText(AppLocalizations t, WeatherHintKind kind) {
  switch (kind) {
    case WeatherHintKind.rainy:
      return t.weatherHeadlineRainy;
    case WeatherHintKind.snowy:
      return t.weatherHeadlineSnowy;
    case WeatherHintKind.hot:
      return t.weatherHeadlineHot;
    case WeatherHintKind.clear:
      return t.weatherHeadlineClear;
  }
}

String _hintForData(WeatherHintData data) {
  final hints = hintsForKind(data.kind);
  return hints[data.hintIndex.clamp(0, hints.length - 1)];
}

IconData _iconFor(int? code) {
  if (code == null) return Icons.wb_sunny_outlined;
  if (code == 0 || code == 1 || code == 2) return Icons.wb_sunny_outlined;
  if (code == 3 || code == 45 || code == 48) return Icons.cloud_outlined;
  if (code >= 51 && code <= 67) return Icons.grain;
  if (code >= 71 && code <= 77) return Icons.ac_unit;
  if (code >= 80 && code <= 82) return Icons.umbrella_outlined;
  if (code >= 95) return Icons.thunderstorm_outlined;
  return Icons.cloud_outlined;
}
