import 'package:flutter/material.dart';
import 'package:yeedoy/core/i18n/app_localizations.dart';

import '../../../../../app/theme/colors.dart';
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
    final t = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        title: Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'SÄ±ra: ${section.sortOrder}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              onPressed: onOpenItems,
              icon: const Icon(Icons.list_alt_outlined),
              tooltip: 'Urunler',
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: t.duzenle,
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }
}

