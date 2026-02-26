import 'package:flutter/material.dart';
import 'package:yeedoy/core/i18n/app_localizations.dart';

import '../../../../app/theme/colors.dart';
import '../../../../features/shared/ui/design_system.dart';

class CategoryQuickFilterItem {
  const CategoryQuickFilterItem({
    required this.id,
    required this.title,
    required this.imageAsset,
  });

  final String id;
  final String title;
  final String imageAsset;
}

enum CategoryQuickFiltersLayout { horizontal, grid2x4 }

class CategoryQuickFilters extends StatelessWidget {
  const CategoryQuickFilters({
    super.key,
    required this.items,
    required this.onTap,
    this.layout = CategoryQuickFiltersLayout.horizontal,
    this.title,
  });

  final List<CategoryQuickFilterItem> items;
  final ValueChanged<CategoryQuickFilterItem> onTap;
  final CategoryQuickFiltersLayout layout;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final visible = items.take(12).toList();
    final resolvedTitle = title ?? AppLocalizations.of(context).quickShortcuts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: resolvedTitle),
        const SizedBox(height: 8),
        if (layout == CategoryQuickFiltersLayout.grid2x4)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.take(8).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final item = visible[index];
              return _CategoryCard(item: item, onTap: () => onTap(item));
            },
          )
        else
          SizedBox(
            height: 136,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = visible[index];
                return SizedBox(
                  width: 116,
                  child: _CategoryCard(item: item, onTap: () => onTap(item)),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.item, required this.onTap});

  final CategoryQuickFilterItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Image.asset(
                item.imageAsset,
                fit: BoxFit.cover,
                cacheWidth: 360,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.card,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.restaurant_menu_outlined,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

