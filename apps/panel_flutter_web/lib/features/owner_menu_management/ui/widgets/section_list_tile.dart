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
    return Card(
      child: ListTile(
        title: Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          context.l10n.ownerSortOrder(section.sortOrder),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              onPressed: onOpenItems,
              icon: const Icon(Icons.list_alt_outlined),
              tooltip: context.l10n.ownerProducts,
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.l10n.duzenle,
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: context.l10n.ownerDelete,
            ),
          ],
        ),
      ),
    );
  }
}

