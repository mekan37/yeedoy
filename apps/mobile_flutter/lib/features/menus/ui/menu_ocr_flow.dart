import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../data/menu_repository.dart';
import '../data/wp_upload.dart';
import '../domain/menu_models.dart';
import '../../../features/shared/ui/design_system.dart';

Future<void> startMenuPriceOcrFlow({
  required BuildContext context,
  required MenuRepository repo,
  required List<MenuItem> menuItems,
}) async {
  final t = AppLocalizations.of(context);
  final source = await _pickImageSource(context);
  if (source == null) return;

  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 2200,
    imageQuality: 92,
  );
  if (picked == null) return;

  if (!context.mounted) return;
  _showProgress(context, message: t.menuReading);

  List<_OcrDetection> detections = const [];
  try {
    detections = await _runOcr(picked.path);
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
    return;
  }

  if (!context.mounted) return;
  Navigator.of(context).pop();

  if (detections.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.noPriceDetectionFound)));
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return _MenuPriceOcrMatchSheet(
        repo: repo,
        menuItems: menuItems,
        detections: detections,
      );
    },
  );
}

Future<void> startReceiptOcrFlow({
  required BuildContext context,
  required SupabaseClient client,
  required MenuRepository repo,
  required String businessId,
  required List<MenuItem> menuItems,
}) async {
  final t = AppLocalizations.of(context);
  if (kIsWeb) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.receiptOcrNotSupportedWeb)));
    return;
  }

  final source = await _pickImageSource(context);
  if (source == null) return;

  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 2200,
    imageQuality: 92,
  );
  if (picked == null) return;

  if (!context.mounted) return;
  _showProgress(context, message: t.receiptReading);

  List<_OcrDetection> detections = const [];
  try {
    detections = await _runOcr(picked.path);
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
    return;
  }

  if (!context.mounted) return;
  Navigator.of(context).pop();

  if (detections.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.noPriceFoundOnReceipt)));
    return;
  }

  _showProgress(context, message: t.receiptUploading);
  WpUploadResult? upload;
  try {
    upload = await uploadWpImageFromXFile(
      client: client,
      file: picked,
      title: 'receipt_${businessId}_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      critical: true,
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
    return;
  }

  if (!context.mounted) return;
  Navigator.of(context).pop();

  if (upload == null || upload.url.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.receiptUploadFailed)));
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return _ReceiptOcrMatchSheet(
        repo: repo,
        menuItems: menuItems,
        detections: detections,
        businessId: businessId,
        imageUrl: upload!.url,
      );
    },
  );
}

Future<ImageSource?> _pickImageSource(BuildContext context) async {
  final t = AppLocalizations.of(context);
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(t.camera),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.gallery),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<List<_OcrDetection>> _runOcr(String path) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final input = InputImage.fromFilePath(path);
    final result = await recognizer.processImage(input);
    final detections = <_OcrDetection>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final hit = _extractPrice(line.text);
        if (hit == null) continue;
        detections.add(
          _OcrDetection(
            line: line.text.trim(),
            priceCents: hit.cents,
            isFallback: hit.isFallback,
          ),
        );
      }
    }
    return detections;
  } finally {
    await recognizer.close();
  }
}

_PriceHit? _extractPrice(String text) {
  final currencyPattern = RegExp(
    r'(?:₺|TL|TRY)\\s*([0-9]{1,4}(?:[.,][0-9]{1,2})?)|([0-9]{1,4}(?:[.,][0-9]{1,2})?)\\s*(?:₺|TL|TRY)',
    caseSensitive: false,
  );
  final currencyMatch = currencyPattern.firstMatch(text);
  if (currencyMatch != null) {
    final raw = (currencyMatch.group(1) ?? currencyMatch.group(2) ?? '').trim();
    final cents = _parseCents(raw);
    if (cents != null) return _PriceHit(cents: cents, isFallback: false);
  }

  final fallbackPattern = RegExp(r'\b([1-9][0-9]{1,3}(?:[.,][0-9]{1,2})?)\b');
  final fallbackMatch = fallbackPattern.firstMatch(text);
  if (fallbackMatch != null) {
    final raw = fallbackMatch.group(1);
    if (raw != null) {
      final cents = _parseCents(raw);
      if (cents != null) return _PriceHit(cents: cents, isFallback: true);
    }
  }
  return null;
}

int? _parseCents(String raw) {
  final normalized = raw.replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null) return null;
  if (value <= 0) return null;
  return (value * 100).round();
}

void _showProgress(BuildContext context, {required String message}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      );
    },
  );
}

