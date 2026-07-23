import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/media/media_upload_repository.dart';
import '../../../shared/ui/design_system.dart';

typedef VerifyPriceSubmit =
    Future<void> Function({
      required bool isPriceCorrect,
      int? correctedPriceCents,
      String? evidenceUrl,
    });

enum VerifyPriceCtaPlacement { top, bottom }

class VerifyPriceBottomSheet extends ConsumerStatefulWidget {
  const VerifyPriceBottomSheet({
    super.key,
    required this.itemName,
    required this.currentPriceLabel,
    required this.onSubmit,
    required this.businessId,
    required this.menuItemId,
    this.ctaPlacement = VerifyPriceCtaPlacement.bottom,
  });

  final String itemName;
  final String currentPriceLabel;
  final VerifyPriceSubmit onSubmit;
  final String businessId;
  final String menuItemId;
  final VerifyPriceCtaPlacement ctaPlacement;

  static Future<void> show(
    BuildContext context, {
    required String itemName,
    required String currentPriceLabel,
    required VerifyPriceSubmit onSubmit,
    required String businessId,
    required String menuItemId,
    VerifyPriceCtaPlacement ctaPlacement = VerifyPriceCtaPlacement.bottom,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => VerifyPriceBottomSheet(
        itemName: itemName,
        currentPriceLabel: currentPriceLabel,
        onSubmit: onSubmit,
        businessId: businessId,
        menuItemId: menuItemId,
        ctaPlacement: ctaPlacement,
      ),
    );
  }

  @override
  ConsumerState<VerifyPriceBottomSheet> createState() =>
      _VerifyPriceBottomSheetState();
}

class _VerifyPriceBottomSheetState
    extends ConsumerState<VerifyPriceBottomSheet> {
  final _priceController = TextEditingController();
  bool? _isCorrect;
  bool _submitting = false;
  bool _uploadingEvidence = false;
  String? _evidenceUrl;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.verifyPriceIsCorrectQuestion,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.itemName} • ${widget.currentPriceLabel}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (widget.ctaPlacement == VerifyPriceCtaPlacement.top) ...[
              _buildSubmitButton(),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: t.verifyPriceCorrectAction,
                    variant: AppButtonVariant.secondary,
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _isCorrect = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: t.verifyPriceIncorrectAction,
                    variant: AppButtonVariant.ghost,
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _isCorrect = false),
                  ),
                ),
              ],
            ),
            if (_isCorrect == false) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t.verifyPriceCorrectPriceLabel,
                  hintText: t.verifyPriceCorrectPriceHint,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: (_submitting || _uploadingEvidence)
                    ? null
                    : _pickEvidence,
                icon: _uploadingEvidence
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_camera_outlined),
                label: Text(
                  _evidenceUrl == null ? t.addEvidencePhoto : t.evidenceAdded,
                ),
              ),
            ],
            if (widget.ctaPlacement == VerifyPriceCtaPlacement.bottom) ...[
              const SizedBox(height: 14),
              _buildSubmitButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final t = context.l10n;
    return AppButton(
      label: t.verify,
      fullWidth: true,
      onPressed: _submitting ? null : _submit,
    );
  }

  Future<void> _submit() async {
    final t = context.l10n;
    if (_isCorrect == null) {
      _showSnack(t.verifyPriceChooseCorrectnessFirst);
      return;
    }
    int? corrected;
    if (_isCorrect == false) {
      corrected = _parsePriceToCents(_priceController.text);
      if (corrected == null) {
        _showSnack(t.verifyPriceEnterValidPrice);
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        isPriceCorrect: _isCorrect!,
        correctedPriceCents: corrected,
        evidenceUrl: _evidenceUrl,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickEvidence() async {
    setState(() => _uploadingEvidence = true);
    try {
      final upload = await ref
          .read(mediaUploadRepositoryProvider)
          .pickAndUploadImage(
            title: 'price_proof_${widget.menuItemId}',
            businessId: widget.businessId,
            menuItemId: widget.menuItemId,
            critical: true,
          );
      if (upload == null) return;
      if (!mounted) return;
      setState(() => _evidenceUrl = upload.urlLarge);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => _uploadingEvidence = false);
    }
  }

  int? _parsePriceToCents(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;
    return (value * 100).round();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
