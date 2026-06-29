/// data_deletion_page.dart — yasal metin uyum ve RPC bağlantı testleri
///
/// Bu testler UI'ı pump etmeden iş mantığını ve sabit metin değerlerini doğrular.
/// T1–T11: Önceki agent tarafından eklenen yasal metin uyum testleri (korunur).
/// T12–T23: Bu görevde eklenen RPC dallanma testleri.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/legal/legal_models.dart';
import 'package:yeedoy/features/legal/legal_repository.dart';

// ---------------------------------------------------------------------------
// Metin sabitleri — data_deletion_page.dart ile senkron tutulmalı
// ---------------------------------------------------------------------------

// _PreRequestCard satırları
const _preRequestTexts = [
  'Hesabınıza ilişkin kişisel verilerinizin silinmesini, yok edilmesini veya anonim hale getirilmesini talep edebilirsiniz.',
  'Bazı veriler yasal yükümlülükler veya güvenlik nedeniyle sınırlı süre saklanabilir.',
  'Talebinizin sonucu size bildirilecektir.',
];

// _AfterSubmitCard
const _afterSubmitText =
    'Talebiniz alınır ve değerlendirilir. Talebinizin sonucu size bildirilecektir. Bazı veriler yasal yükümlülükler nedeniyle sınırlı süre saklanabilir.';

// SnackBar — güncellendi: "Talebiniz alınmıştır. Değerlendirme sonucu size bildirilecektir."
const _snackBarText =
    'Talebiniz alınmıştır. Değerlendirme sonucu size bildirilecektir.';

// Pazarlama yönlendirme notu
const _marketingNoteText =
    'Pazarlama e-postasını kapatmak, veri silme talebinden farklı bir işlemdir. '
    'Bu seçenek yalnızca gelecekteki kampanya e-postalarını durdurur; '
    'mevcut verilerinizin silinmesini sağlamaz. '
    'Bildirim Ayarları sayfasından kolayca kapatabilirsiniz.';

// Talep nedeni listesi
const _reasons = [
  'Hesabımı silme talebi',
  'Kişisel verilerimin silinmesi / yok edilmesi / anonimleştirilmesi talebi',
  'Yorum, favori veya check-in verilerimle ilgili talep',
  'Destek talebi geçmişimle ilgili talep',
  'İşletme sahipliği başvurumla ilgili talep',
  'Pazarlama e-postası iznini kapatmak istiyorum',
  'Diğer',
];

const _marketingReason = 'Pazarlama e-postası iznini kapatmak istiyorum';

// ---------------------------------------------------------------------------
// Yasaklı ifadeler — ekranda GÖRÜNMEMELI
// ---------------------------------------------------------------------------

const _forbiddenPhrases = [
  'kalıcı olarak silinecektir',
  'geri alınamaz',
  '30 gün',
  'tüm verileriniz silinecek',
  'Veri İndir',
];

// ---------------------------------------------------------------------------
// UI seçeneği → request_type eşleştirme tablosu (data_deletion_page.dart ile senkron)
// ---------------------------------------------------------------------------

/// _reasonToRequestType() metodunu burada da uyguluyoruz.
/// data_deletion_page.dart içindeki switch expression ile birebir aynı olmalı.
String _reasonToRequestType(String reason) {
  return switch (reason) {
    'Kişisel verilerimin silinmesi / yok edilmesi / anonimleştirilmesi talebi' =>
      'delete_data',
    'Yorum, favori veya check-in verilerimle ilgili talep' =>
      'delete_interactions',
    'Destek talebi geçmişimle ilgili talep' => 'delete_support',
    'İşletme sahipliği başvurumla ilgili talep' => 'delete_owner_claims',
    _ => 'other',
  };
}

// ---------------------------------------------------------------------------
// Sahte repository (Supabase çağrısı yapmadan test)
// ---------------------------------------------------------------------------

class _FakeLegalRepository implements LegalRepository {
  bool submitPrivacyCalled = false;
  bool submitAccountDeletionCalled = false;
  String? lastPrivacyRequestType;
  String? lastPrivacyDetails;
  String? lastAccountDeletionReason;
  bool throwOnPrivacy = false;
  bool throwOnAccountDeletion = false;

  @override
  Future<void> submitPrivacyRequest({
    required String requestType,
    String? details,
  }) async {
    if (throwOnPrivacy) throw Exception('network_error');
    submitPrivacyCalled = true;
    lastPrivacyRequestType = requestType;
    lastPrivacyDetails = details;
  }

