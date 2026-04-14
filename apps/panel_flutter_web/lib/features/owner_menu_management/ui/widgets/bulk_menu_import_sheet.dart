import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../../../core/web/download_utils.dart';
import '../../domain/bulk_import_models.dart';

// ─── Sheet entry point ────────────────────────────────────────────────────────

class BulkMenuImportSheet extends ConsumerStatefulWidget {
  const BulkMenuImportSheet({super.key, required this.menuId});
  final String menuId;

  @override
  ConsumerState<BulkMenuImportSheet> createState() =>
      _BulkMenuImportSheetState();
}

class _BulkMenuImportSheetState extends ConsumerState<BulkMenuImportSheet> {
  // Steps: 0=instructions, 1=preview, 2=result
  int _step = 0;
  bool _loading = false;
  String? _error;

  List<BulkImportRow> _rows = [];
  BulkImportResult? _result;

  // ── Template download ─────────────────────────────────────────────────────

  void _downloadTemplate() {
    final xls = Excel.createExcel();
    xls.rename('Sheet1', 'Menü');
    final sheet = xls['Menü'];

    // Header
    final headers = [
      'Bölüm Adı',
      'Ürün Adı',
      'Açıklama',
      'Fiyat (₺)',
      'Mevcut? (E/H)',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Sample rows
    final samples = [
      ['Çorbalar', 'Mercimek Çorbası', 'Geleneksel tarif', 75.0, 'E'],
      ['Çorbalar', 'Domates Çorbası', '', 65.0, 'E'],
      ['Ana Yemekler', 'Izgara Köfte', '200g, yanında pilav', 180.0, 'E'],
      ['Ana Yemekler', 'Tavuk Şiş', 'Orman mantarlı', 155.0, 'E'],
      ['Tatlılar', 'Baklava', 'Fıstıklı', 90.0, 'E'],
      ['İçecekler', 'Ayran', '300ml', 25.0, 'E'],
    ];
    for (final row in samples) {
      sheet.appendRow([
        TextCellValue(row[0] as String),
        TextCellValue(row[1] as String),
        TextCellValue(row[2] as String),
        DoubleCellValue(row[3] as double),
        TextCellValue(row[4] as String),
      ]);
    }

    final bytes = xls.save();
    if (bytes != null) {
      downloadBytes(
        bytes: bytes,
        fileName: 'yeedoy_menu_sablonu.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  // ── File pick & parse ─────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final bytes = result.files.first.bytes;
      if (bytes == null) throw Exception('Dosya okunamadı');
      _rows = _parseExcel(bytes);
      setState(() => _step = 1);
    } catch (e) {
      setState(() => _error = 'Dosya hatası: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<BulkImportRow> _parseExcel(Uint8List bytes) {
    final xls = Excel.decodeBytes(bytes);
    final sheetName = xls.tables.keys.first;
    final sheet = xls.tables[sheetName]!;
    final dataRows = sheet.rows.skip(1); // skip header

    final result = <BulkImportRow>[];
    int idx = 2; // 1-based, header is row 1

    for (final row in dataRows) {
      String cell(int col) =>
          (row.length > col ? row[col]?.value?.toString() ?? '' : '').trim();

      final section = cell(0);
      final name = cell(1);
      final desc = cell(2);
      final priceRaw = cell(3);
      final availRaw = cell(4).toUpperCase();

      // Skip entirely blank rows
      if (section.isEmpty && name.isEmpty && priceRaw.isEmpty) {
        idx++;
        continue;
      }

      String? error;
      int priceCents = 0;

      if (section.isEmpty) {
        error = 'Bölüm adı boş';
      } else if (name.isEmpty || name.length < 2) {
        error = 'Ürün adı çok kısa';
      } else {
        final priceVal = double.tryParse(priceRaw.replaceAll(',', '.'));
        if (priceRaw.isNotEmpty && priceVal == null) {
          error = 'Geçersiz fiyat: "$priceRaw"';
        } else if (priceVal != null && priceVal < 0) {
          error = 'Fiyat negatif olamaz';
        } else {
          priceCents = ((priceVal ?? 0) * 100).round();
        }
      }

      final isAvail = availRaw != 'H' && availRaw != 'N' && availRaw != 'FALSE';

      result.add(BulkImportRow(
        rowIndex: idx,
        sectionName: section,
        itemName: name,
        description: desc,
        priceCents: priceCents,
        isAvailable: isAvail,
        error: error,
      ));
      idx++;
    }
    return result;
  }

  // ── Confirm & upload ──────────────────────────────────────────────────────

  Future<void> _upload() async {
    final validRows = _rows.where((r) => !r.hasError).toList();
    if (validRows.isEmpty) return;
    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseProvider);
      final res = await client.rpc(
        'owner_bulk_import_menu_items_v1',
        params: {
          'p_menu_id': widget.menuId,
          'p_rows': validRows.map((r) => r.toRpcMap()).toList(),
        },
      );
      final data = res as Map<String, dynamic>?;
      if (data?['ok'] != true) {
        throw Exception(data?['error'] ?? 'import_failed');
      }
      setState(() {
        _result = BulkImportResult.fromMap(data!);
        _step = 2;
      });
    } catch (e) {
      setState(() => _error = 'Yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: switch (_step) {
              0 => _StepInstructions(
                  onDownload: _downloadTemplate,
                  onPickFile: _loading ? null : _pickFile,
                  loading: _loading,
                  error: _error,
                ),
              1 => _StepPreview(
                  rows: _rows,
                  loading: _loading,
                  error: _error,
                  onBack: () => setState(() => _step = 0),
                  onConfirm: _loading ? null : _upload,
                ),
              _ => _StepResult(
                  result: _result!,
                  onClose: () => Navigator.pop(context, true),
                ),
            },
          ),
        ],
      ),
    );
  }
}

