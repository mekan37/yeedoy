import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import '../domain/yemek_gunlugu_bildiricisi.dart';
import '../domain/yemek_gunlugu_modeli.dart';

class YemekGunluguSayfasi extends ConsumerWidget {
  const YemekGunluguSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(yemekGunluguProvider);
    return AppScaffold(
      appBar: AppAppBar(
        title: Text(context.l10n.yemekGunluguPageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: context.l10n.yemekGunluguReminderTooltip,
            onPressed: () => _showHatirlaticiSheet(context),
          ),
        ],
      ),
      body: journalAsync.when(
        loading: () => const _JournalSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppErrorMapper.message(e),
                style: const TextStyle(color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(yemekGunluguProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.yemekGunluguRetryButton),
              ),
            ],
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return AppEmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: context.l10n.yemekGunluguEmptyTitle,
              description: context.l10n.yemekGunluguEmptyDescription,
            );
          }
          final grouped = _groupByDate(context, entries);
          return RefreshIndicator(
            onRefresh: () => ref.read(yemekGunluguProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final group = grouped[index];
                return _DateGroup(
                  dateLabel: group.dateLabel,
                  entries: group.entries,
                  onTapEntry: (entry) => _showEditSheet(context, ref, entry),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showHatirlaticiSheet(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('yg_reminder_enabled') ?? false;
    final saat = prefs.getInt('yg_reminder_hour') ?? 20;
    final dakika = prefs.getInt('yg_reminder_minute') ?? 0;

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _HatirlaticiSheet(
        enabled: enabled,
        saat: saat,
        dakika: dakika,
        onSave: (en, s, d) async {
          await prefs.setBool('yg_reminder_enabled', en);
          await prefs.setInt('yg_reminder_hour', s);
          await prefs.setInt('yg_reminder_minute', d);
          if (ctx.mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  en
                      ? ctx.l10n.yemekGunluguReminderSetSnackbar(
                          '${s.toString().padLeft(2, '0')}:${d.toString().padLeft(2, '0')}',
                        )
                      : ctx.l10n.yemekGunluguReminderOffSnackbar,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  List<_DateGroupData> _groupByDate(
    BuildContext context,
    List<YemekGunluguKaydi> entries,
  ) {
    final map = <String, List<YemekGunluguKaydi>>{};
    final order = <String>[];
    for (final e in entries) {
      final label = _formatDate(context, e.checkedInAt);
      if (!map.containsKey(label)) {
        map[label] = [];
        order.add(label);
      }
      map[label]!.add(e);
    }
    return order
        .map((label) => _DateGroupData(dateLabel: label, entries: map[label]!))
        .toList();
  }

  String _formatDate(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return context.l10n.yemekGunluguToday;
    if (diff == 1) return context.l10n.yemekGunluguYesterday;
    final months = [
      context.l10n.yemekGunluguMonthJanuary,
      context.l10n.yemekGunluguMonthFebruary,
      context.l10n.yemekGunluguMonthMarch,
      context.l10n.yemekGunluguMonthApril,
      context.l10n.yemekGunluguMonthMay,
      context.l10n.yemekGunluguMonthJune,
      context.l10n.yemekGunluguMonthJuly,
      context.l10n.yemekGunluguMonthAugust,
      context.l10n.yemekGunluguMonthSeptember,
      context.l10n.yemekGunluguMonthOctober,
      context.l10n.yemekGunluguMonthNovember,
      context.l10n.yemekGunluguMonthDecember,
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    YemekGunluguKaydi entry,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => _EditSheet(
        entry: entry,
        onSave: (amountCents, note, rating) async {
          Navigator.of(sheetCtx).pop();
          await ref
              .read(yemekGunluguProvider.notifier)
              .guncelle(
                visitId: entry.visitId,
                amountCents: amountCents,
                note: note,
                rating: rating,
              );
        },
      ),
    );
  }
}

class _DateGroupData {
  const _DateGroupData({required this.dateLabel, required this.entries});
  final String dateLabel;
  final List<YemekGunluguKaydi> entries;
}

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.dateLabel,
    required this.entries,
    required this.onTapEntry,
  });

  final String dateLabel;
  final List<YemekGunluguKaydi> entries;
  final void Function(YemekGunluguKaydi) onTapEntry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            dateLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.muted,
            ),
          ),
        ),
        for (final entry in entries) ...[
          RepaintBoundary(
            child: _JournalEntryTile(
              entry: entry,
              onTap: () => onTapEntry(entry),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _JournalEntryTile extends StatelessWidget {
  const _JournalEntryTile({required this.entry, required this.onTap});

  final YemekGunluguKaydi entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(entry.checkedInAt);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.businessName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.category} • $timeStr',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (entry.amountCents != null) ...[
                Text(
                  _formatPrice(entry.amountCents!, entry.currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ],
          ),
          if (entry.personalRating != null) ...[
            const SizedBox(height: 6),
            _StarRow(rating: entry.personalRating!),
          ],
          if ((entry.personalNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.personalNote!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              context.l10n.yemekGunluguEditLabel,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatPrice(int cents, String currency) {
    final symbol = currency == 'TRY' ? '₺' : currency;
    return '${(cents / 100).toStringAsFixed(2)} $symbol';
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: AppColors.warning,
        );
      }),
    );
  }
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.entry, required this.onSave});

  final YemekGunluguKaydi entry;
  final Future<void> Function(int? amountCents, String? note, int? rating)
  onSave;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  int _rating = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _amountCtrl = TextEditingController(
      text: entry.amountCents != null
          ? (entry.amountCents! / 100).toStringAsFixed(2)
          : '',
    );
    _noteCtrl = TextEditingController(text: entry.personalNote ?? '');
    _rating = entry.personalRating ?? 0;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.entry.businessName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.entry.category,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: InputDecoration(
              labelText: context.l10n.yemekGunluguAmountPaidLabel,
              hintText: context.l10n.yemekGunluguAmountHint,
              suffixText: '₺',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.yemekGunluguNoteLabel,
              hintText: context.l10n.yemekGunluguNoteHint,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.yemekGunluguRatingLabel,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 32,
                    color: AppColors.warning,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _handleSave,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(context.l10n.yemekGunluguSaveButton),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      final rawAmount = _amountCtrl.text.trim().replaceAll(',', '.');
      final parsedAmount = double.tryParse(rawAmount);
      final amountCents = parsedAmount != null
          ? (parsedAmount * 100).round()
          : null;
      final note = _noteCtrl.text.trim();
      final rating = _rating > 0 ? _rating : null;
      await widget.onSave(amountCents, note.isEmpty ? null : note, rating);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _JournalSkeleton extends StatelessWidget {
  const _JournalSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 6,
      separatorBuilder: (_, i) => const SizedBox(height: 8),
      itemBuilder: (_, i) => const AppSkeletonCard(lines: 2),
    );
  }
}

