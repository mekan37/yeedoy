import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yeedoy/core/ceviri/uygulama_yerellesmeleri.dart';

import '../../../../uygulama/tema/renkler.dart';
import '../../../../features/shared/ui/basarilar/basari_gorselleri.dart';
import '../../domain/basari.dart';

class AchievementsGrid extends StatelessWidget {
  const AchievementsGrid({super.key, required this.items});

  final List<Achievement> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 360 ? 3 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) => _AchievementTile(item: items[index]),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.item});

  final Achievement item;

  @override
  Widget build(BuildContext context) {
    final visual = appAchievementVisualForId(
      item.id,
      fallbackHex: item.colorHex,
    );
    final unlocked = item.unlocked;
    final iconColor = unlocked ? visual.color : AppColors.muted;

    return Tooltip(
      message: item.description,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context, item, visual.color),
        child: AnimatedOpacity(
          opacity: unlocked ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 180),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 52,
                  width: 52,
                  child: Center(
                    child: FaIcon(
                      unlocked ? visual.icon : FontAwesomeIcons.lock,
                      color: iconColor,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                if ((item.targetValue ?? 0) > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${item.currentValue ?? 0}/${item.targetValue}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showDetails(BuildContext context, Achievement item, Color color) {
  final t = AppLocalizations.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              item.description,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  item.unlocked ? t.achievementStatusUnlocked : t.achievementStatusLocked,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  t.inboxXpGain(item.xp),
                  style: TextStyle(fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}




