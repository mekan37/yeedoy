import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/suggestion.dart';

final suggestionsRepositoryProvider = Provider<SuggestionsRepository>((ref) {
  return SuggestionsRepository(ref.watch(supabaseProvider));
});

class SuggestionsRepository {
  SuggestionsRepository(this.client);
  final SupabaseClient client;

  Future<String> submit({
    required String name,
    required String category,
    String? city,
    String? district,
    String? address,
    String? phone,
    String? website,
    String? notes,
  }) async {
    final res = await client.rpc(
      'submit_business_suggestion',
      params: {
        'p_name': name,
        'p_category': category,
        'p_city': city,
        'p_district': district,
        'p_address': address,
        'p_phone': phone,
        'p_website': website,
        'p_notes': notes,
      },
    );

    return res.toString(); // uuid string
  }

  Future<List<BusinessSuggestion>> listMySuggestions() async {
    final res = await client
        .from('business_suggestions')
        .select(
          'id,name,category,status,created_at,city,district,admin_note,approved_business_id',
        )
        .order('created_at', ascending: false);

    return (res as List).map((e) => BusinessSuggestion.fromMap(e)).toList();
  }

  Future<List<BusinessSuggestion>> getMySuggestions({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final List<dynamic> res = await client
          .from('business_suggestions')
          .select(
            'id,name,category,status,created_at,city,district,admin_note,approved_business_id',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return res
          .whereType<Map>()
          .map((m) => BusinessSuggestion.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<ExistingBusinessCandidate>> findPossibleExisting({
    required String name,
    String? city,
    String? district,
    String? address,
    int limit = 6,
  }) async {
    if (name.trim().length < 3) return const [];

    var q = client
        .from('businesses')
        .select('id,name,address,city,district')
        .ilike('name', '%${name.trim()}%');

    final cityTrim = (city ?? '').trim();
    final districtTrim = (district ?? '').trim();
    if (cityTrim.isNotEmpty) q = q.eq('city', cityTrim);
    if (districtTrim.isNotEmpty) q = q.eq('district', districtTrim);

    final res = await q.limit(limit);
    final rows = (res as List?) ?? const [];
    final all = rows
        .whereType<Map>()
        .map(
          (e) => ExistingBusinessCandidate.fromMap(e.cast<String, dynamic>()),
        )
        .toList();
    final addressTrim = (address ?? '').trim().toLowerCase();
    if (addressTrim.isEmpty) return all;
    all.sort((a, b) {
      final aScore = a.address.toLowerCase().contains(addressTrim) ? 1 : 0;
      final bScore = b.address.toLowerCase().contains(addressTrim) ? 1 : 0;
      return bScore.compareTo(aScore);
    });
    return all;
  }
}

class ExistingBusinessCandidate {
  const ExistingBusinessCandidate({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.district,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String district;

  factory ExistingBusinessCandidate.fromMap(Map<String, dynamic> map) {
    return ExistingBusinessCandidate(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
    );
  }
}