// ── Hatırlatıcı Ayar Sayfası ────────────────────────────────────────────────

class _HatirlaticiSheet extends StatefulWidget {
  final bool enabled;
  final int saat;
  final int dakika;
  final void Function(bool en, int s, int d) onSave;

  const _HatirlaticiSheet({
    required this.enabled,
    required this.saat,
    required this.dakika,
    required this.onSave,
  });

  @override
  State<_HatirlaticiSheet> createState() => _HatirlaticiSheetState();
}

class _HatirlaticiSheetState extends State<_HatirlaticiSheet> {
  late bool _enabled;
  late int _saat;
  late int _dakika;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _saat = widget.saat;
    _dakika = widget.dakika;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            context.l10n.yemekGunluguReminderSheetTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.yemekGunluguReminderSheetSubtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Enable/disable
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile.adaptive(
              title: Text(
                context.l10n.yemekGunluguDailyReminderTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(context.l10n.yemekGunluguDailyReminderSubtitle),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ),

          if (_enabled) ...[
            const SizedBox(height: 16),
            Text(
              context.l10n.yemekGunluguReminderTimeLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 10),

            // Time picker
            Row(
              children: [
                // Hour
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        context.l10n.yemekGunluguHourLabel,
                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  setState(() => _saat = (_saat - 1 + 24) % 24),
                            ),
                            Text(
                              _saat.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  setState(() => _saat = (_saat + 1) % 24),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Text(
                    ':',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                ),
                // Minute
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        context.l10n.yemekGunluguMinuteLabel,
                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => setState(
                                () => _dakika = (_dakika - 15 + 60) % 60,
                              ),
                            ),
                            Text(
                              _dakika.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  setState(() => _dakika = (_dakika + 15) % 60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            // Quick time presets
            Wrap(
              spacing: 8,
              children: [
                for (final preset in [
                  (12, 0),
                  (18, 0),
                  (19, 30),
                  (20, 0),
                  (21, 0),
                ])
                  ChoiceChip(
                    label: Text(
                      '${preset.$1.toString().padLeft(2, '0')}:${preset.$2.toString().padLeft(2, '0')}',
                    ),
                    selected: _saat == preset.$1 && _dakika == preset.$2,
                    onSelected: (_) => setState(() {
                      _saat = preset.$1;
                      _dakika = preset.$2;
                    }),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onSave(_enabled, _saat, _dakika),
              child: Text(context.l10n.yemekGunluguSaveButton),
            ),
          ),
        ],
      ),
    );
  }
}
