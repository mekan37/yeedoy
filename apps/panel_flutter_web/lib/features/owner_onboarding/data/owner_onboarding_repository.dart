import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../domain/owner_onboarding_models.dart';

class OwnerOnboardingRepository {
  OwnerOnboardingRepository(this.client);
  final SupabaseClient client;

  Future<OwnerOnboardingProgress> getProgress(String businessId) async {
    try {
      final res = await client.rpc('get_owner_onboarding_progress_v1', params: {
        'p_business_id': businessId,
      });
      if (res is List && res.isNotEmpty && res.first is Map) {
        final data = (res.first as Map).cast<String, dynamic>();
        return OwnerOnboardingProgress(
          stepCompleted: (data['step_completed'] as num?)?.toInt() ?? 0,
          updatedAt: DateTime.tryParse((data['updated_at'] ?? '').toString()),
        );
      }
      return const OwnerOnboardingProgress(stepCompleted: 0, updatedAt: null);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> setProgress(String businessId, int stepCompleted) async {
    try {
      final res = await client.rpc('owner_set_onboarding_progress_v1', params: {
        'p_business_id': businessId,
        'p_step_completed': stepCompleted,
      });
      if (res is Map) {
        final ok = (res['ok'] as bool?) ?? false;
        if (!ok) {
          throw Exception((res['message'] ?? res['code'] ?? 'Bilinmeyen hata').toString());
        }
        return;
      }
      throw Exception('Kurulum güncellenemedi');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<OwnerBusinessProfile> getBusinessProfile(String businessId) async {
    try {
      final res = await client
          .from('businesses')
          .select('logo_url,cover_url')
          .eq('id', businessId)
          .maybeSingle();
      final data = (res as Map?)?.cast<String, dynamic>() ?? const {};
      return OwnerBusinessProfile(
        logoUrl: (data['logo_url'] ?? '').toString(),
        coverUrl: (data['cover_url'] ?? '').toString(),
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> updateBusinessProfile({
    required String businessId,
    required String logoUrl,
    required String coverUrl,
  }) async {
    try {
      final res = await client.rpc('owner_update_business_profile_v1', params: {
        'p_business_id': businessId,
        'p_logo_url': logoUrl,
        'p_cover_url': coverUrl,
      });
      if (res is Map) {
        final ok = (res['ok'] as bool?) ?? false;
        if (!ok) {
          throw Exception((res['message'] ?? res['code'] ?? 'Bilinmeyen hata').toString());
        }
      }
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<OwnerBusinessHours?> getBusinessHours(String businessId) async {
    try {
      final res = await client
          .from('business_hours')
          .select('mon_open,mon_close')
          .eq('business_id', businessId)
          .maybeSingle();
      if (res == null) return null;
      final data = (res as Map).cast<String, dynamic>();
      return OwnerBusinessHours(
        openTime: _asTimeString(data['mon_open']),
        closeTime: _asTimeString(data['mon_close']),
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> upsertBusinessHours({
    required String businessId,
    required String openTime,
    required String closeTime,
  }) async {
    try {
      final res = await client.rpc('owner_upsert_business_hours_v1', params: {
        'p_business_id': businessId,
        'p_open': openTime,
        'p_close': closeTime,
      });
      if (res is Map) {
        final ok = (res['ok'] as bool?) ?? false;
        if (!ok) {
          throw Exception((res['message'] ?? res['code'] ?? 'Bilinmeyen hata').toString());
        }
      }
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<OwnerOnboardingMenuStatus> getMenuStatus(String businessId) async {
    try {
      final menusRes = await client
          .from('menus')
          .select('id,title')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      final menus = (menusRes as List?)?.whereType<Map>().toList() ?? const [];
      if (menus.isEmpty) {
        return const OwnerOnboardingMenuStatus(
          menuCount: 0,
          sectionCount: 0,
          itemCount: 0,
          primaryMenuId: null,
          primaryMenuTitle: null,
        );
      }

      var sectionCount = 0;
      var itemCount = 0;

      for (final menu in menus) {
        final menuId = (menu['id'] ?? '').toString();
        if (menuId.isEmpty) continue;
        final sectionsRes = await client.rpc('get_menu_sections_v1', params: {
          'p_menu_id': menuId,
        });
        final sections = (sectionsRes as List?)?.whereType<Map>().toList() ?? const [];
        if (sections.isEmpty) continue;
        sectionCount += sections.length;

        for (final section in sections) {
          final sectionId = (section['id'] ?? '').toString();
          if (sectionId.isEmpty) continue;
          final itemsRes = await client.rpc('get_menu_items_v2', params: {
            'p_section_id': sectionId,
            'p_limit': 1,
            'p_offset': 0,
          });
          final items = (itemsRes as List?)?.whereType<Map>().toList() ?? const [];
          if (items.isNotEmpty) {
            itemCount += items.length;
            return OwnerOnboardingMenuStatus(
              menuCount: menus.length,
              sectionCount: sectionCount,
              itemCount: itemCount,
              primaryMenuId: (menus.first['id'] ?? '').toString(),
              primaryMenuTitle: (menus.first['title'] ?? '').toString(),
            );
          }
        }
      }

      return OwnerOnboardingMenuStatus(
        menuCount: menus.length,
        sectionCount: sectionCount,
        itemCount: itemCount,
        primaryMenuId: (menus.first['id'] ?? '').toString(),
        primaryMenuTitle: (menus.first['title'] ?? '').toString(),
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<OwnerOnboardingMenuPreview?> getMenuPreview(String businessId) async {
    try {
      final menusRes = await client
          .from('menus')
          .select('id,title')
          .eq('business_id', businessId)
          .order('created_at', ascending: false)
          .limit(1);
      final menus = (menusRes as List?)?.whereType<Map>().toList() ?? const [];
      if (menus.isEmpty) return null;
      final menuId = (menus.first['id'] ?? '').toString();
      final menuTitle = (menus.first['title'] ?? '').toString();
      if (menuId.isEmpty) return null;

      final sectionsRes = await client.rpc('get_menu_sections_v1', params: {
        'p_menu_id': menuId,
      });
      final sections = (sectionsRes as List?)?.whereType<Map>().toList() ?? const [];
      final resultSections = <OwnerOnboardingMenuSection>[];

      for (final section in sections) {
        final sectionId = (section['id'] ?? '').toString();
        if (sectionId.isEmpty) continue;
        final itemsRes = await client.rpc('get_menu_items_v2', params: {
          'p_section_id': sectionId,
          'p_limit': 200,
          'p_offset': 0,
        });
        final items = (itemsRes as List?)?.whereType<Map>().toList() ?? const [];
        resultSections.add(
          OwnerOnboardingMenuSection(
            id: sectionId,
            title: (section['title'] ?? '').toString(),
            items: items
                .map(
                  (item) => OwnerOnboardingMenuItem(
                    name: (item['name'] ?? '').toString(),
                    description: (item['description'] ?? '').toString(),
                    priceCents: (item['price_cents'] as num?)?.toInt(),
                    currency: (item['currency'] ?? '').toString(),
                  ),
                )
                .toList(),
          ),
        );
      }

      return OwnerOnboardingMenuPreview(
        menuId: menuId,
        menuTitle: menuTitle,
        sections: resultSections,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<OwnerBusinessProfileScore> getProfileScore(String businessId) async {
    try {
      final res = await client.rpc('get_business_profile_score_v1', params: {
        'p_business_id': businessId,
      });
      final data = (res as Map).cast<String, dynamic>();
      return OwnerBusinessProfileScore(
        score: (data['score'] as num?)?.toInt() ?? 0,
        breakdown: (data['breakdown'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

String? _asTimeString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return text;
}



