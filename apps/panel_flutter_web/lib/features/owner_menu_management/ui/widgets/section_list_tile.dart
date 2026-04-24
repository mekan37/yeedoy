import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../domain/owner_menu_models.dart';

class SectionListTile extends StatelessWidget {
  const SectionListTile({
    super.key,
    required this.section,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenItems,
  });

  final OwnerMenuSection section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppColors.primary.withValues(alpha: 0.3)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.list_alt_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              section.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textStrong,
                              ),
                            ),
                            Text(
                              context.l10n.ownerSortOrder(section.sortOrder),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          _ActionBtn(
                            icon: Icons.format_list_bulleted_outlined,
                            tooltip: context.l10n.ownerProducts,
                            onTap: onOpenItems,
                            filled: true,
                          ),
                          _ActionBtn(
                            icon: Icons.edit_outlined,
                            tooltip: context.l10n.duzenle,
                            onTap: onEdit,
                          ),
                          _ActionBtn(
                            icon: Icons.delete_outline,
                            tooltip: context.l10n.ownerDelete,
                            onTap: onDelete,
                            danger: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : (filled ? AppColors.primary : AppColors.muted);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: filled
                ? AppColors.primarySoft
                : (danger ? AppColors.danger.withValues(alpha: 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}
