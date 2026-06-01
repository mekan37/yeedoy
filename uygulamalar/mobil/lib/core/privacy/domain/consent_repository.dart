import 'consent_state.dart';

abstract class ConsentRepository {
  /// Daha önce kaydedilmiş onayı yükler.
  Future<ConsentState> load();

  /// Onay durumunu kalıcı olarak saklar.
  Future<void> save(ConsentState state);

  /// KVKK veri silme talebi — tüm onay verilerini temizler.
  Future<void> clear();
}
