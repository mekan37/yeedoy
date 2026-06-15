import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/analytics/analytics_client.dart';
import '../../../../core/analytics/analytics_repository.dart';
import '../../../../core/analytics/app_events.dart';
import '../../../../core/content/content_moderation.dart';
import '../../../../core/errors/app_error_codes.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/media/media_upload_repository.dart';
import '../../../shared/ui/design_system.dart';
import '../../data/menu_repository.dart';
import '../../data/offline_verify_queue.dart';

/// Bottom sheet for submitting a new price suggestion for a menu item.
class PriceSuggestionSheet extends ConsumerStatefulWidget {
  const PriceSuggestionSheet({
    super.key,
    required this.menuItemId,
    required this.businessId,
    required this.menuId,
  });
  final String menuItemId;
  final String businessId;
  final String menuId;

  @override
  ConsumerState<PriceSuggestionSheet> createState() =>
      _PriceSuggestionSheetState();
}

class _PriceSuggestionSheetState extends ConsumerState<PriceSuggestionSheet> {
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  bool _submitting = false;
  bool _uploading = false;
  Object? _error;
  bool _vatIncluded = true;
  String? _evidenceUrl;

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
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
            Text(t.priceVerification, style: context.sectionTitleStyle),
            const SizedBox(height: 10),
            Text(
              t.priceVerificationSteps,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (_error != null) ...[
              Text(
                _priceSuggestionErrorText(context, _error),
                style: const TextStyle(color: AppColors.danger),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.newPriceTry),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(labelText: t.note),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: (_submitting || _uploading) ? null : _pickEvidence,
              icon: _uploading
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
            const SizedBox(height: 8),
            Row(
              children: [
                Text(t.vatIncluded),
                const Spacer(),
                Switch(
                  value: _vatIncluded,
                  onChanged: (value) => setState(() => _vatIncluded = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.submit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final parsed = _parsePrice(_priceController.text.trim());
    final noteText = _noteController.text.trim();
    final moderation = await ContentModeration.instance.validateNote(noteText);
    if (moderation != null) {
      setState(() => _error = moderation.code);
      return;
    }
    if (parsed == null) {
      setState(() => _error = 'invalid_price');
      return;
    }
    final cents = (parsed * 100).round();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final clientId = await getAnalyticsClientId();
      final result = await ref
          .read(menuRepositoryProvider)
          .submitMenuItemPriceSuggestion(
            menuItemId: widget.menuItemId,
            suggestedPriceCents: cents,
            currency: 'TRY',
            clientId: clientId,
            capturedAt: DateTime.now(),
            note: noteText,
            evidenceUrl: _evidenceUrl,
            businessId: widget.businessId,
            menuId: widget.menuId,
          );
      if (!result.ok) {
        setState(() {
          _submitting = false;
          _error = result.error ?? 'unknown';
        });
        return;
      }
      if (!mounted) return;
      await ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: 'price_suggestion_submitted',
            businessId: widget.businessId,
            source: 'menu_item_price_suggestion',
            clientId: clientId,
            meta: {'menu_item_id': widget.menuItemId},
          );
      await ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.verifyPriceSubmit,
            businessId: widget.businessId,
            source: 'menu_item_price_suggestion',
            clientId: clientId,
            meta: {'menu_item_id': widget.menuItemId},
          );
      if (!mounted) return;
      Navigator.pop(context, result);
    } on OfflineQueuedException {
      if (!mounted) return;
      Navigator.pop(
        context,
        const PriceSuggestionSubmissionResult(ok: true, queued: true),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = AppErrorMapper.message(e);
      if (msg.contains('rate_limited_24h')) {
        setState(() {
          _submitting = false;
          _error = 'rate_limited_24h';
        });
        return;
      }
      setState(() {
        _submitting = false;
        _error = e;
      });
    }
  }

  Future<void> _pickEvidence() async {
    setState(() => _uploading = true);
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
      if (mounted) setState(() => _uploading = false);
    }
  }
}

double? _parsePrice(String value) {
  final cleaned = value.replaceAll(',', '.');
  return double.tryParse(cleaned);
}

String _priceSuggestionErrorText(BuildContext context, Object? error) {
  final t = AppLocalizations.of(context);
  if (error == null) return '';
  if (error == 'invalid_price') return t.priceInvalid;
  if (error == AppErrorCodes.containsLinkOrPhone) {
    return t.noteNoLinkPhone;
  }
  if (error == AppErrorCodes.containsProfanity) {
    return t.noteContainsProfanity;
  }
  if (error == AppErrorCodes.emojiSpam) {
    return t.noteTooManyEmoji;
  }
  if (error == 'rate_limited_24h') {
    return t.rateLimited24h;
  }
  if (error == AppErrorCodes.priceSuggestionDailyRateLimited) {
    return t.dailyPriceSuggestionLimitReached;
  }
  if (error == 'bad_evidence_url') {
    return t.invalidEvidenceLink;
  }
  if (error == 'bad_currency') {
    return t.invalidCurrency;
  }
  return AppErrorMapper.message(error);
}
