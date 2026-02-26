import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../features/business/report_controller.dart';

class ReportBottomSheet extends ConsumerStatefulWidget {
  const ReportBottomSheet.business({
    super.key,
    required this.businessId,
    required this.redirectUrl,
    this.rateLimitText = 'Bu işletme için bugün zaten bildirim gönderdin.',
    this.initialReason,
    this.initialDetails,
  }) : reviewId = null,
       menuItemPhotoId = null;

  const ReportBottomSheet.review({
    super.key,
    required this.reviewId,
    required this.redirectUrl,
    this.rateLimitText =
        'Bu yorum için son 24 saatte zaten bildirim gönderdin.',
    this.initialReason,
    this.initialDetails,
  }) : businessId = null,
       menuItemPhotoId = null;
  const ReportBottomSheet.menuPhoto({
    super.key,
    required this.menuItemPhotoId,
    required this.businessId,
    required this.redirectUrl,
    this.rateLimitText =
        'Bu fotoğraf için son 24 saatte zaten bildirim gönderdin.',
    this.initialReason,
    this.initialDetails,
  }) : reviewId = null;

  final String? businessId;
  final String? reviewId;
  final String? menuItemPhotoId;
  final String redirectUrl;
  final String rateLimitText;
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

  List<(String, String)> get _reasons {
    if (widget.reviewId != null) {
      return const [
        ('spam', 'Spam / reklam'),
        ('abuse', 'Hakaret / uygunsuz'),
        ('wrong_info', 'Yanlış bilgi'),
        ('copyright', 'Telif ihlali'),
        ('illegal', 'Yasa dışı'),
        ('other', 'Diğer'),
      ];
    }
    if (widget.menuItemPhotoId != null) {
      return const [
        ('copyright', 'Telif ihlali'),
        ('spam', 'Spam / reklam'),
        ('wrong_info', 'Yanlış görsel'),
        ('illegal', 'Yasa dışı'),
        ('other', 'Diğer'),
      ];
    }
    return const [
      ('wrong_info', 'Yanlış bilgi'),
      ('closed', 'İşletme kapandı'),
      ('moved', 'Taşındı'),
      ('wrong_price', 'Fiyat yanlış'),
      ('spam', 'Spam / reklam'),
      ('copyright', 'Telif ihlali'),
      ('illegal', 'Yasa dışı'),
      ('other', 'Diğer'),
    ];
  }

  @override
  void initState() {
    super.initState();
    final initialReason = widget.initialReason;
    if (initialReason != null && _reasons.any((r) => r.$1 == initialReason)) {
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
    final st = widget.reviewId != null
        ? ref.watch(reviewReportControllerProvider(widget.reviewId!))
        : (widget.menuItemPhotoId != null
              ? ref.watch(
                  menuPhotoReportControllerProvider(widget.menuItemPhotoId!),
                )
              : ref.watch(reportControllerProvider(widget.businessId!)));
    final isLoading = st.status == ReportStatus.loading;
    final errorText = st.status == ReportStatus.error
        ? (st.errorCode == 'rate_limited_24h'
              ? widget.rateLimitText
              : (st.message ?? 'Bir hata oluştu.'))
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
          const Text(
            'Bildir',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (widget.businessId != null) ...[
            const Text(
              'Çok sayıda yanlış bilgi bildirimi görünürlüğü düşürür. '
              'İşletme sahibi doğruladıktan sonra tekrar yükselir.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          DropdownButtonFormField<String>(
            initialValue: reason,
            items: _reasons
                .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                .toList(),
            onChanged: isLoading
                ? null
                : (v) => setState(() => reason = v ?? 'other'),
            decoration: const InputDecoration(labelText: 'Sebep'),
          ),
          const SizedBox(height: 12),
          if (showCopyright) ...[
            TextField(
              controller: copyrightUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'İhlal URL (fotoğraf bağlantısı)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: copyrightOwnerCtrl,
              decoration: const InputDecoration(
                labelText: 'Hak sahibi adı (opsiyonel)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: copyrightEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Hak sahibi e-posta (opsiyonel)',
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: detailsCtrl,
            maxLength: 500,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Detaylar (opsiyonel)',
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
              child: Text(isLoading ? 'Gönderiliyor...' : 'Gönder'),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final details = _buildDetails();
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
        const SnackBar(content: Text('Teşekkürler, incelenecek.')),
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
      ).showSnackBar(SnackBar(content: Text(res.error ?? 'Bir hata oluştu.')));
    }
  }

  String? _buildDetails() {
    final base = detailsCtrl.text.trim();
    if (reason != 'copyright') {
      return base.isEmpty ? null : base;
    }
    final url = copyrightUrlCtrl.text.trim();
    final owner = copyrightOwnerCtrl.text.trim();
    final email = copyrightEmailCtrl.text.trim();
    final parts = <String>[];
    if (url.isNotEmpty) parts.add('İhlal URL: $url');
    if (owner.isNotEmpty) parts.add('Hak sahibi: $owner');
    if (email.isNotEmpty) parts.add('E-posta: $email');
    if (base.isNotEmpty) parts.add('Not: $base');
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }
}