class _MenuPriceOcrMatchSheet extends StatefulWidget {
  const _MenuPriceOcrMatchSheet({
    required this.repo,
    required this.menuItems,
    required this.detections,
  });

  final MenuRepository repo;
  final List<MenuItem> menuItems;
  final List<_OcrDetection> detections;

  @override
  State<_MenuPriceOcrMatchSheet> createState() =>
      _MenuPriceOcrMatchSheetState();
}

class _ReceiptOcrMatchSheet extends StatefulWidget {
  const _ReceiptOcrMatchSheet({
    required this.repo,
    required this.menuItems,
    required this.detections,
    required this.businessId,
    required this.imageUrl,
  });

  final MenuRepository repo;
  final List<MenuItem> menuItems;
  final List<_OcrDetection> detections;
  final String businessId;
  final String imageUrl;

  @override
  State<_ReceiptOcrMatchSheet> createState() => _ReceiptOcrMatchSheetState();
}

class _ReceiptOcrMatchSheetState extends State<_ReceiptOcrMatchSheet> {
  late final List<_OcrRow> _rows = widget.detections
      .map((d) => _OcrRow.fromDetection(d))
      .toList();
  int _autoMatched = 0;

  @override
  void initState() {
    super.initState();
    _autoMatched = _autoMatchRows();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.matchReceipt,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_autoMatched > 0) ...[
            Text(
              t.autoMatchedRowsCheck(_autoMatched),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _rows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = _rows[index];
                return AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.line,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (row.isFallback)
                            AppChip.status(
                              label: t.unlabeled,
                              status: AppChipStatus.warning,
                            ),
                          SizedBox(
                            width: 130,
                            child: TextField(
                              controller: row.controller,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: t.priceTry,
                                isDense: true,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: Autocomplete<MenuItem>(
                              displayStringForOption: (item) => item.name,
                              optionsBuilder: (value) {
                                final q = value.text.trim().toLowerCase();
                                if (q.isEmpty) {
                                  return widget.menuItems.take(8);
                                }
                                return widget.menuItems.where(
                                  (item) => item.name.toLowerCase().contains(q),
                                );
                              },
                              onSelected: (item) {
                                setState(() {
                                  row.menuItem = item;
                                  row.suggestedName = item.name;
                                  row.didPrefill = true;
                                });
                              },
                              fieldViewBuilder:
                                  (context, controller, focusNode, onSubmit) {
                                    if (!row.didPrefill &&
                                        row.suggestedName != null) {
                                      controller.text = row.suggestedName!;
                                      controller.selection =
                                          TextSelection.collapsed(
                                            offset: controller.text.length,
                                          );
                                      row.didPrefill = true;
                                    }
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: t.selectMenuItem,
                                        isDense: true,
                                        suffixIcon: row.menuItem != null
                                            ? const Icon(Icons.check, size: 18)
                                            : null,
                                      ),
                                    );
                                  },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _rows.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _submit, child: Text(t.sendReceipt)),
          ),
        ],
      ),
    );
  }

  int _autoMatchRows() {
    var matched = 0;
    for (final row in _rows) {
      final best = _findBestMenuItem(row.line, widget.menuItems);
      if (best != null) {
        row.menuItem = best;
        row.suggestedName = best.name;
        matched += 1;
      }
    }
    return matched;
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final selected = _rows.where((row) => row.menuItem != null).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.selectAtLeastOneItem)));
      return;
    }

    for (final row in selected) {
      final cents = _parseCents(row.controller.text);
      if (cents == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.invalidPriceExists)));
        return;
      }
      row.priceCents = cents;
    }

    _showProgress(context, message: t.sendingReceipt);
    try {
      for (final row in selected) {
        await widget.repo.submitMenuItemPriceSuggestion(
          menuItemId: row.menuItem!.id,
          suggestedPriceCents: row.priceCents,
          currency: 'TRY',
          note: 'receipt_ocr',
        );
      }

      final matches = [
        for (final row in selected)
          {
            'menu_item_id': row.menuItem!.id,
            'detected_price_cents': row.priceCents,
          },
      ];

      await widget.repo.submitReceiptSubmission(
        businessId: widget.businessId,
        imageUrl: widget.imageUrl,
        matches: matches,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.receiptSent)));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }
}

class _MenuPriceOcrMatchSheetState extends State<_MenuPriceOcrMatchSheet> {
  late final List<_OcrRow> _rows = widget.detections
      .map((d) => _OcrRow.fromDetection(d))
      .toList();
  int _autoMatched = 0;

