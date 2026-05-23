class CollabList {
  const CollabList({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.inviteToken,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String inviteToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CollabList.fromMap(Map<String, dynamic> map) {
    return CollabList(
      id: (map['id'] ?? '').toString(),
      ownerId: (map['owner_id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: map['description'] as String?,
      inviteToken: (map['invite_token'] ?? '').toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class CollabListItem {
  const CollabListItem({
    required this.id,
    required this.listId,
    required this.businessId,
    required this.addedBy,
    this.note,
    required this.createdAt,
    required this.score,
    required this.myVote,
    this.businessName,
    this.businessCategory,
    this.businessCity,
    this.businessDistrict,
  });

  final String id;
  final String listId;
  final String businessId;
  final String addedBy;
  final String? note;
  final DateTime createdAt;
  final int score;
  final int myVote; // -1, 0, or 1
  final String? businessName;
  final String? businessCategory;
  final String? businessCity;
  final String? businessDistrict;

  factory CollabListItem.fromMap(Map<String, dynamic> map) {
    return CollabListItem(
      id: (map['id'] ?? '').toString(),
      listId: (map['list_id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      addedBy: (map['added_by'] ?? '').toString(),
      note: map['note'] as String?,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      score: ((map['score'] as num?) ?? 0).toInt(),
      myVote: ((map['my_vote'] as num?) ?? 0).toInt(),
      businessName: map['business_name'] as String?,
      businessCategory: map['business_category'] as String?,
      businessCity: map['business_city'] as String?,
      businessDistrict: map['business_district'] as String?,
    );
  }

  CollabListItem copyWith({int? score, int? myVote}) {
    return CollabListItem(
      id: id,
      listId: listId,
      businessId: businessId,
      addedBy: addedBy,
      note: note,
      createdAt: createdAt,
      score: score ?? this.score,
      myVote: myVote ?? this.myVote,
      businessName: businessName,
      businessCategory: businessCategory,
      businessCity: businessCity,
      businessDistrict: businessDistrict,
    );
  }
}

class CollabListDetail {
  const CollabListDetail({required this.list, required this.items});

  final CollabList list;
  final List<CollabListItem> items;
}
