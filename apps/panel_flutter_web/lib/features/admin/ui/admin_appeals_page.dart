import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../../shared/ui/design_system.dart';
import '../domain/admin_appeals_controller.dart';
import '../domain/admin_moderation_models.dart';

class AdminAppealsPage extends ConsumerWidget {
  const AdminAppealsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminAppealsControllerProvider);
    final controller = ref.read(adminAppealsControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelPageHeader(
            padding: EdgeInsets.zero,
            title: Text(context.l10n.adminAppealsTitle),
            actions: [
              OutlinedButton.icon(
                onPressed: state.isLoading ? null : controller.refresh,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.yenile),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text(context.l10n.pending),
                selected: state.statusFilter == 'pending',
                onSelected: (_) => controller.setStatusFilter('pending'),
              ),
              FilterChip(
                label: Text(context.l10n.approved),
                selected: state.statusFilter == 'approved',
                onSelected: (_) => controller.setStatusFilter('approved'),
              ),
              FilterChip(
                label: Text(context.l10n.rejected),
                selected: state.statusFilter == 'rejected',
                onSelected: (_) => controller.setStatusFilter('rejected'),
              ),
              FilterChip(
                label: Text(context.l10n.tumu),
                selected: state.statusFilter.isEmpty,
                onSelected: (_) => controller.setStatusFilter(''),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AppErrorMapper.message(state.error),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty
                ? Center(
                    child: AppEmptyState(
                      icon: Icons.gavel_outlined,
                      title: context.l10n.adminAppealsEmptySla,
                      description: 'Filtre kriterlerinize uyan başvuru bulunamadı.',
                    ),
                  )
                : ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openDecisionSheet(
                            context,
                            ref,
                            item: item,
                            templates: state.templates,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.sourceType} · ${item.reason}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textStrong,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.l10n.adminAppealSourceAndUser(
                                          _short(item.sourceId),
                                          _short(item.appellantUserId),
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _statusLabel(context, item.status),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
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

Future<void> _openDecisionSheet(
  BuildContext context,
  WidgetRef ref, {
  required AdminAppealItem item,
  required List<ModerationDecisionTemplate> templates,
}) async {
  final noteCtrl = TextEditingController(text: item.decisionNote ?? '');
  var decision = item.status == 'approved' ? 'approved' : 'rejected';
  ModerationDecisionTemplate? selectedTemplate;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.adminAppealDecisionTitle(_short(item.id)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: decision,
                  items: [
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text(context.l10n.adminAppealApproveAction),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text(context.l10n.adminAppealRejectAction),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    decision = value ?? 'rejected';
                  }),
                  decoration: InputDecoration(
                    labelText: context.l10n.adminAppealDecisionLabel,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedTemplate?.id,
                  items: templates
                      .where((template) => template.decision == decision)
                      .map(
                        (template) => DropdownMenuItem<String>(
                          value: template.id,
                          child: Text(template.title),
                        ),
                      )
                      .toList(),
                  onChanged: (templateId) {
                    final template = templates.firstWhere(
                      (candidate) => candidate.id == templateId,
                      orElse: () => const ModerationDecisionTemplate(
                        id: '',
                        scope: '',
                        decision: '',
                        title: '',
                        body: '',
                        locale: 'tr-TR',
                      ),
                    );
                    if (template.id.isEmpty) return;
                    setState(() {
                      selectedTemplate = template;
                      noteCtrl.text = template.body;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: context.l10n.adminAppealTemplateLabel,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: context.l10n.adminAppealDecisionTextLabel,
                    hintText: context.l10n.adminAppealDecisionTextHint,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(adminAppealsControllerProvider.notifier)
                            .decide(
                              appealId: item.id,
                              decision: decision,
                              note: noteCtrl.text.trim(),
                            );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppErrorMapper.message(error)),
                          ),
                        );
                      }
                    },
                    child: Text(context.l10n.save),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

String _short(String id) => id.length <= 10
    ? id
    : '${id.substring(0, 6)}...${id.substring(id.length - 4)}';

String _statusLabel(BuildContext context, String status) => switch (status) {
  'pending' => context.l10n.pending,
  'approved' => context.l10n.approved,
  'rejected' => context.l10n.rejected,
  _ => status,
};