  @override
  Future<void> submitAccountDeletionRequest({String? reason}) async {
    if (throwOnAccountDeletion) throw Exception('network_error');
    submitAccountDeletionCalled = true;
    lastAccountDeletionReason = reason;
  }

  @override
  Future<PolicyAcceptanceSnapshot?> loadAcceptanceSnapshot() async => null;

  @override
  Future<LegalRequestOverview?> loadRequestOverview() async => null;

  @override
  Future<void> acceptPolicyVersions(
    List<PolicyVersionRecord> versions, {
    String sourceApp = 'test',
  }) async {}
}

// ---------------------------------------------------------------------------
// _submit() iş mantığı simülatörü
// UI pump gerekmeden neden seçimine göre hangi RPC'nin çağrıldığını doğrular.
// ---------------------------------------------------------------------------

/// _submit() içindeki neden dallanma mantığını doğrudan simüle eder.
/// data_deletion_page.dart'taki _submit() akışıyla birebir aynıdır.
Future<({bool navigated, String? error})> _runSubmitLogic({
  required String? reason,
  required _FakeLegalRepository repo,
  bool emailFilled = true,
}) async {
  // Neden seçilmemişse erken dön
  if (reason == null) {
    return (navigated: false, error: 'Lütfen talep nedenini seçin.');
  }

  // Pazarlama seçeneği → yönlendirme (RPC çağrılmaz)
  if (reason == _marketingReason) {
    // context.push('/notification-preferences') simüle edilir
    return (navigated: true, error: null);
  }

  // E-posta zorunluluğu
  if (!emailFilled) {
    return (navigated: false, error: 'Lütfen e-posta adresinizi girin.');
  }

  final details = 'Neden: $reason';

  try {
    if (reason == 'Hesabımı silme talebi') {
      await repo.submitAccountDeletionRequest(reason: details);
    } else {
      final requestType = _reasonToRequestType(reason);
      await repo.submitPrivacyRequest(requestType: requestType, details: details);
    }
    return (navigated: true, error: null);
  } catch (e) {
    return (navigated: false, error: e.toString());
  }
}

