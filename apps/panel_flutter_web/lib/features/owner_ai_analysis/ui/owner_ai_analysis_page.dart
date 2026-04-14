import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/app_scaffold.dart';
import '../../../shared/ui/components/owner_business_guard.dart';
import '../../../shared/ui/design_system.dart';
import '../data/ai_analysis_repository.dart';
import '../domain/ai_analysis_models.dart';

// ─── providers ──────────────────────────────────────────────────────────────

final _jobsProvider = FutureProvider.autoDispose
    .family<List<AiOcrJob>, String>((ref, businessId) async {
  final repo = ref.watch(aiAnalysisRepositoryProvider);
  return repo.listJobs(businessId: businessId);
});

final _analysisProvider = FutureProvider.autoDispose
    .family<List<AiAnalysisItem>, _AnalysisQuery>((ref, q) async {
  final repo = ref.watch(aiAnalysisRepositoryProvider);
  return repo.listAnalysis(
    businessId: q.businessId,
    statusFilter: q.statusFilter,
  );
});

class _AnalysisQuery {
  const _AnalysisQuery({required this.businessId, this.statusFilter});
  final String businessId;
  final String? statusFilter;

  @override
  bool operator ==(Object other) =>
      other is _AnalysisQuery &&
      other.businessId == businessId &&
      other.statusFilter == statusFilter;

  @override
  int get hashCode => Object.hash(businessId, statusFilter);
}

// ─── page ────────────────────────────────────────────────────────────────────

class OwnerAiAnalysisPage extends ConsumerStatefulWidget {
  const OwnerAiAnalysisPage({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<OwnerAiAnalysisPage> createState() =>
      _OwnerAiAnalysisPageState();
}

class _OwnerAiAnalysisPageState extends ConsumerState<OwnerAiAnalysisPage> {
  String? _statusFilter;
  bool _uploading = false;
  String? _uploadError;

  @override
  Widget build(BuildContext context) {
    if (widget.businessId.isEmpty) {
      return AppScaffold(
        appBar: AppBar(title: Text(context.l10n.ownerAiAnalysisTitle)),
        body: AppEmptyState(
          icon: Icons.psychology_outlined,
          title: context.l10n.ownerAiAnalysisNoBusinessTitle,
          description: context.l10n.ownerAiAnalysisNoBusinessDescription,
        ),
      );
    }

    return OwnerBusinessGuard(
      businessId: widget.businessId,
      builder: (context, ref) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    final query = _AnalysisQuery(
      businessId: widget.businessId,
      statusFilter: _statusFilter,
    );
    final analysisAsync = ref.watch(_analysisProvider(query));

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.ownerAiAnalysisTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_jobsProvider(widget.businessId));
          ref.invalidate(_analysisProvider(query));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            // Disclaimer banner
            _DisclaimerBanner(),
            const SizedBox(height: 16),

            // Upload section
            _UploadSection(
              uploading: _uploading,
              error: _uploadError,
              onUpload: _handleUpload,
            ),
            const SizedBox(height: 20),

            // Jobs history
            _JobsSection(businessId: widget.businessId),
            const SizedBox(height: 20),

            // Analysis results
            Text(
              l10n.ownerAiAnalysisResultsTitle,
              style: context.titleStyle,
            ),
            const SizedBox(height: 8),
            _StatusFilterChips(
              selected: _statusFilter,
              onChanged: (v) => setState(() => _statusFilter = v),
            ),
            const SizedBox(height: 12),
            analysisAsync.when(
              loading: () => const _AnalysisSkeleton(),
              error: (e, _) => Text(
                AppErrorMapper.message(e),
                style: context.bodyStyle.copyWith(color: Colors.red),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: l10n.ownerAiAnalysisEmptyTitle,
                    description: l10n.ownerAiAnalysisEmptyDescription,
                  );
                }
                return Column(
                  children: [
                    for (final item in items) ...[
                      _AnalysisCard(
                        item: item,
                        onApprove: item.status == 'pending_review'
                            ? () => _onApprove(item)
                            : null,
                        onReject: item.status == 'pending_review'
                            ? () => _onReject(item)
                            : null,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload() async {
    setState(() {
      _uploading = true;
      _uploadError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _uploading = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _uploading = false;
          _uploadError = 'file_read_error';
        });
        return;
      }

      final repo = ref.read(aiAnalysisRepositoryProvider);
      final mimeType = _mimeFromExt(file.extension ?? 'jpg');

      final fileUrl = await repo.uploadMenuFile(
        businessId: widget.businessId,
        bytes: bytes,
        fileName: file.name,
        mimeType: mimeType,
      );

      final jobId = await repo.createOcrJob(
        businessId: widget.businessId,
        fileUrl: fileUrl,
        fileName: file.name,
      );

      if (!mounted) return;
      setState(() => _uploading = false);

      ref.invalidate(_jobsProvider(widget.businessId));

      // Trigger analysis (show progress snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerAiAnalysisAnalyzing)),
      );

      try {
        final count = await repo.triggerAnalysis(jobId: jobId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.ownerAiAnalysisComplete(count)),
          ),
        );
        ref.invalidate(_jobsProvider(widget.businessId));
        ref.invalidate(_analysisProvider(
          _AnalysisQuery(businessId: widget.businessId, statusFilter: _statusFilter),
        ));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorMapper.message(e)),
            backgroundColor: Colors.red,
          ),
        );
        ref.invalidate(_jobsProvider(widget.businessId));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadError = AppErrorMapper.message(e);
      });
    }
  }

  Future<void> _onApprove(AiAnalysisItem item) async {
    try {
      await ref.read(aiAnalysisRepositoryProvider).approveAnalysis(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerAiAnalysisApproved)),
      );
      ref.invalidate(_analysisProvider(
        _AnalysisQuery(businessId: widget.businessId, statusFilter: _statusFilter),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(e))),
      );
    }
  }

  Future<void> _onReject(AiAnalysisItem item) async {
    try {
      await ref.read(aiAnalysisRepositoryProvider).rejectAnalysis(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerAiAnalysisRejected)),
      );
      ref.invalidate(_analysisProvider(
        _AnalysisQuery(businessId: widget.businessId, statusFilter: _statusFilter),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(e))),
      );
    }
  }

  String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

