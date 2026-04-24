import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/owner_business_guard.dart';
import '../../../shared/ui/components/panel_action_button.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../domain/owner_business_hours_controller.dart';
import '../domain/owner_business_hours_models.dart';

class OwnerBusinessHoursPage extends ConsumerStatefulWidget {
  const OwnerBusinessHoursPage({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<OwnerBusinessHoursPage> createState() =>
      _OwnerBusinessHoursPageState();
}

class _OwnerBusinessHoursPageState
    extends ConsumerState<OwnerBusinessHoursPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OwnerBusinessGuard(
      businessId: widget.businessId,
      builder: (context, ref) {
        final st = ref.watch(
            ownerBusinessHoursControllerProvider(widget.businessId));
        final ctrl = ref.read(
            ownerBusinessHoursControllerProvider(widget.businessId).notifier);

        return Column(
          children: [
            PanelPageHeader(
              eyebrow: l10n.ownerShellPanelTitle,
              title: const Text('Çalışma Saatleri'),
              description:
                  'Haftalık program ve özel günleri yönetin. Müşteriler menü sayfasında "Şu an açık" bilgisini görür.',
              actions: [
                if (st.isOpenNow != null) _OpenNowBadge(isOpen: st.isOpenNow!),
                PanelActionButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Yenile',
                  variant: PanelActionButtonVariant.neutral,
                  onPressed: ctrl.refresh,
                ),
              ],
            ),
            Expanded(
              child: st.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: ctrl.refresh,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (st.error != null)
                            _ErrorBanner(message: st.error.toString()),
                          if (st.savedMessage != null)
                            _SuccessBanner(message: st.savedMessage!),
                          // ── Weekly schedule ───────────────────────────
                          _SectionCard(
                            title: 'Haftalık Program',
                            child: Column(
                              children: [
                                ...st.weekly.map(
                                  (row) => _DayRow(
                                    row: row,
                                    onClosedChanged: (v) =>
                                        ctrl.updateDayClosed(row.dayOfWeek, v),
                                    onOpenTimeChanged: (v) =>
                                        ctrl.updateDayOpenTime(row.dayOfWeek, v),
                                    onCloseTimeChanged: (v) =>
                                        ctrl.updateDayCloseTime(row.dayOfWeek, v),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: PanelActionButton(
                                    icon: Icons.save_rounded,
                                    tooltip: 'Haftalık Saatleri Kaydet',
                                    label: st.isSaving
                                        ? 'Kaydediliyor…'
                                        : 'Haftalık Saatleri Kaydet',
                                    variant: PanelActionButtonVariant.primary,
                                    onPressed: st.isSaving
                                        ? null
                                        : () => ctrl.saveWeeklyHours(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // ── Special / holiday days ────────────────────
                          _SectionCard(
                            title: 'Özel Günler ve Tatiller',
                            trailing: PanelActionButton(
                              icon: Icons.add_rounded,
                              tooltip: 'Özel Gün Ekle',
                              label: 'Özel Gün Ekle',
                              variant: PanelActionButtonVariant.secondary,
                              onPressed: () => _showAddSpecialDialog(
                                  context, ctrl),
                            ),
                            child: st.special.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Text(
                                        'Özel gün eklenmemiş.',
                                        style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 13),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: st.special
                                        .map(
                                          (s) => _SpecialDayTile(
                                            item: s,
                                            onDelete: () =>
                                                ctrl.deleteSpecialHour(s.date),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddSpecialDialog(
    BuildContext context,
    OwnerBusinessHoursController ctrl,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddSpecialDayDialog(ctrl: ctrl),
    );
  }
}

// ── Open/closed badge ────────────────────────────────────────────────────────

class _OpenNowBadge extends StatelessWidget {
  const _OpenNowBadge({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.muted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.muted.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.success : AppColors.muted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'Şu an açık' : 'Şu an kapalı',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isOpen ? AppColors.success : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 20, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Day row ──────────────────────────────────────────────────────────────────

const _dayLabels = [
  'Pazar',     // 0
  'Pazartesi', // 1
  'Salı',      // 2
  'Çarşamba',  // 3
  'Perşembe',  // 4
  'Cuma',      // 5
  'Cumartesi', // 6
];

class _DayRow extends StatefulWidget {
  const _DayRow({
    required this.row,
    required this.onClosedChanged,
    required this.onOpenTimeChanged,
    required this.onCloseTimeChanged,
  });
  final BusinessHourRow row;
  final ValueChanged<bool> onClosedChanged;
  final ValueChanged<String> onOpenTimeChanged;
  final ValueChanged<String> onCloseTimeChanged;

  @override
  State<_DayRow> createState() => _DayRowState();
}

class _DayRowState extends State<_DayRow> {
  late TextEditingController _openCtrl;
  late TextEditingController _closeCtrl;

  @override
  void initState() {
    super.initState();
    _openCtrl = TextEditingController(text: widget.row.openTime);
    _closeCtrl = TextEditingController(text: widget.row.closeTime);
  }

  @override
  void didUpdateWidget(covariant _DayRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.openTime != widget.row.openTime) {
      _openCtrl.text = widget.row.openTime;
    }
    if (oldWidget.row.closeTime != widget.row.closeTime) {
      _closeCtrl.text = widget.row.closeTime;
    }
  }

  @override
  void dispose() {
    _openCtrl.dispose();
    _closeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              _dayLabels[row.dayOfWeek],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
          ),
          Switch(
            value: !row.isClosed,
            onChanged: (v) => widget.onClosedChanged(!v),
            activeThumbColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          if (!row.isClosed) ...[
            _TimeField(
              label: 'Açılış',
              controller: _openCtrl,
              onSubmitted: widget.onOpenTimeChanged,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('–', style: TextStyle(color: AppColors.muted)),
            ),
            _TimeField(
              label: 'Kapanış',
              controller: _closeCtrl,
              onSubmitted: widget.onCloseTimeChanged,
            ),
          ] else
            const Text(
              'Kapalı',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.controller,
    required this.onSubmitted,
  });
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11),
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        onSubmitted: onSubmitted,
        onTapOutside: (_) => onSubmitted(controller.text),
      ),
    );
  }
}

// ── Special day tile ─────────────────────────────────────────────────────────

class _SpecialDayTile extends StatelessWidget {
  const _SpecialDayTile({required this.item, required this.onDelete});
  final BusinessSpecialHour item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.date,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.isClosed
                      ? 'Kapalı${item.note != null ? ' — ${item.note}' : ''}'
                      : '${item.openTime ?? '?'} – ${item.closeTime ?? '?'}${item.note != null ? ' (${item.note})' : ''}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.muted),
            tooltip: 'Sil',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Add special day dialog ───────────────────────────────────────────────────

class _AddSpecialDayDialog extends StatefulWidget {
  const _AddSpecialDayDialog({required this.ctrl});
  final OwnerBusinessHoursController ctrl;

  @override
  State<_AddSpecialDayDialog> createState() => _AddSpecialDayDialogState();
}

class _AddSpecialDayDialogState extends State<_AddSpecialDayDialog> {
  final _dateCtrl = TextEditingController();
  final _openCtrl = TextEditingController(text: '09:00');
  final _closeCtrl = TextEditingController(text: '22:00');
  final _noteCtrl = TextEditingController();
  bool _isClosed = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _openCtrl.dispose();
    _closeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final date = _dateCtrl.text.trim();
    if (date.isEmpty) {
      setState(() => _error = 'Tarih gerekli (YYYY-AA-GG).');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await widget.ctrl.addSpecialHour(
      date: date,
      openTime: _isClosed ? null : _openCtrl.text.trim(),
      closeTime: _isClosed ? null : _closeCtrl.text.trim(),
      isClosed: _isClosed,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Özel Gün Ekle'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Tarih (YYYY-AA-GG)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Kapalı', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Switch(
                  value: _isClosed,
                  onChanged: (v) => setState(() => _isClosed = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            if (!_isClosed) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _openCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Açılış',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _closeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kapanış',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                    color: AppColors.danger, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Kaydediliyor…' : 'Ekle'),
        ),
      ],
    );
  }
}

// ── Banner widgets ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
