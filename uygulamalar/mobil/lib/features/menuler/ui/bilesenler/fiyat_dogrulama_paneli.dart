import 'package:flutter/material.dart';

import '../../../../uygulama/tema/renkler.dart';
import '../../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../shared/ui/tasarim_sistemi.dart';

typedef VerifyPriceSubmit =
    Future<void> Function({
      required bool isPriceCorrect,
      int? correctedPriceCents,
    });

enum VerifyPriceCtaPlacement { top, bottom }

class VerifyPriceBottomSheet extends StatefulWidget {
  const VerifyPriceBottomSheet({
    super.key,
    required this.itemName,
    required this.currentPriceLabel,
    required this.onSubmit,
    this.ctaPlacement = VerifyPriceCtaPlacement.bottom,
  });

  final String itemName;
  final String currentPriceLabel;
  final VerifyPriceSubmit onSubmit;
  final VerifyPriceCtaPlacement ctaPlacement;

  static Future<void> show(
    BuildContext context, {
    required String itemName,
    required String currentPriceLabel,
    required VerifyPriceSubmit onSubmit,
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
        ctaPlacement: ctaPlacement,
      ),
    );
  }

  @override
  State<VerifyPriceBottomSheet> createState() => _VerifyPriceBottomSheetState();
}

class _VerifyPriceBottomSheetState extends State<VerifyPriceBottomSheet> {
  final _priceController = TextEditingController();
  bool? _isCorrect;
  bool _submitting = false;

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
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
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

