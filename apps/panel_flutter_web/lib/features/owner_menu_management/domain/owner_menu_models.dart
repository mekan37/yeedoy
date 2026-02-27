class OwnerMenu {
  OwnerMenu({
    required this.id,
    required this.businessId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.version = 1,
    this.updatedAt,
    this.source = 'owner',
    this.confidenceScore = 0,
    this.kind,
    this.activeFrom,
    this.activeTo,
  });

  final String id;
  final String businessId;
  final String title;
  final String status;
  final DateTime createdAt;
  final int version;
  final DateTime? updatedAt;
  final String source;
  final double confidenceScore;
  final String? kind;
  final String? activeFrom;
  final String? activeTo;

  factory OwnerMenu.fromMap(Map<String, dynamic> map) {
    return OwnerMenu(
      id: (map['id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      version: _asIntNullable(map['version']) ?? 1,
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
      source: (map['source'] ?? 'owner').toString(),
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0,
      kind: map['kind']?.toString(),
      activeFrom: map['active_from']?.toString(),
      activeTo: map['active_to']?.toString(),
      createdAt: _asDate(map['created_at']),
    );
  }
}

class OwnerMenuSection {
  OwnerMenuSection({
    required this.id,
    required this.menuId,
    required this.title,
    required this.sortOrder,
  });

  final String id;
  final String menuId;
  final String title;
  final int sortOrder;

  factory OwnerMenuSection.fromMap(Map<String, dynamic> map) {
    return OwnerMenuSection(
      id: (map['id'] ?? '').toString(),
      menuId: (map['menu_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      sortOrder: _asInt(map['sort_order']),
    );
  }
}

class OwnerMenuItem {
  OwnerMenuItem({
    required this.id,
    required this.sectionId,
    required this.businessId,
    required this.name,
    required this.status,
    this.description,
    this.priceCents,
    this.currency,
    this.catalogItemId,
  });

  final String id;
  final String sectionId;
  final String businessId;
  final String name;
  final String status;
  final String? description;
  final int? priceCents;
  final String? currency;
  final int? catalogItemId;

  factory OwnerMenuItem.fromMap(Map<String, dynamic> map) {
    return OwnerMenuItem(
      id: (map['id'] ?? '').toString(),
      sectionId: (map['section_id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      description: map['description']?.toString(),
      priceCents: _asIntNullable(map['price_cents']),
      currency: map['currency']?.toString(),
      catalogItemId: _asIntNullable(map['catalog_item_id']),
    );
  }
}

class OwnerMenuItemVariant {
  OwnerMenuItemVariant({
    required this.id,
    required this.menuItemId,
    required this.label,
    required this.priceCents,
    required this.currency,
    required this.isDefault,
    required this.isAvailable,
    required this.sortOrder,
  });

  final String id;
  final String menuItemId;
  final String label;
  final int priceCents;
  final String currency;
  final bool isDefault;
  final bool isAvailable;
  final int sortOrder;

  factory OwnerMenuItemVariant.fromMap(Map<String, dynamic> map) {
    return OwnerMenuItemVariant(
      id: (map['id'] ?? '').toString(),
      menuItemId: (map['menu_item_id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      priceCents: _asInt(map['price_cents']),
      currency: (map['currency'] ?? 'TRY').toString(),
      isDefault: map['is_default'] == true,
      isAvailable: map['is_available'] != false,
      sortOrder: _asInt(map['sort_order']),
    );
  }
}

class OwnerRpcResult {
  OwnerRpcResult({required this.ok, this.code, this.message, this.id});

  final bool ok;
  final String? code;
  final String? message;
  final String? id;

  factory OwnerRpcResult.fromResponse(dynamic res) {
    if (res is Map) {
      return OwnerRpcResult(
        ok: (res['ok'] as bool?) ?? false,
        code: res['code']?.toString(),
        message: res['message']?.toString(),
        id: res['id']?.toString(),
      );
    }
    if (res is List && res.isNotEmpty && res.first is Map) {
      return OwnerRpcResult.fromResponse(res.first);
    }
    return OwnerRpcResult(
      ok: false,
      code: 'unknown',
      message: 'Bilinmeyen hata',
    );
  }
}

class OwnerMenuException implements Exception {
  OwnerMenuException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'OwnerMenuException($code): $message';
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse((v ?? '').toString()) ?? 0;
}

int? _asIntNullable(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime _asDate(Object? v) {
  if (v is DateTime) return v;
  return DateTime.tryParse((v ?? '').toString()) ?? DateTime.now();
}
