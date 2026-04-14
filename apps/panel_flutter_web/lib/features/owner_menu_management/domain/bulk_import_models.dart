class BulkImportRow {
  const BulkImportRow({
    required this.rowIndex,
    required this.sectionName,
    required this.itemName,
    this.description = '',
    this.priceCents = 0,
    this.isAvailable = true,
    this.error,
  });

  final int rowIndex;
  final String sectionName;
  final String itemName;
  final String description;
  final int priceCents;
  final bool isAvailable;
  final String? error;

  bool get hasError => error != null;

  double get priceTl => priceCents / 100;

  Map<String, dynamic> toRpcMap() => {
        'section': sectionName,
        'name': itemName,
        'description': description,
        'price_cents': priceCents,
        'is_available': isAvailable,
      };

  BulkImportRow withError(String err) => BulkImportRow(
        rowIndex: rowIndex,
        sectionName: sectionName,
        itemName: itemName,
        description: description,
        priceCents: priceCents,
        isAvailable: isAvailable,
        error: err,
      );
}

class BulkImportResult {
  const BulkImportResult({
    required this.inserted,
    required this.sectionsCreated,
    required this.skipped,
    required this.rpcErrors,
  });

  final int inserted;
  final int sectionsCreated;
  final int skipped;
  final List<Map<String, dynamic>> rpcErrors;

  factory BulkImportResult.fromMap(Map<String, dynamic> m) =>
      BulkImportResult(
        inserted: (m['inserted'] as num? ?? 0).toInt(),
        sectionsCreated: (m['sections_created'] as num? ?? 0).toInt(),
        skipped: (m['skipped'] as num? ?? 0).toInt(),
        rpcErrors: ((m['errors'] as List?) ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );
}
