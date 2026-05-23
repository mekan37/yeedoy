import 'package:flutter/material.dart';

import '../../../../uygulama/tema/renkler.dart';
import '../../../../core/ceviri/uygulama_yerellesmeleri.dart';

enum CommunityScoreKind { userTrust, dataTrust, valueInsight }

Future<void> showCommunityScoreExplainerSheet(
  BuildContext context, {
  required CommunityScoreKind kind,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => CommunityScoreExplainerSheet(kind: kind),
  );
}

class CommunityScoreGuideCard extends StatelessWidget {
  const CommunityScoreGuideCard({
    super.key,
    required this.kind,
    this.margin = const EdgeInsets.only(top: 12),
  });

  final CommunityScoreKind kind;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(context, kind);
    final t = AppLocalizations.of(context);
    return Container(
      margin: margin,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScoreCategoryPill(label: copy.categoryLabel),
              const SizedBox(height: 10),
              Text(
                copy.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                copy.summary,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => showCommunityScoreExplainerSheet(
                    context,
                    kind: kind,
                  ),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(t.communityScoreExplainAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunityScoreExplainerSheet extends StatelessWidget {
  const CommunityScoreExplainerSheet({super.key, required this.kind});

  final CommunityScoreKind kind;

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(context, kind);
    final t = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScoreCategoryPill(label: copy.categoryLabel),
            const SizedBox(height: 12),
            Text(
              copy.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              copy.summary,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Text(
              t.communityScoreWhatImproves,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final signal in copy.signals) ...[
              _ScoreBullet(text: signal),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Text(
              t.communityScoreHowUsed,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              copy.usage,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBullet extends StatelessWidget {
  const _ScoreBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}

class ScoreCategoryPill extends StatelessWidget {
  const ScoreCategoryPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _CommunityScoreCopy {
  const _CommunityScoreCopy({
    required this.categoryLabel,
    required this.title,
    required this.summary,
    required this.signals,
    required this.usage,
  });

  final String categoryLabel;
  final String title;
  final String summary;
  final List<String> signals;
  final String usage;
}

_CommunityScoreCopy _copyFor(BuildContext context, CommunityScoreKind kind) {
  final t = AppLocalizations.of(context);
  switch (kind) {
    case CommunityScoreKind.userTrust:
      return _CommunityScoreCopy(
        categoryLabel: t.communityScoreUserTrustCategory,
        title: t.profileCommunityTrustTitle,
        summary: t.communityScoreUserTrustSummary,
        signals: [
          t.communityScoreUserTrustSignalAccuracy,
          t.communityScoreUserTrustSignalApproval,
          t.communityScoreUserTrustSignalSafety,
        ],
        usage: t.communityScoreUserTrustUsage,
      );
    case CommunityScoreKind.dataTrust:
      return _CommunityScoreCopy(
        categoryLabel: t.communityScoreDataTrustCategory,
        title: t.communityScoreDataTrustLabel,
        summary: t.communityScoreDataTrustSummary,
        signals: [
          t.communityScoreDataTrustSignalFreshness,
          t.communityScoreDataTrustSignalConsensus,
          t.communityScoreDataTrustSignalStability,
        ],
        usage: t.communityScoreDataTrustUsage,
      );
    case CommunityScoreKind.valueInsight:
      return _CommunityScoreCopy(
        categoryLabel: t.communityScoreInfoOnlyCategory,
        title: t.pricePerformance,
        summary: t.communityScoreValueInsightSummary,
        signals: [
          t.communityScoreValueSignalVerification,
          t.communityScoreValueSignalVotes,
          t.communityScoreValueSignalStability,
        ],
        usage: t.communityScoreValueUsage,
      );
  }
}
