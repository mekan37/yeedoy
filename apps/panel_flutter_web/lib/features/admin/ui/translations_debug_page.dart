import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../l10n/translation_catalog.dart';

class TranslationsDebugPage extends StatefulWidget {
  const TranslationsDebugPage({super.key});

  @override
  State<TranslationsDebugPage> createState() => _TranslationsDebugPageState();
}

class _TranslationsDebugPageState extends State<TranslationsDebugPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final entries = TRANSLATIONS.entries.where((entry) {
      if (query.isEmpty) return true;
      final key = entry.key.toLowerCase();
      final tr = (entry.value['tr'] ?? '').toLowerCase();
      final en = (entry.value['en'] ?? '').toLowerCase();
      return key.contains(query) || tr.contains(query) || en.contains(query);
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(title: const Text('Translations')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search key or value',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final tr = entry.value['tr'] ?? '';
                final en = entry.value['en'] ?? '';
                final missingEn = en.trim().isEmpty;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textStrong,
                                ),
                              ),
                            ),
                            if (missingEn)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: const Text(
                                  'Missing EN',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'tr: $tr',
                          style: const TextStyle(color: AppColors.textStrong),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'en: ${en.isEmpty ? '-' : en}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