// ─── sub-widgets ─────────────────────────────────────────────────────────────

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.ownerAiAnalysisDisclaimer,
              style: context.captionStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadSection extends StatelessWidget {
  const _UploadSection({
    required this.uploading,
    required this.error,
    required this.onUpload,
  });

  final bool uploading;
  final String? error;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.ownerAiAnalysisUploadTitle, style: context.titleStyle),
            const SizedBox(height: 4),
            Text(
              l10n.ownerAiAnalysisUploadDescription,
              style: context.captionStyle,
            ),
            const SizedBox(height: 12),
            if (error != null) ...[
              Text(error!, style: context.bodyStyle.copyWith(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            AppButton(
              label: uploading
                  ? l10n.ownerAiAnalysisUploading
                  : l10n.ownerAiAnalysisUploadAction,
              onPressed: uploading ? null : onUpload,
              icon: uploading ? null : Icons.upload_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _JobsSection extends ConsumerWidget {
  const _JobsSection({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(_jobsProvider(businessId));
    return jobsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (jobs) {
        if (jobs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.ownerAiAnalysisJobsTitle, style: context.titleStyle),
            const SizedBox(height: 8),
            for (final job in jobs.take(5)) ...[
              _JobStatusTile(job: job),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

class _JobStatusTile extends StatelessWidget {
  const _JobStatusTile({required this.job});
  final AiOcrJob job;

  @override
  Widget build(BuildContext context) {
    final color = job.isCompleted
        ? Colors.green
        : job.isFailed
            ? Colors.red
            : Colors.orange;
    final icon = job.isCompleted
        ? Icons.check_circle_outline
        : job.isFailed
            ? Icons.error_outline
            : Icons.hourglass_top_outlined;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                job.fileName ?? job.fileUrl.split('/').last,
                style: context.bodyStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (job.isCompleted && job.itemCount != null)
              Text(
                '${job.itemCount} ürün',
                style: context.captionStyle.copyWith(color: Colors.green),
              ),
            if (job.isFailed)
              Text(
                job.errorMessage ?? 'Hata',
                style: context.captionStyle.copyWith(color: Colors.red),
              ),
            if (job.isActive)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        AppFilterChip(
          label: context.l10n.ownerAiAnalysisFilterAll,
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        AppFilterChip(
          label: context.l10n.ownerAiAnalysisFilterPending,
          selected: selected == 'pending_review',
          onTap: () => onChanged('pending_review'),
        ),
        AppFilterChip(
          label: context.l10n.ownerAiAnalysisFilterApproved,
          selected: selected == 'approved',
          onTap: () => onChanged('approved'),
        ),
        AppFilterChip(
          label: context.l10n.ownerAiAnalysisFilterRejected,
          selected: selected == 'rejected',
          onTap: () => onChanged('rejected'),
        ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final AiAnalysisItem item;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  Color _confidenceColor(BuildContext context) {
    switch (item.confidenceLevel) {
      case ConfidenceLevel.high:
        return Colors.green;
      case ConfidenceLevel.medium:
        return Colors.orange;
      case ConfidenceLevel.low:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidenceColor = _confidenceColor(context);
    final confidencePct = (item.confidence * 100).toStringAsFixed(0);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: confidenceColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '$confidencePct%',
                    style: context.captionStyle.copyWith(color: confidenceColor),
                  ),
                ),
                const SizedBox(width: 6),
                _StatusBadge(status: item.status),
              ],
            ),

            // Allergens
            if (item.allergens.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final a in item.allergens)
                    _AllergenChip(code: a),
                ],
              ),
            ],

            // Calories
            if (item.calorieMin != null || item.calorieMax != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.local_fire_department_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _calorieLabel(),
                    style: context.captionStyle,
                  ),
                  Text(
                    ' (yaklaşık)',
                    style: context.captionStyle.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],

            // Ingredients
            if (item.ingredients.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.ingredients.take(6).join(', ') +
                    (item.ingredients.length > 6 ? '...' : ''),
                style: context.captionStyle,
              ),
            ],

            // Review required warning
            if (item.requiresReview && item.status == 'pending_review') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.ownerAiAnalysisReviewRequired,
                    style: context.captionStyle
                        .copyWith(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ],

            // Actions
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onApprove != null)
                    Expanded(
                      child: AppButton(
                        label: context.l10n.ownerAiAnalysisApproveAction,
                        onPressed: onApprove,
                        icon: Icons.check_outlined,
                      ),
                    ),
                  if (onApprove != null && onReject != null)
                    const SizedBox(width: 8),
                  if (onReject != null)
                    Expanded(
                      child: AppButton(
                        label: context.l10n.ownerAiAnalysisRejectAction,
                        variant: AppButtonVariant.ghost,
                        onPressed: onReject,
                        icon: Icons.close_outlined,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _calorieLabel() {
    if (item.calorieMin != null && item.calorieMax != null) {
      return '${item.calorieMin}–${item.calorieMax} kcal';
    }
    if (item.calorieMin != null) return '≥${item.calorieMin} kcal';
    if (item.calorieMax != null) return '≤${item.calorieMax} kcal';
    return '';
  }
}

class _AllergenChip extends StatelessWidget {
  const _AllergenChip({required this.code});
  final String code;

  static const _labels = <String, String>{
    'gluten': 'Gluten',
    'crustaceans': 'Kabuklu',
    'eggs': 'Yumurta',
    'fish': 'Balık',
    'peanuts': 'Yer fıstığı',
    'soybeans': 'Soya',
    'milk': 'Süt',
    'nuts': 'Kuruyemiş',
    'celery': 'Kereviz',
    'mustard': 'Hardal',
    'sesame': 'Susam',
    'sulphites': 'Sülfit',
    'lupin': 'Acı bakla',
    'molluscs': 'Yumuşakça',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        _labels[code] ?? code,
        style: context.captionStyle.copyWith(color: Colors.red.shade700),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = context.l10n.ownerAiAnalysisStatusApproved;
        break;
      case 'rejected':
        color = Colors.red;
        label = context.l10n.ownerAiAnalysisStatusRejected;
        break;
      default:
        color = Colors.orange;
        label = context.l10n.ownerAiAnalysisStatusPending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: context.captionStyle.copyWith(color: color),
      ),
    );
  }
}

class _AnalysisSkeleton extends StatelessWidget {
  const _AnalysisSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: AppSkeletonCard(lines: 4),
        ),
      ),
    );
  }
}
