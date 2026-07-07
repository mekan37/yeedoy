import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yeedoy/features/profile/domain/achievement.dart';

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

LinearGradient medalGradient(String tier) {
  switch (tier) {
    case 'gold':
      return const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFB8860B), Color(0xFFFFD700)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case 'silver':
      return const LinearGradient(
        colors: [Color(0xFFE8E8E8), Color(0xFF9E9E9E), Color(0xFFE8E8E8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case 'special':
      return const LinearGradient(
        colors: [Color(0xFF9C27B0), Color(0xFF4A148C), Color(0xFF9C27B0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    default:
      return const LinearGradient(
        colors: [Color(0xFFCD7F32), Color(0xFF8B4513), Color(0xFFCD7F32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  }
}

class AchievementMedalWidget extends StatelessWidget {
  const AchievementMedalWidget({
    super.key,
    required this.achievement,
    this.size = 56.0,
    this.showLabel = false,
  });

  final Achievement achievement;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final gradient = medalGradient(achievement.tier);
    final visual = _achievementVisualById[achievement.id];
    final iconWidget = visual != null
        ? FaIcon(visual.icon, size: size * 0.55, color: Colors.white)
        : Icon(Icons.emoji_events, size: size * 0.55, color: Colors.white);

    final medal = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: iconWidget),
    );

    if (!showLabel) return medal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        medal,
        const SizedBox(height: 4),
        SizedBox(
          width: size + 8,
          child: Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