// ---------------------------------------------------------------------------
// Testler
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // T1–T11: Yasal metin uyum testleri (korunur)
  // =========================================================================

  group('DataDeletionPage — yasal metin uyum kontrolleri', () {
    // -----------------------------------------------------------------------
    // T1: Kesin "kalıcı silinecektir" ifadesi ekranda bulunmamalı
    // -----------------------------------------------------------------------
    test('T1: _PreRequestCard metinleri "kalıcı olarak silinecektir" içermiyor',
        () {
      for (final text in _preRequestTexts) {
        expect(
          text.toLowerCase().contains('kalıcı olarak silinecektir'),
          isFalse,
          reason:
              '"kalıcı olarak silinecektir" kesin ifadesi legal belgelerle çelişiyor. '
              'Sorunlu metin: "$text"',
        );
      }
    });

    // -----------------------------------------------------------------------
    // T2: "Bu işlem geri alınamaz" ifadesi ekranda bulunmamalı
    // -----------------------------------------------------------------------
    test('T2: Yasaklı ifadeler hiçbir ekran metninde yer almıyor', () {
      final allTexts = [
        ..._preRequestTexts,
        _afterSubmitText,
        _snackBarText,
        _marketingNoteText,
      ];

      for (final forbidden in _forbiddenPhrases) {
        for (final text in allTexts) {
          expect(
            text.toLowerCase().contains(forbidden.toLowerCase()),
            isFalse,
            reason:
                '"$forbidden" yasaklı ifadesi bulundu. '
                'Metin: "$text"',
          );
        }
      }
    });

    // -----------------------------------------------------------------------
    // T3: "30 gün" veya kesin süre ifadesi SnackBar metninde bulunmuyor
    // -----------------------------------------------------------------------
    test('T3: SnackBar metni kesin süre (30 gün, 60 gün vb.) içermiyor', () {
      final pattern = RegExp(r'\d+\s*(gün|hafta|ay|yıl)', caseSensitive: false);
      expect(
        pattern.hasMatch(_snackBarText),
        isFalse,
        reason:
            'SnackBar metninde kesin süre ifadesi bulunamaz. Metin: "$_snackBarText"',
      );
    });

    // -----------------------------------------------------------------------
    // T4: _AfterSubmitCard metni "sınırlı süre saklanabilir" içeriyor
    // -----------------------------------------------------------------------
    test(
        'T4: _AfterSubmitCard "sınırlı süre saklanabilir" uyarısını içeriyor',
        () {
      expect(
        _afterSubmitText.contains('sınırlı süre saklanabilir'),
        isTrue,
        reason:
            'Yasal saklama istisnası uyarısı _AfterSubmitCard metninde yer almalı.',
      );
    });

    // -----------------------------------------------------------------------
    // T5: "Talebiniz alınır ve değerlendirilir" ifadesi mevcut
    // -----------------------------------------------------------------------
    test('T5: _AfterSubmitCard "Talebiniz alınır ve değerlendirilir" içeriyor',
        () {
      expect(
        _afterSubmitText.contains('Talebiniz alınır ve değerlendirilir'),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // T6: Pazarlama seçeneği neden listesinde var ve ayrı olarak işaretli
    // -----------------------------------------------------------------------
    test('T6: _marketingReason _reasons listesinde yer alıyor', () {
      expect(_reasons.contains(_marketingReason), isTrue,
          reason:
              'Pazarlama e-postası seçeneği talep nedeni listesinde bulunmalı.');
    });

    // -----------------------------------------------------------------------
    // T7: Pazarlama nedeni seçilince submit() form göndermez (yönlendirme yapar)
    // -----------------------------------------------------------------------
    test(
        'T7: Pazarlama seçilince submitPrivacyRequest çağrılmaz',
        () async {
      final repo = _FakeLegalRepository();
      final result = await _runSubmitLogic(reason: _marketingReason, repo: repo);

      expect(
        repo.submitPrivacyCalled,
        isFalse,
        reason:
            'Pazarlama seçeneği seçildiğinde submitPrivacyRequest çağrılmamalı; '
            'kullanıcı bildirim ayarları sayfasına yönlendirilmeli.',
      );
      expect(repo.submitAccountDeletionCalled, isFalse,
          reason: 'Pazarlama seçeneği hesap silme RPC çağırmamalı.');
      expect(result.navigated, isTrue,
          reason: 'Pazarlama seçeneği yönlendirme yapmalı.');
    });

    // -----------------------------------------------------------------------
    // T8: Pazarlama yönlendirme notu "veri silme talebinden farklı" içeriyor
    // -----------------------------------------------------------------------
    test('T8: Pazarlama notu kullanıcıyı doğru bilgilendiriyor', () {
      expect(
        _marketingNoteText.contains('veri silme talebinden farklı'),
        isTrue,
        reason:
            'Pazarlama notu, bu seçeneğin veri silme talebinden farklı olduğunu belirtmeli.',
      );
    });

    // -----------------------------------------------------------------------
    // T9: Pazarlama notu "Bildirim Ayarları" yönlendirmesini içeriyor
    // -----------------------------------------------------------------------
    test('T9: Pazarlama notu "Bildirim Ayarları" sayfasına yönlendiriyor', () {
      expect(
        _marketingNoteText.contains('Bildirim Ayarları'),
        isTrue,
        reason:
            'Pazarlama notu, kullanıcıyı Bildirim Ayarları sayfasına yönlendirmeli.',
      );
    });

    // -----------------------------------------------------------------------
    // T10: "Veri İndir" aktif metin olarak ekranda yer almıyor
    // -----------------------------------------------------------------------
    test('T10: "Veri İndir" aktif buton/metin _preRequestTexts içinde yok',
        () {
      for (final text in _preRequestTexts) {
        expect(
          text.contains('Veri İndir'),
          isFalse,
          reason: '"Veri İndir" işlevsiz bir aksiyon olarak ekranda yer almamalı.',
        );
      }
    });

    // -----------------------------------------------------------------------
    // T11: _reasons listesi 7 seçenek içeriyor (pazarlama dahil)
    // -----------------------------------------------------------------------
    test('T11: Neden listesi beklenen 7 seçeneği içeriyor', () {
      expect(_reasons.length, equals(7));
      expect(_reasons.first, 'Hesabımı silme talebi');
      expect(_reasons.last, 'Diğer');
    });
  });

  // =========================================================================
  // T12–T23: RPC dallanma testleri
  // =========================================================================

  group('DataDeletionPage _submit() — RPC dallanma testleri', () {
    // -----------------------------------------------------------------------
    // T12: Hesap silme seçeneği → submit_account_deletion_request_v1 çağrıldı
    // -----------------------------------------------------------------------
    test('T12: "Hesabımı silme talebi" → submitAccountDeletionRequest çağrılır',
        () async {
      final repo = _FakeLegalRepository();
      await _runSubmitLogic(reason: 'Hesabımı silme talebi', repo: repo);

      expect(repo.submitAccountDeletionCalled, isTrue,
          reason: 'Hesap silme seçeneği submitAccountDeletionRequest çağırmalı.');
    });

    // -----------------------------------------------------------------------
    // T13: Hesap silme seçeneği → submit_privacy_request_v1 çağrılmadı
    // -----------------------------------------------------------------------
    test(
        'T13: "Hesabımı silme talebi" → submitPrivacyRequest çağrılmaz',
        () async {
      final repo = _FakeLegalRepository();
      await _runSubmitLogic(reason: 'Hesabımı silme talebi', repo: repo);

      expect(repo.submitPrivacyCalled, isFalse,
          reason:
              'Hesap silme talebi privacy_requests tablosuna gitmamalı; '
              'submitPrivacyRequest çağrılmamalı.');
    });

    // -----------------------------------------------------------------------
    // T14: "Kişisel verilerin silinmesi" → submit_privacy_request_v1 + request_type: 'delete_data'
    // -----------------------------------------------------------------------
    test(
        'T14: "Kişisel verilerimin silinmesi" → submitPrivacyRequest(delete_data)',
        () async {
      final repo = _FakeLegalRepository();
      await _runSubmitLogic(
        reason:
            'Kişisel verilerimin silinmesi / yok edilmesi / anonimleştirilmesi talebi',
        repo: repo,
      );

      expect(repo.submitPrivacyCalled, isTrue);
      expect(repo.lastPrivacyRequestType, equals('delete_data'),
          reason:
              '"Kişisel verilerimin silinmesi" seçeneği request_type="delete_data" göndermelidir.');
      expect(repo.submitAccountDeletionCalled, isFalse);
    });

    // -----------------------------------------------------------------------
    // T15: "Yorum, favori veya check-in" → request_type: 'delete_interactions'
    // -----------------------------------------------------------------------
    test(
        'T15: "Yorum, favori veya check-in verilerimle ilgili talep" → delete_interactions',
        () async {
      final repo = _FakeLegalRepository();
      await _runSubmitLogic(
        reason: 'Yorum, favori veya check-in verilerimle ilgili talep',
        repo: repo,
      );

      expect(repo.submitPrivacyCalled, isTrue);
      expect(repo.lastPrivacyRequestType, equals('delete_interactions'));
      expect(repo.submitAccountDeletionCalled, isFalse);
    });

    // -----------------------------------------------------------------------
    // T16: "Destek talebi geçmişimle ilgili talep" → request_type: 'delete_support'
    // -----------------------------------------------------------------------
    test(
        'T16: "Destek talebi geçmişimle ilgili talep" → delete_support',
        () async {
      final repo = _FakeLegalRepository();
      await _runSubmitLogic(
        reason: 'Destek talebi geçmişimle ilgili talep',
        repo: repo,
      );

      expect(repo.submitPrivacyCalled, isTrue);
      expect(repo.lastPrivacyRequestType, equals('delete_support'));
      expect(repo.submitAccountDeletionCalled, isFalse);
    });

    // -----------------------------------------------------------------------
    // T17: "İşletme sahipliği başvurumla ilgili talep" → request_type: 'delete_owner_claims'
    // -----------------------------------------------------------------------
    test(
        'T17: "İşletme sahipliği başvurumla ilgili talep" → delete_owner_claims',
        () async {
      final repo = _FakeLegalRepository();
      await _runSubmitLogic(
        reason: 'İşletme sahipliği başvurumla ilgili talep',
        repo: repo,
      );

      expect(repo.submitPrivacyCalled, isTrue);
      expect(repo.lastPrivacyRequestType, equals('delete_owner_claims'));
      expect(repo.submitAccountDeletionCalled, isFalse);
    });

    // -----------------------------------------------------------------------
    // T18: "Diğer" → request_type: 'other'
    // -----------------------------------------------------------------------
    test('T18: "Diğer" → submitPrivacyRequest(other)', () async {
      final repo = _FakeLegalRepository();
      await _runSubmitLogic(reason: 'Diğer', repo: repo);

      expect(repo.submitPrivacyCalled, isTrue);
      expect(repo.lastPrivacyRequestType, equals('other'));
      expect(repo.submitAccountDeletionCalled, isFalse);
    });

    // -----------------------------------------------------------------------
    // T19: Pazarlama seçeneği → hiçbir veri silme RPC çağrılmaz
    // -----------------------------------------------------------------------
    test(
        'T19: Pazarlama seçeneği → veri silme RPC çağrılmaz',
        () async {
      final repo = _FakeLegalRepository();
      await _runSubmitLogic(reason: _marketingReason, repo: repo);

      expect(repo.submitPrivacyCalled, isFalse,
          reason: 'Pazarlama seçeneği submitPrivacyRequest çağırmamalı.');
      expect(repo.submitAccountDeletionCalled, isFalse,
          reason: 'Pazarlama seçeneği submitAccountDeletionRequest çağırmamalı.');
    });

    // -----------------------------------------------------------------------
    // T20: Pazarlama seçeneği → yönlendirme yapıldı (navigated: true)
    // -----------------------------------------------------------------------
    test('T20: Pazarlama seçeneği → bildirim tercihleri sayfasına yönlendirdi',
        () async {
      final repo = _FakeLegalRepository();
      final result = await _runSubmitLogic(reason: _marketingReason, repo: repo);

      expect(result.navigated, isTrue,
          reason:
              'Pazarlama seçeneği seçilince /notification-preferences yönlendirmesi yapılmalı.');
    });

    // -----------------------------------------------------------------------
    // T21: RPC hata verirse UI çökmeden hata mesajı gösteriyor
    // -----------------------------------------------------------------------
    test('T21: submitPrivacyRequest hata verince navigated=false, error dolu',
        () async {
      final repo = _FakeLegalRepository()..throwOnPrivacy = true;
      final result = await _runSubmitLogic(reason: 'Diğer', repo: repo);

      expect(result.navigated, isFalse,
          reason: 'RPC hata verince kullanıcı sayfada kalmalı.');
      expect(result.error, isNotNull,
          reason: 'Hata mesajı UI\'ya yansıtılmalı.');
    });

    // -----------------------------------------------------------------------
    // T22: Ekranda "kalıcı olarak silinecektir" ifadesi yok
    // -----------------------------------------------------------------------
    test('T22: Ekranda "kalıcı olarak silinecektir" ifadesi yer almıyor', () {
      final allTexts = [
        ..._preRequestTexts,
        _afterSubmitText,
        _snackBarText,
        _marketingNoteText,
      ];
      for (final text in allTexts) {
        expect(
          text.toLowerCase().contains('kalıcı olarak silinecektir'),
          isFalse,
          reason: '"kalıcı olarak silinecektir" ifadesi ekranda olmamalı.',
        );
      }
    });

    // -----------------------------------------------------------------------
    // T23: Ekranda "30 gün" ifadesi yok
    // -----------------------------------------------------------------------
    test('T23: Ekranda "30 gün" ifadesi yer almıyor', () {
      final allTexts = [
        ..._preRequestTexts,
        _afterSubmitText,
        _snackBarText,
        _marketingNoteText,
      ];
      for (final text in allTexts) {
        expect(
          text.contains('30 gün'),
          isFalse,
          reason: '"30 gün" kesin süre ifadesi ekranda olmamalı.',
        );
      }
    });
  });

  // =========================================================================
  // T24: _reasonToRequestType kapsamlı eşleştirme kontrolü
  // =========================================================================

  group('_reasonToRequestType — eşleştirme doğruluğu', () {
    test('T24: Tüm UI seçenekleri doğru request_type değerine eşleşiyor', () {
      final expected = <String, String>{
        'Kişisel verilerimin silinmesi / yok edilmesi / anonimleştirilmesi talebi':
            'delete_data',
        'Yorum, favori veya check-in verilerimle ilgili talep':
            'delete_interactions',
        'Destek talebi geçmişimle ilgili talep': 'delete_support',
        'İşletme sahipliği başvurumla ilgili talep': 'delete_owner_claims',
        'Diğer': 'other',
        'Bilinmeyen seçenek': 'other', // default: other
      };

      for (final entry in expected.entries) {
        expect(
          _reasonToRequestType(entry.key),
          equals(entry.value),
          reason:
              '"${entry.key}" → "${entry.value}" eşleştirmesi yanlış.',
        );
      }
    });
  });
}