  @override
  void initState() {
    super.initState();
    _autoMatched = _autoMatchRows();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.matchPrices,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_autoMatched > 0) ...[
            Text(
              t.autoMatchedRowsCheck(_autoMatched),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _rows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = _rows[index];
                return AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.line,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (row.isFallback)
                            AppChip.status(
                              label: t.unlabeled,
                              status: AppChipStatus.warning,
                            ),
                          SizedBox(
                            width: 130,
                            child: TextField(
                              controller: row.controller,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: t.priceTry,
                                isDense: true,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: Autocomplete<MenuItem>(
                              displayStringForOption: (item) => item.name,
                              optionsBuilder: (value) {
                                final q = value.text.trim().toLowerCase();
                                if (q.isEmpty) {
                                  return widget.menuItems.take(8);
                                }
                                return widget.menuItems.where(
                                  (item) => item.name.toLowerCase().contains(q),
                                );
                              },
                              onSelected: (item) {
                                setState(() {
                                  row.menuItem = item;
                                  row.suggestedName = item.name;
                                  row.didPrefill = true;
                                });
                              },
                              fieldViewBuilder:
                                  (context, controller, focusNode, onSubmit) {
                                    if (!row.didPrefill &&
                                        row.suggestedName != null) {
                                      controller.text = row.suggestedName!;
                                      controller.selection =
                                          TextSelection.collapsed(
                                            offset: controller.text.length,
                                          );
                                      row.didPrefill = true;
                                    }
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: t.selectMenuItem,
                                        isDense: true,
                                        suffixIcon: row.menuItem != null
                                            ? const Icon(Icons.check, size: 18)
                                            : null,
                                      ),
                                    );
                                  },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _rows.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: Text(t.sendReceiptSuggestions),
            ),
          ),
        ],
      ),
    );
  }

  int _autoMatchRows() {
    var matched = 0;
    for (final row in _rows) {
      final best = _findBestMenuItem(row.line, widget.menuItems);
      if (best != null) {
        row.menuItem = best;
        row.suggestedName = best.name;
        matched += 1;
      }
    }
    return matched;
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final selected = _rows.where((row) => row.menuItem != null).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.selectAtLeastOneItem)));
      return;
    }

    for (final row in selected) {
      final cents = _parseCents(row.controller.text);
      if (cents == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.invalidPriceExists)));
        return;
      }
      row.priceCents = cents;
    }

    _showProgress(context, message: t.sendingReceiptSuggestions);
    try {
      for (final row in selected) {
        await widget.repo.submitMenuItemPriceSuggestion(
          menuItemId: row.menuItem!.id,
          suggestedPriceCents: row.priceCents,
          currency: 'TRY',
          note: 'ocr',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.priceSuggestionsSent)));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }
}

class _OcrRow {
  _OcrRow({
    required this.line,
    required this.isFallback,
    required this.priceCents,
  }) : controller = TextEditingController(text: _formatCents(priceCents));

  factory _OcrRow.fromDetection(_OcrDetection detection) {
    return _OcrRow(
      line: detection.line,
      isFallback: detection.isFallback,
      priceCents: detection.priceCents,
    );
  }

  final String line;
  final bool isFallback;
  int priceCents;
  MenuItem? menuItem;
  String? suggestedName;
  bool didPrefill = false;
  final TextEditingController controller;
}

String _formatCents(int cents) {
  final value = cents / 100.0;
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

class _OcrDetection {
  const _OcrDetection({
    required this.line,
    required this.priceCents,
    required this.isFallback,
  });

  final String line;
  final int priceCents;
  final bool isFallback;
}

class _PriceHit {
  const _PriceHit({required this.cents, required this.isFallback});

  final int cents;
  final bool isFallback;
}

String _normalizeText(String input) {
  var text = input.toLowerCase();
  text = text
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u');
  text = text.replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ');
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text;
}

int _scoreMatch(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 100;
  if (a.contains(b) || b.contains(a)) {
    final minLen = a.length < b.length ? a.length : b.length;
    return 80 + (minLen > 10 ? 10 : minLen);
  }
  final aTokens = a.split(' ');
  final bTokens = b.split(' ');
  var overlap = 0;
  for (final t in aTokens) {
    if (bTokens.contains(t)) overlap++;
  }
  if (overlap == 0) return 0;
  return 50 + overlap * 10;
}

MenuItem? _findBestMenuItem(String line, List<MenuItem> items) {
  final normalizedLine = _normalizeText(line);
  if (normalizedLine.isEmpty) return null;
  MenuItem? best;
  var bestScore = 0;
  for (final item in items) {
    final score = _scoreMatch(normalizedLine, _normalizeText(item.name));
    if (score > bestScore) {
      bestScore = score;
      best = item;
    }
  }
  return bestScore >= 60 ? best : null;
}

