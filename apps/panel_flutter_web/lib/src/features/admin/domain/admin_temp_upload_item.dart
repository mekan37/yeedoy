class AdminTempUploadItem {
  const AdminTempUploadItem({
    required this.id,
    required this.businessId,
    required this.kind,
    required this.storageBucket,
    required this.storagePath,
    required this.status,
    required this.createdAt,
    this.previewUrl,
  });

  final String id;
  final String businessId;
  final String kind;
  final String storageBucket;
  final String storagePath;
  final String status;
  final DateTime createdAt;
  final String? previewUrl;

  factory AdminTempUploadItem.fromMap(Map<String, dynamic> map) {
    return AdminTempUploadItem(
      id: (map['id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      kind: (map['kind'] ?? '').toString(),
      storageBucket: (map['storage_bucket'] ?? 'temp').toString(),
      storagePath: (map['storage_path'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  AdminTempUploadItem copyWith({String? previewUrl}) {
    return AdminTempUploadItem(
      id: id,
      businessId: businessId,
      kind: kind,
      storageBucket: storageBucket,
      storagePath: storagePath,
      status: status,
      createdAt: createdAt,
      previewUrl: previewUrl ?? this.previewUrl,
    );
  }
}
