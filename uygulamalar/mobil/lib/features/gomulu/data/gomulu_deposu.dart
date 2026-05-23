import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ag/supabase_saglayicisi.dart';

final embedRepositoryProvider = Provider<EmbedRepository>((ref) {
  return EmbedRepository(ref.watch(supabaseProvider));
});

final freshEmbedsProvider = FutureProvider.family<List<Embed>, int>((
  ref,
  limit,
) {
  return ref
      .watch(embedRepositoryProvider)
      .listFreshEmbedsNearbyOrRecent(limit: limit);
});

class EmbedRepository {
  EmbedRepository(this._client);

  final SupabaseClient _client;

  Future<void> addEmbed({
    required String ownerType,
    required String ownerId,
    required String urlRaw,
    required String urlNormalized,
    required String provider,
    String? title,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('auth_required');
    }
    await _client.from('embeds').insert({
      'owner_type': ownerType,
      'owner_id': ownerId,
      'provider': provider,
      'url_raw': urlRaw,
      'url_normalized': urlNormalized,
      'title': title,
      'created_by': userId,
    });
  }

  Future<List<Embed>> listEmbedsForOwner(
    String ownerType,
    String ownerId, {
    int limit = 20,
  }) async {
    final rows = await _client
        .from('embeds')
        .select(
          'id,provider,url_normalized,title,thumbnail_url,created_at,owner_type',
        )
        .eq('owner_type', ownerType)
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false)
        .limit(limit);
    return ((rows as List?) ?? const [])
        .whereType<Map>()
        .map((row) => Embed.fromMap(row.cast<String, dynamic>()))
        .toList();
  }

  Future<List<Embed>> listFreshEmbedsNearbyOrRecent({int limit = 20}) async {
    final rows = await _client
        .from('embeds')
        .select(
          'id,provider,url_normalized,title,thumbnail_url,created_at,owner_type',
        )
        .order('created_at', ascending: false)
        .limit(limit);
    return ((rows as List?) ?? const [])
        .whereType<Map>()
        .map((row) => Embed.fromMap(row.cast<String, dynamic>()))
        .toList();
  }
}

class Embed {
  const Embed({
    required this.id,
    required this.provider,
    required this.urlNormalized,
    required this.title,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.ownerType,
  });

  final String id;
  final String provider;
  final String urlNormalized;
  final String? title;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final String ownerType;

  factory Embed.fromMap(Map<String, dynamic> map) {
    return Embed(
      id: (map['id'] ?? '').toString(),
      provider: (map['provider'] ?? 'unknown').toString(),
      urlNormalized: (map['url_normalized'] ?? '').toString(),
      title: map['title']?.toString(),
      thumbnailUrl: map['thumbnail_url']?.toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      ownerType: (map['owner_type'] ?? 'user').toString(),
    );
  }
}
