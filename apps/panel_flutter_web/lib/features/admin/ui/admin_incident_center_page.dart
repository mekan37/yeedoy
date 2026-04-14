import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../data/admin_incident_repository.dart';

class AdminIncidentCenterPage extends ConsumerStatefulWidget {
  const AdminIncidentCenterPage({super.key});

  @override
  ConsumerState<AdminIncidentCenterPage> createState() =>
      _AdminIncidentCenterPageState();
}

class _AdminIncidentCenterPageState extends ConsumerState<AdminIncidentCenterPage> {
  final _incidentKeyCtrl = TextEditingController(text: 'yanlis-fiyat');
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  String _status = 'open';
  String _visibility = 'public';
  bool _saving = false;

  @override
  void dispose() {
    _incidentKeyCtrl.dispose();
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          PanelPageHeader(
            padding: EdgeInsets.zero,
            title: Text(l10n.adminIncidentCenterTitle),
            description: l10n.adminIncidentCenterSubtitle,
          ),
          const SizedBox(height: 12),
          _QuickPanel(onTap: (route) => context.go(route)),
          const SizedBox(height: 12),
          const _ReadyResponses(),
          const SizedBox(height: 12),
          _LogComposer(
            incidentKeyCtrl: _incidentKeyCtrl,
            titleCtrl: _titleCtrl,
            summaryCtrl: _summaryCtrl,
            actionCtrl: _actionCtrl,
            status: _status,
            visibility: _visibility,
            saving: _saving,
            onStatusChanged: (v) => setState(() => _status = v),
            onVisibilityChanged: (v) => setState(() => _visibility = v),
            onSave: _save,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<IncidentUpdate>>(
            future: ref.read(adminIncidentRepositoryProvider).listAdmin(limit: 100),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Text(
                  AppErrorMapper.message(snap.error),
                  style: const TextStyle(color: AppColors.danger),
                );
              }
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return Text(l10n.adminIncidentCenterNoLogs);
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminIncidentCenterTransparentLogTitle,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      for (final item in items.take(20)) ...[
                        Text(
                          '${item.incidentKey} • ${item.status.toUpperCase()} • ${_fmtTime(item.createdAt)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(item.title),
                        Text(item.summary, style: const TextStyle(color: AppColors.muted)),
                        Text(
                          l10n.adminIncidentCenterHowFixed(item.actionTaken),
                          style: const TextStyle(color: AppColors.textStrong),
                        ),
                        const Divider(height: 18),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_incidentKeyCtrl.text.trim().isEmpty ||
        _titleCtrl.text.trim().isEmpty ||
        _summaryCtrl.text.trim().isEmpty ||
        _actionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.adminIncidentCenterFillAllFields)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(adminIncidentRepositoryProvider).create(
        incidentKey: _incidentKeyCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        summary: _summaryCtrl.text.trim(),
        actionTaken: _actionCtrl.text.trim(),
        status: _status,
        visibility: _visibility,
      );
      if (!mounted) return;
      _titleCtrl.clear();
      _summaryCtrl.clear();
      _actionCtrl.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmtTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _QuickPanel extends StatelessWidget {
  const _QuickPanel({required this.onTap});

  final void Function(String route) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminIncidentCenterQuickPanelTitle,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => onTap('/admin/reports'),
                  child: Text(l10n.adminIncidentCenterReportsQueueAction),
                ),
                OutlinedButton(
                  onPressed: () => onTap('/admin/businesses'),
                  child: Text(l10n.adminIncidentCenterReviewBusinessAction),
                ),
                OutlinedButton(
                  onPressed: () => onTap('/admin/audit'),
                  child: Text(l10n.adminIncidentCenterAuditLogAction),
                ),
                OutlinedButton(
                  onPressed: () => onTap('/guvenlik-durumu'),
                  child: Text(l10n.adminIncidentCenterHowWeFixedAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyResponses extends StatelessWidget {
  const _ReadyResponses();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminIncidentCenterReadyResponsesTitle,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminIncidentCenterReadyResponseWrongPrice,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.adminIncidentCenterReadyResponseFakeBusiness,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.adminIncidentCenterReadyResponseMedia,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogComposer extends StatelessWidget {
  const _LogComposer({
    required this.incidentKeyCtrl,
    required this.titleCtrl,
    required this.summaryCtrl,
    required this.actionCtrl,
    required this.status,
    required this.visibility,
    required this.saving,
    required this.onStatusChanged,
    required this.onVisibilityChanged,
    required this.onSave,
  });

  final TextEditingController incidentKeyCtrl;
  final TextEditingController titleCtrl;
  final TextEditingController summaryCtrl;
  final TextEditingController actionCtrl;
  final String status;
  final String visibility;
  final bool saving;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onVisibilityChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminIncidentCenterLogEntryTitle,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: incidentKeyCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminIncidentCenterIncidentKeyLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminIncidentCenterTitleLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: summaryCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.adminIncidentCenterWhatHappenedLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: actionCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.adminIncidentCenterHowDidWeFixLabel,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                DropdownButton<String>(
                  value: status,
                  items: [
                    DropdownMenuItem(
                      value: 'open',
                      child: Text(l10n.adminIncidentCenterStatusOpen),
                    ),
                    DropdownMenuItem(
                      value: 'mitigated',
                      child: Text(l10n.adminIncidentCenterStatusMitigated),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text(l10n.adminIncidentCenterStatusResolved),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) onStatusChanged(v);
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: visibility,
                  items: [
                    DropdownMenuItem(
                      value: 'public',
                      child: Text(l10n.adminIncidentCenterVisibilityPublic),
                    ),
                    DropdownMenuItem(
                      value: 'internal',
                      child: Text(l10n.adminIncidentCenterVisibilityInternal),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) onVisibilityChanged(v);
                  },
                ),
                const Spacer(),
                FilledButton(
                  onPressed: saving ? null : onSave,
                  child: Text(
                    saving
                        ? l10n.saving
                        : l10n.adminIncidentCenterAddLogAction,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

