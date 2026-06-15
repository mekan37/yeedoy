import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension ReviewCreatePageLabels on AppLocalizations {
  String get reviewCreateHeroTitle => localeName.startsWith('tr')
      ? 'Yorum Yap ve Puan Ver'
      : 'Write a Review & Rate';

  String get reviewCreateHeroSubtitle => localeName.startsWith('tr')
      ? 'Deneyimini paylaş, topluluğa yardımcı ol'
      : 'Share your experience and help the community';

  String get reviewCreateRatingHintLow =>
      localeName.startsWith('tr') ? 'Kötü' : 'Poor';

  String get reviewCreateRatingHintHigh =>
      localeName.startsWith('tr') ? 'Mükemmel' : 'Excellent';

  String get reviewCreateContentLabel => localeName.startsWith('tr')
      ? 'Yorumun (isteğe bağlı)'
      : 'Your review (optional)';

  String get reviewCreateContentPlaceholder => localeName.startsWith('tr')
      ? 'Deneyimini buraya yazabilirsin...'
      : 'Write about your experience here...';

  String get reviewCreatePhotosLabel =>
      localeName.startsWith('tr') ? 'Fotoğraf Ekle' : 'Add Photos';

  String get reviewCreateAddPhoto =>
      localeName.startsWith('tr') ? 'Fotoğraf ekle' : 'Add photo';

  String reviewCreateAddPhotoHint(int max) => localeName.startsWith('tr')
      ? 'En fazla $max foto'
      : 'Up to $max photos';

  String get reviewCreateExperienceLabel => localeName.startsWith('tr')
      ? 'Detaylı Değerlendirme (isteğe bağlı)'
      : 'Detailed Rating (optional)';

  String get reviewCreateAddToFavorites => localeName.startsWith('tr')
      ? 'Bu işletmeyi favorilerime ekle'
      : 'Add this business to my favorites';

  String get reviewCreateSubmitCta =>
      localeName.startsWith('tr') ? 'Yorumu Gönder' : 'Submit Review';
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
}
