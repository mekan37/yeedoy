import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_provider.dart';
import '../storage/local_db/local_db_models.dart';
import '../storage/local_db/local_db_provider.dart';
import '../storage/local_db/local_db_store.dart';

final moderationBlacklistRepositoryProvider =
    Provider<ModerationBlacklistRepository>((ref) {
      return ModerationBlacklistRepository(
        ref.watch(supabaseProvider),
        ref.watch(localDbStoreProvider),
      );
    });

class ModerationBlacklistRepository {
  ModerationBlacklistRepository(this.client, this._localDb);

  final SupabaseClient client;
  final LocalDbStore _localDb;

  static const String _cacheId = 'terms';
  static const Duration _cacheTtl = Duration(hours: 24);

  /// Sunucudan kara liste terimlerini çeker; başarısız olursa (offline vb.)
  /// en son önbelleklenen listeyi (süresi geçmiş olsa dahi) döner, o da yoksa
  /// boş liste döner — çağıran taraf bunu "ön-kontrol atlanabilir" olarak
  /// yorumlamalı, hata fırlatılmaz.
  Future<List<String>> fetchTerms() async {
    try {
      final fresh = await _readCache(allowExpired: false);
      if (fresh != null) return fresh;

      final res = await client.rpc('get_moderation_blacklist_terms_v1');
      final terms = (res as List)
          .whereType<Map>()
          .map((row) => (row['term'] ?? '').toString())
          .where((term) => term.isNotEmpty)
          .toList(growable: false);
      await _localDb.upsert(
        bucket: LocalDbBucket.moderationBlacklist,
        id: _cacheId,
        payload: <String, dynamic>{'terms': terms},
        expiresAt: DateTime.now().toUtc().add(_cacheTtl),
      );
      return terms;
    } catch (_) {
      try {
        final stale = await _readCache(allowExpired: true);
        return stale ?? const [];
      } catch (_) {
        return const [];
      }
    }
  }

  Future<List<String>?> _readCache({required bool allowExpired}) async {
    final record = await _localDb.read(
      LocalDbBucket.moderationBlacklist,
      _cacheId,
      allowExpired: allowExpired,
    );
    final terms = record?.payload['terms'];
    if (terms is! List) return null;
    return terms.map((e) => e.toString()).toList(growable: false);
  }
}
