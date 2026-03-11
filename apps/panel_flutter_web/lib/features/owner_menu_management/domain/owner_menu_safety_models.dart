enum OwnerTrashEntityType { menu, item, photo }

class OwnerTrashEntry {
  const OwnerTrashEntry({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
    this.menuId,
    this.menuItemId,
    this.photoUrl,
  });

  final OwnerTrashEntityType entityType;
  final String entityId;
  final String title;
  final String subtitle;
  final DateTime? occurredAt;
  final String? menuId;
  final String? menuItemId;
  final String? photoUrl;

  factory OwnerTrashEntry.fromMap(Map<String, dynamic> map) {
    return OwnerTrashEntry(
      entityType: _trashTypeFromRaw((map['entity_type'] ?? '').toString()),
      entityId: (map['entity_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      occurredAt: _dateOrNull(map['occurred_at']),
      menuId: _nullable(map['menu_id']),
      menuItemId: _nullable(map['menu_item_id']),
      photoUrl: _nullable(map['photo_url']),
    );
  }
}

class OwnerMenuVersionSnapshot {
  const OwnerMenuVersionSnapshot({
    required this.snapshotId,
    required this.menuId,
    required this.menuVersion,
    required this.snapshotReason,
    required this.createdAt,
    required this.sectionCount,
    required this.itemCount,
  });

  final String snapshotId;
  final String menuId;
  final int menuVersion;
  final String snapshotReason;
  final DateTime createdAt;
  final int sectionCount;
  final int itemCount;

  factory OwnerMenuVersionSnapshot.fromMap(Map<String, dynamic> map) {
    return OwnerMenuVersionSnapshot(
      snapshotId: (map['snapshot_id'] ?? '').toString(),
      menuId: (map['menu_id'] ?? '').toString(),
      menuVersion: _asInt(map['menu_version']),
      snapshotReason: (map['snapshot_reason'] ?? '').toString(),
      createdAt: _dateOrNull(map['created_at']) ?? DateTime.now(),
      sectionCount: _asInt(map['section_count']),
      itemCount: _asInt(map['item_count']),
    );
  }
}

class OwnerMenuVersionDetail {
  const OwnerMenuVersionDetail({
    required this.snapshotId,
    required this.menuId,
    required this.menuVersion,
    required this.snapshotReason,
    required this.createdAt,
    required this.menuTitle,
    required this.menuKind,
    required this.sectionTitles,
    required this.itemNames,
  });

  final String snapshotId;
  final String menuId;
  final int menuVersion;
  final String snapshotReason;
  final DateTime createdAt;
  final String menuTitle;
  final String? menuKind;
  final List<String> sectionTitles;
  final List<String> itemNames;

  int get sectionCount => sectionTitles.length;
  int get itemCount => itemNames.length;

  factory OwnerMenuVersionDetail.fromMap(Map<String, dynamic> map) {
    return OwnerMenuVersionDetail(
      snapshotId: (map['snapshot_id'] ?? '').toString(),
      menuId: (map['menu_id'] ?? '').toString(),
      menuVersion: _asInt(map['menu_version']),
      snapshotReason: (map['snapshot_reason'] ?? '').toString(),
      createdAt: _dateOrNull(map['created_at']) ?? DateTime.now(),
      menuTitle: (map['menu_title'] ?? '').toString(),
      menuKind: _nullable(map['menu_kind']),
      sectionTitles: _stringList(map['section_titles']),
      itemNames: _stringList(map['item_names']),
    );
  }
}

class OwnerMenuStructureSummary {
  const OwnerMenuStructureSummary({
    required this.menuId,
    required this.menuTitle,
    required this.menuKind,
    required this.sectionTitles,
    required this.itemNames,
  });

  final String menuId;
  final String menuTitle;
  final String? menuKind;
  final List<String> sectionTitles;
  final List<String> itemNames;

  int get sectionCount => sectionTitles.length;
  int get itemCount => itemNames.length;
}

class OwnerRestoreVersionResult {
  const OwnerRestoreVersionResult({required this.menuId});

  final String menuId;
}

OwnerTrashEntityType _trashTypeFromRaw(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'menu':
      return OwnerTrashEntityType.menu;
    case 'photo':
      return OwnerTrashEntityType.photo;
    case 'item':
    default:
      return OwnerTrashEntityType.item;
  }
}

DateTime? _dateOrNull(Object? value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String? _nullable(Object? value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;
  return text;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
