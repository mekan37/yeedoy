import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy/core/content/content_moderation.dart';
import 'package:yeedoy/core/content/moderation_blacklist_repository.dart';
import 'package:yeedoy/core/storage/local_db/memory_local_db_store.dart';

/// `configureRepository` çağrılmadan önce zaten enjekte edilmiş gibi
/// davranan sahte repository — gerçek Supabase/ağ çağrısı yapmaz.
class _FakeModerationBlacklistRepository extends ModerationBlacklistRepository {
  _FakeModerationBlacklistRepository(this._terms)
    : super(
        SupabaseClient(
          'http://localhost:54321',
          'fake-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
        MemoryLocalDbStore(),
      );

  final List<String> _terms;

  @override
  Future<List<String>> fetchTerms() async => _terms;
}

void main() {
  group('blacklistMatches', () {
    test('detects a blacklisted term regardless of case and spacing', () {
      expect(blacklistMatches('Bu bir SIKTIR yorumu', ['siktir']), isTrue);
      expect(blacklistMatches('bu s i k t i r yorumu', ['siktir']), isTrue);
    });

    test('does not flag clean text', () {
      expect(
        blacklistMatches('gayet güzel bir mekan', ['siktir', 'amk']),
        isFalse,
      );
    });

    test('handles an empty blacklist safely', () {
      expect(blacklistMatches('herhangi bir metin', const []), isFalse);
    });

    test('matches obfuscated variants via normalization', () {
      expect(blacklistMatches('4mk yorumu', ['amk']), isTrue);
    });
  });

  group('ContentModeration.validateReview', () {
    test('rejects content shorter than minimum length', () async {
      final result = await ContentModeration.instance.validateReview(
        content: 'kisa',
      );
      expect(result, isNotNull);
      expect(result!.code, 'content_too_short');
    });
  });

  group('ContentModeration blacklist cache', () {
    tearDown(ContentModeration.resetForTesting);

    test(
      'blacklist call before configureRepository does not permanently '
      'poison the cache with an empty result',
      () async {
        // Repository henüz configureRepository() ile ayarlanmadı. Bu çağrı
        // _loadBlacklist -> _fetchBlacklist yolunu repository=null iken
        // tetikler; eski davranışta bu, boş sonucu statik cache'e kalıcı
        // olarak yazardı ve aşağıdaki configureRepository çağrısı hiçbir
        // zaman etkili olmazdı.
        final beforeConfigure = await ContentModeration.instance
            .validateReview(content: 'gayet güzel bir mekan burada');
        expect(beforeConfigure, isNull);

        // "gizliterim" ayarlanan sözlük dışında hiçbir statik kural
        // (_containsObfuscatedProfanity, link/telefon, emoji spam vb.)
        // tarafından yakalanmaz — bu yüzden yalnızca repository'den gelen
        // kara liste devrede olduğunda tespit edilebilir.
        ContentModeration.instance.configureRepository(
          _FakeModerationBlacklistRepository(const ['gizliterim']),
        );

        final afterConfigure = await ContentModeration.instance
            .validateReview(content: 'bu yorumda gizliterim kelimesi var');
        expect(afterConfigure, isNotNull);
        expect(afterConfigure!.code, 'contains_profanity');
      },
    );
  });
}
