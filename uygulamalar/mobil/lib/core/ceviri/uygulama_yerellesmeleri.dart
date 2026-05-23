import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension ReviewRatingCriterionLabels on AppLocalizations {
  String get reviewRatingCriterionTaste =>
      localeName.startsWith('tr') ? 'Lezzet' : 'Taste';

  String get reviewRatingCriterionServiceSpeed =>
      localeName.startsWith('tr') ? 'Servis Hizi' : 'Service speed';

  String get reviewRatingCriterionPricePerformance =>
      localeName.startsWith('tr') ? 'Fiyat performans' : 'Price performance';

  String get reviewRatingCriterionCleanliness =>
      localeName.startsWith('tr') ? 'Temizlik' : 'Cleanliness';

  String get reviewRatingCriterionAtmosphere =>
      localeName.startsWith('tr') ? 'Atmosfer' : 'Atmosphere';

  String get mapsLabel => localeName.startsWith('tr') ? 'Harita' : 'Maps';

  String get websiteLabel => 'Website';

  String get contactTitle => localeName.startsWith('tr') ? 'Iletisim' : 'Contact';
}
