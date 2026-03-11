import '../../../core/i18n/app_localizations.dart';
import '../domain/owner_menu_models.dart';

String ownerMenuErrorMessage(
  AppLocalizations l10n,
  Object error, {
  String? fallback,
}) {
  if (error is OwnerMenuException) {
    switch (error.code) {
      case 'not_owner':
        return l10n.ownerMenuErrorNotOwner;
      case 'invalid':
        return error.message;
      case 'not_found':
        return l10n.ownerMenuErrorNotFound;
      case 'has_items':
        return l10n.ownerMenuErrorHasItems;
      default:
        return error.message;
    }
  }
  return fallback ?? l10n.ownerMenuErrorGeneric;
}