// ─── Step 0: Instructions ─────────────────────────────────────────────────────

class _StepInstructions extends StatelessWidget {
  const _StepInstructions({
    required this.onDownload,
    required this.onPickFile,
    required this.loading,
    this.error,
  });

  final VoidCallback onDownload;
  final VoidCallback? onPickFile;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toplu Menü Yükleme',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Excel şablonunu indirin, doldurun ve yükleyin. '
            'Yüzlerce ürün tek seferde eklenir.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Steps
          _HowToStep(
            num: '1',
            title: 'Şablonu İndir',
            desc: 'Örnek verilerle dolu Excel şablonu indirilir.',
            action: OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Şablonu İndir (.xlsx)'),
            ),
          ),
          const SizedBox(height: 12),
          const _HowToStep(
            num: '2',
            title: 'Şablonu Doldur',
            desc: 'Bölüm adı, ürün adı, açıklama, fiyat ve '
                'mevcut bilgilerini girin. '
                'Her satır bir ürün.',
          ),
          const SizedBox(height: 12),
          _HowToStep(
            num: '3',
            title: 'Dosyayı Yükle',
            desc: 'Doldurulmuş Excel dosyasını seçin.',
            action: FilledButton.icon(
              onPressed: onPickFile,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_file_outlined, size: 16),
              label: Text(loading ? 'Yükleniyor…' : 'Dosya Seç'),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(error!,
                  style: const TextStyle(
                      color: AppColors.danger, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 20),
          // Column guide
          const Text(
            'Şablon Sütunları',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const _ColumnGuideTable(),
        ],
      ),
    );
  }
}

class _HowToStep extends StatelessWidget {
  const _HowToStep({
    required this.num,
    required this.title,
    required this.desc,
    this.action,
  });

