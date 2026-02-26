import '../domain/owner_menu_models.dart';

String ownerMenuErrorMessage(Object error, {String? fallback}) {
  if (error is OwnerMenuException) {
    switch (error.code) {
      case 'not_owner':
        return 'Bu islem icin yetkin yok.';
      case 'invalid':
        return error.message;
      case 'not_found':
        return 'Kayıt bulunamadı.';
      case 'has_items':
        return 'Bölümde ürün var.';
      default:
        return error.message;
    }
  }
  return fallback ?? 'Bir hata oluştu.';
}


