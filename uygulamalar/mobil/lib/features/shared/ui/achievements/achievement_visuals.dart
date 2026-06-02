import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppAchievementVisual {
  const AppAchievementVisual({required this.icon, required this.color});

  final FaIconData icon;
  final Color color;
}

const Map<String, AppAchievementVisual> _achievementVisualById = {
  'first_review': AppAchievementVisual(
    icon: FontAwesomeIcons.comment,
    color: Color(0xFF4CAF50),
  ),
  'first_rating': AppAchievementVisual(
    icon: FontAwesomeIcons.star,
    color: Color(0xFFFBC02D),
  ),
  'first_discovery': AppAchievementVisual(
    icon: FontAwesomeIcons.locationDot,
    color: Color(0xFF039BE5),
  ),
  'traveler_10': AppAchievementVisual(
    icon: FontAwesomeIcons.compass,
    color: Color(0xFF00897B),
  ),
  'district_gourmet_top10': AppAchievementVisual(
    icon: FontAwesomeIcons.crown,
    color: Color(0xFFFF6F00),
  ),
  'price_hunter_5': AppAchievementVisual(
    icon: FontAwesomeIcons.tags,
    color: Color(0xFF2E7D32),
  ),
  'pizza_master_10': AppAchievementVisual(
    icon: FontAwesomeIcons.pizzaSlice,
    color: Color(0xFFF57C00),
  ),
  'observer_3': AppAchievementVisual(
    icon: FontAwesomeIcons.eye,
    color: Color(0xFF4527A0),
  ),
  'detective_10': AppAchievementVisual(
    icon: FontAwesomeIcons.pen,
    color: Color(0xFF6A1B9A),
  ),
  'trusted_contributor': AppAchievementVisual(
    icon: FontAwesomeIcons.shieldHalved,
    color: Color(0xFF0D47A1),
  ),
  'silent_follower_20': AppAchievementVisual(
    icon: FontAwesomeIcons.userSecret,
    color: Color(0xFF37474F),
  ),
  'night_gourmet_5': AppAchievementVisual(
    icon: FontAwesomeIcons.moon,
    color: Color(0xFF283593),
  ),
  'menu_archivist_1': AppAchievementVisual(
    icon: FontAwesomeIcons.receipt,
    color: Color(0xFF5E35B1),
  ),
  'chance_hunter_10': AppAchievementVisual(
    icon: FontAwesomeIcons.compass,
    color: Color(0xFFF9A825),
  ),
  'weekend_wanderer_8': AppAchievementVisual(
    icon: FontAwesomeIcons.map,
    color: Color(0xFF5D4037),
  ),
  'deep_menu_diver_30': AppAchievementVisual(
    icon: FontAwesomeIcons.store,
    color: Color(0xFF6D4C41),
  ),
  'combo_price_streak_3': AppAchievementVisual(
    icon: FontAwesomeIcons.fire,
    color: Color(0xFFE53935),
  ),
  'combo_district_master_5': AppAchievementVisual(
    icon: FontAwesomeIcons.map,
    color: Color(0xFF5D4037),
  ),
  'combo_full_contributor': AppAchievementVisual(
    icon: FontAwesomeIcons.bolt,
    color: Color(0xFFFDD835),
  ),
};

AppAchievementVisual appAchievementVisualForId(
  String achievementId, {
  String? fallbackHex,
}) {
  return _achievementVisualById[achievementId] ??
      AppAchievementVisual(
        icon: FontAwesomeIcons.award,
        color: _hexToColor(fallbackHex),
      );
}

Color _hexToColor(String? raw) {
  final text = (raw ?? '').replaceAll('#', '').trim();
  if (text.length != 6) return const Color(0xFF9CA3AF);
  final value = int.tryParse('FF$text', radix: 16);
  if (value == null) return const Color(0xFF9CA3AF);
  return Color(value);
}