  final String num;
  final String title;
  final String desc;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            num,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12)),
              if (action != null) ...[
                const SizedBox(height: 8),
                action!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ColumnGuideTable extends StatelessWidget {
  const _ColumnGuideTable();

  @override
  Widget build(BuildContext context) {
    const cols = [
      ('A', 'Bölüm Adı', 'Zorunlu — ör: Çorbalar'),
      ('B', 'Ürün Adı', 'Zorunlu — en az 2 karakter'),
      ('C', 'Açıklama', 'İsteğe bağlı'),
      ('D', 'Fiyat (₺)', 'Sayı — ör: 75 veya 75,50'),
      ('E', 'Mevcut? (E/H)', 'E=Evet, H=Hayır (varsayılan: E)'),
    ];
    return Column(
      children: cols
          .map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(c.$1,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB))),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 130,
                      child: Text(c.$2,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(c.$3,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ─── Step 1: Preview ──────────────────────────────────────────────────────────

class _StepPreview extends StatelessWidget {
  const _StepPreview({
    required this.rows,
    required this.loading,
    this.error,
    required this.onBack,
    required this.onConfirm,
  });

  final List<BulkImportRow> rows;
  final bool loading;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final valid = rows.where((r) => !r.hasError).length;
    final invalid = rows.where((r) => r.hasError).length;
    final sections = rows
        .where((r) => !r.hasError)
        .map((r) => r.sectionName)
        .toSet()
        .length;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Önizleme',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              // Summary chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _SummaryChip(
                    label: '$valid ürün eklenecek',
                    color: const Color(0xFF16A34A),
                    icon: Icons.check_circle_outline,
                  ),
                  _SummaryChip(
                    label: '$sections bölüm',
                    color: const Color(0xFF2563EB),
                    icon: Icons.folder_outlined,
                  ),
                  if (invalid > 0)
                    _SummaryChip(
                      label: '$invalid hata var',
                      color: AppColors.danger,
                      icon: Icons.error_outline,
                    ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 12)),
              ],
            ],
          ),
        ),
        // Table
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(36),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.8),
                3: FlexColumnWidth(1.0),
                4: FixedColumnWidth(60),
              },
              children: [
                // Header
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                  ),
                  children: ['#', 'Bölüm', 'Ürün', 'Fiyat', 'Mevcut']
                      .map((h) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            child: Text(h,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted)),
                          ))
                      .toList(),
                ),
                ...rows.map((row) => _buildRow(row)),
              ],
            ),
          ),
        ),
        // Footer actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: onBack,
                child: const Text('Geri'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: valid == 0 ? null : onConfirm,
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('$valid Ürünü Yükle'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildRow(BulkImportRow row) {
    final bgColor = row.hasError
        ? const Color(0xFFFEF2F2)
        : row.rowIndex.isEven
            ? Colors.white
            : const Color(0xFFFAFAFA);

    Widget cell(String text, {bool muted = false, bool bold = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: muted ? AppColors.muted : Colors.black87,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );

    return TableRow(
      decoration: BoxDecoration(color: bgColor),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: row.hasError
              ? Tooltip(
                  message: row.error!,
                  child: const Icon(Icons.error_outline,
                      size: 14, color: AppColors.danger),
                )
              : Text('${row.rowIndex}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.muted)),
        ),
        cell(row.sectionName),
        cell(row.itemName, bold: true),
        cell(row.priceCents == 0
            ? '—'
            : '₺${row.priceTl.toStringAsFixed(2)}'),
        cell(row.isAvailable ? 'E' : 'H', muted: true),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ─── Step 2: Result ───────────────────────────────────────────────────────────

class _StepResult extends StatelessWidget {
  const _StepResult({required this.result, required this.onClose});
  final BulkImportResult result;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outlined,
              size: 48, color: Color(0xFF16A34A)),
          const SizedBox(height: 12),
          const Text(
            'Yükleme Tamamlandı!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _ResultRow(
            icon: Icons.add_box_outlined,
            color: const Color(0xFF16A34A),
            label: '${result.inserted} ürün eklendi',
          ),
          const SizedBox(height: 8),
          _ResultRow(
            icon: Icons.folder_open_outlined,
            color: const Color(0xFF2563EB),
            label: '${result.sectionsCreated} yeni bölüm oluşturuldu',
          ),
          if (result.skipped > 0) ...[
            const SizedBox(height: 8),
            _ResultRow(
              icon: Icons.skip_next_outlined,
              color: AppColors.muted,
              label: '${result.skipped} satır atlandı',
            ),
          ],
          if (result.rpcErrors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${result.rpcErrors.length} hata:',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.danger),
            ),
            ...result.rpcErrors.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Satır ${e['row']}: ${e['reason']}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.danger),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onClose,
              child: const Text('Menüye Dön'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label,
            style:
                TextStyle(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
