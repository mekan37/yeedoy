import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../uygulama/tema/uygulama_tipografisi.dart';
import '../../../../uygulama/tema/renkler.dart';
import '../../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../isletme/domain/rapor_kontrolcusu.dart';

class ReportBottomSheet extends ConsumerStatefulWidget {
  const ReportBottomSheet.business({
    super.key,
    required this.businessId,
    required this.redirectUrl,
    this.rateLimitText,
    this.initialReason,
    this.initialDetails,
  }) : reviewId = null,
       menuItemPhotoId = null;

  const ReportBottomSheet.review({
    super.key,
    required this.reviewId,
    required this.redirectUrl,
    this.rateLimitText,
    this.initialReason,
    this.initialDetails,
  }) : businessId = null,
       menuItemPhotoId = null;

  const ReportBottomSheet.menuPhoto({
    super.key,
    required this.menuItemPhotoId,
    required this.businessId,
    required this.redirectUrl,
    this.rateLimitText,
    this.initialReason,
    this.initialDetails,
  }) : reviewId = null;

  final String? businessId;
  final String? reviewId;
  final String? menuItemPhotoId;
  final String redirectUrl;
  final String? rateLimitText;
  final String? initialReason;
  final String? initialDetails;

  @override
  ConsumerState<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends ConsumerState<ReportBottomSheet> {
  final detailsCtrl = TextEditingController();
  final copyrightUrlCtrl = TextEditingController();
  final copyrightOwnerCtrl = TextEditingController();
  final copyrightEmailCtrl = TextEditingController();
  String reason = 'spam';

  List<(String, String)> _reasons(AppLocalizations t) {
    if (widget.reviewId != null) {
      return [
        ('spam', t.reportReasonSpam),
        ('abuse', t.reportReasonAbuse),
        ('wrong_info', t.reportReasonWrongInfo),
        ('copyright', t.reportReasonCopyright),
        ('illegal', t.reportReasonIllegal),
        ('other', t.other),
      ];
    }
    if (widget.menuItemPhotoId != null) {
      return [
        ('copyright', t.reportReasonCopyright),
        ('spam', t.reportReasonSpam),
        ('wrong_info', t.reportReasonWrongImage),
        ('illegal', t.reportReasonIllegal),
        ('other', t.other),
      ];
    }
    return [
      ('wrong_info', t.reportReasonWrongInfo),
      ('closed', t.reportReasonClosed),
      ('moved', t.reportReasonMoved),
      ('wrong_price', t.reportReasonWrongPrice),
      ('spam', t.reportReasonSpam),
      ('copyright', t.reportReasonCopyright),
      ('illegal', t.reportReasonIllegal),
      ('other', t.other),
    ];
  }

  @override
  void initState() {
    super.initState();
    final initialReason = widget.initialReason;
    if (initialReason != null) {
      reason = initialReason;
    } else if (widget.businessId != null) {
      reason = 'wrong_info';
    }
    final initialDetails = widget.initialDetails;
    if (initialDetails != null && initialDetails.trim().isNotEmpty) {
      detailsCtrl.text = initialDetails.trim();
    }
  }

  @override
  void dispose() {
    detailsCtrl.dispose();
    copyrightUrlCtrl.dispose();
    copyrightOwnerCtrl.dispose();
    copyrightEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final reasons = _reasons(t);
    if (!reasons.any((r) => r.$1 == reason)) {
      reason = reasons.first.$1;
    }

    final st = widget.reviewId != null
        ? ref.watch(reviewReportControllerProvider(widget.reviewId!))
        : (widget.menuItemPhotoId != null
              ? ref.watch(
                  menuPhotoReportControllerProvider(widget.menuItemPhotoId!),
                )
              : ref.watch(reportControllerProvider(widget.businessId!)));
    final isLoading = st.status == ReportStatus.loading;
    final rateLimitText = widget.rateLimitText ?? _defaultRateLimitText(t);
    final errorText = st.status == ReportStatus.error
        ? (st.errorCode == 'rate_limited_24h'
              ? rateLimitText
              : (st.message ?? t.unexpectedError))
        : null;
    final showCopyright = reason == 'copyright';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.report, style: context.sectionTitleStyle),
          const SizedBox(height: 12),
          if (widget.businessId != null) ...[
            Text(
              t.reportBusinessHint,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          DropdownButtonFormField<String>(
            initialValue: reason,
            items: reasons
                .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                .toList(),
            onChanged: isLoading
                ? null
                : (v) => setState(() => reason = v ?? 'other'),
            decoration: InputDecoration(labelText: t.reportReasonLabel),
          ),
          const SizedBox(height: 12),
          if (showCopyright) ...[
            TextField(
              controller: copyrightUrlCtrl,
              decoration: InputDecoration(labelText: t.reportCopyrightUrlLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: copyrightOwnerCtrl,
              decoration: InputDecoration(
                labelText: t.reportCopyrightOwnerLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: copyrightEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: t.reportCopyrightEmailLabel,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: detailsCtrl,
            maxLength: 500,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: t.reportDetailsLabel,
              alignLabelWithHint: true,
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Text(errorText, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : _submit,
              child: Text(isLoading ? t.submitting : t.submit),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  String _defaultRateLimitText(AppLocalizations t) {
    if (widget.reviewId != null) return t.reportRateLimitReview;
    if (widget.menuItemPhotoId != null) return t.reportRateLimitPhoto;
    return t.reportRateLimitBusiness;
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final details = _buildDetails(t);
    final res = widget.reviewId != null
        ? await ref
              .read(reviewReportControllerProvider(widget.reviewId!).notifier)
              .submit(reason: reason, details: details)
        : (widget.menuItemPhotoId != null
              ? await ref
                    .read(
                      menuPhotoReportControllerProvider(
                        widget.menuItemPhotoId!,
                      ).notifier,
                    )
                    .submit(reason: reason, details: details)
              : await ref
                    .read(reportControllerProvider(widget.businessId!).notifier)
                    .submit(reason: reason, details: details));

    if (!mounted) return;

    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.queued ? t.weakConnectionQueueNotice : t.reportSubmittedThanks,
          ),
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (res.error == 'not_authenticated') {
      Navigator.pop(context);
      final redirect = Uri.encodeComponent(widget.redirectUrl);
      context.go('/login?redirect=$redirect');
      return;
    }

    if (res.error != 'rate_limited_24h') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.error ?? t.unexpectedError)));
    }
  }

  String? _buildDetails(AppLocalizations t) {
    final base = detailsCtrl.text.trim();
    if (reason != 'copyright') {
      return base.isEmpty ? null : base;
    }
    final url = copyrightUrlCtrl.text.trim();
    final owner = copyrightOwnerCtrl.text.trim();
    final email = copyrightEmailCtrl.text.trim();
    final parts = <String>[];
    if (url.isNotEmpty) parts.add('${t.reportCopyrightUrlPrefix}: $url');
    if (owner.isNotEmpty) parts.add('${t.reportCopyrightOwnerPrefix}: $owner');
    if (email.isNotEmpty) parts.add('${t.reportCopyrightEmailPrefix}: $email');
    if (base.isNotEmpty) parts.add('${t.note}: $base');
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }
}

