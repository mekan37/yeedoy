import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/app_tokens.dart';

/// Pill-style segmented tab bar driven by [DefaultTabController].
///
/// Active tab gets a card-colored background, a 2px primary bottom
/// border, and primary text; inactive tabs are muted on transparent.
class AppSegmentedTabBar extends StatelessWidget {
  const AppSegmentedTabBar({
    super.key,
    required this.labels,
    this.selectedIndex,
    this.onTap,
  });

  final List<String> labels;
  final int? selectedIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final controller = selectedIndex == null
        ? DefaultTabController.of(context)
        : null;
    return Container(
      padding: EdgeInsets.all(tokens.space4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(tokens.radius12),
      ),
      child: AnimatedBuilder(
        animation: controller ?? kAlwaysDismissedAnimation,
        builder: (context, _) {
          final activeIndex = selectedIndex ?? controller!.index;
          return Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (onTap != null) {
                        onTap!(i);
                      } else {
                        controller!.animateTo(i);
                      }
                    },
                    child: AnimatedContainer(
                      duration: tokens.fast,
                      padding: EdgeInsets.symmetric(vertical: tokens.space8),
                      decoration: BoxDecoration(
                        color: activeIndex == i
                            ? AppColors.card
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(tokens.radius12),
                        border: Border(
                          bottom: BorderSide(
                            color: activeIndex == i
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: activeIndex == i
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
