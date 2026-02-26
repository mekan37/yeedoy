class BusinessMenu {
  BusinessMenu({
    required this.id,
    required this.title,
    this.status = 'published',
    this.version = 1,
    this.updatedAt,
    this.source = 'owner',
    this.confidenceScore = 0,
    this.activeFrom,
    this.activeTo,
  });

  final String id;
  final String title;
  final String status;
  final int version;
  final DateTime? updatedAt;
  final String source;
  final double confidenceScore;
  final String? activeFrom;
  final String? activeTo;

  factory BusinessMenu.fromMap(Map<String, dynamic> map) {
    return BusinessMenu(
      id: _asString(map, ['id', 'menu_id']) ?? '',
      title: _asString(map, ['title', 'name', 'category_name']) ?? 'Menü',
      status: _asString(map, ['status']) ?? 'published',
      version: _asInt(map, ['version']) ?? 1,
      updatedAt: _asDateNullable(map['updated_at'] ?? map['created_at']),
      source: _asString(map, ['source']) ?? 'owner',
      confidenceScore: _asDouble(map, ['confidence_score', 'confidence']) ?? 0,
      activeFrom: _asString(map, ['active_from', 'active_start', 'start_time']),
      activeTo: _asString(map, ['active_to', 'active_end', 'end_time']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'status': status,
    'version': version,
    'updated_at': updatedAt?.toIso8601String(),
    'source': source,
    'confidence_score': confidenceScore,
    'active_from': activeFrom,
    'active_to': activeTo,
  };
}

class MenuSection {
  MenuSection({required this.id, required this.title, this.sortOrder});

  final String id;
  final String title;
  final int? sortOrder;

  factory MenuSection.fromMap(Map<String, dynamic> map) {
    return MenuSection(
      id:
          _asString(map, [
            'id',
            'section_id',
            'category_id',
            'menu_category_id',
          ]) ??
          '',
      title: _asString(map, ['title', 'name', 'category_name']) ?? 'Bölüm',
      sortOrder: _asInt(map, ['sort_order']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'sort_order': sortOrder,
  };
}

class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    this.sectionId,
    this.description,
    this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.tags = const [],
    this.isVegan = false,
    this.isGlutenFree = false,
    this.catalogItemId,
    this.catalogCategoryName,
    this.priceStatus = 'unverified',
    this.total30d,
  });

  final String id;
  final String name;
  final String? sectionId;
  final String? description;
  final double? price;
  final String? imageUrl;
  final bool isAvailable;
  final List<String> tags;
  final bool isVegan;
  final bool isGlutenFree;
  final int? catalogItemId;
  final String? catalogCategoryName;
  final String priceStatus;
  final int? total30d;

  MenuItem copyWith({
    String? id,
    String? name,
    String? sectionId,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    List<String>? tags,
    bool? isVegan,
    bool? isGlutenFree,
    int? catalogItemId,
    String? catalogCategoryName,
    String? priceStatus,
    int? total30d,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sectionId: sectionId ?? this.sectionId,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      tags: tags ?? this.tags,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      catalogItemId: catalogItemId ?? this.catalogItemId,
      catalogCategoryName: catalogCategoryName ?? this.catalogCategoryName,
      priceStatus: priceStatus ?? this.priceStatus,
      total30d: total30d ?? this.total30d,
    );
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    final priceCents = _asDouble(map, ['price_cents']);
    final rawPrice = _asDouble(map, ['price', 'unit_price', 'amount']);
    return MenuItem(
      id: _asString(map, ['id', 'menu_item_id']) ?? '',
      name: _asString(map, ['name', 'title']) ?? 'Ürün',
      sectionId: _asString(map, [
        'section_id',
        'menu_section_id',
        'category_id',
        'menu_category_id',
      ]),
      description: _asString(map, ['description', 'desc', 'details']),
      price: priceCents != null ? (priceCents / 100) : rawPrice,
      imageUrl: _asString(map, [
        'image_url',
        'imageUrl',
        'photo_url',
        'photoUrl',
      ]),
      isAvailable: _asBool(map, ['is_available', 'isAvailable']) ?? true,
      tags: _asStringList(map, ['tags']),
      isVegan: _asBool(map, ['is_vegan', 'vegan']) ?? false,
      isGlutenFree: _asBool(map, ['is_gluten_free', 'gluten_free']) ?? false,
      catalogItemId: _asInt(map, ['catalog_item_id', 'catalogItemId']),
      catalogCategoryName: _asString(map, [
        'catalog_category_name',
        'catalogCategoryName',
      ]),
      priceStatus: _asString(map, ['price_status', 'status']) ?? 'unverified',
      total30d: _asInt(map, ['total_30d', 'total30d', 'votes_30d']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'section_id': sectionId,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'is_available': isAvailable,
    'tags': tags,
    'is_vegan': isVegan,
    'is_gluten_free': isGlutenFree,
    'catalog_item_id': catalogItemId,
    'catalog_category_name': catalogCategoryName,
    'price_status': priceStatus,
    'total_30d': total30d,
  };
}

class MenuItemPhoto {
  MenuItemPhoto({
    required this.id,
    required this.url,
    required this.urlLarge,
    required this.urlThumb,
    this.upVotes = 0,
    this.downVotes = 0,
    this.myVote,
  });

  final String id;
  final String url;
  final String urlLarge;
  final String urlThumb;
  final int upVotes;
  final int downVotes;
  final int? myVote;

  int get score => upVotes - downVotes;

  MenuItemPhoto copyWith({
    String? id,
    String? url,
    String? urlLarge,
    String? urlThumb,
    int? upVotes,
    int? downVotes,
    int? myVote,
  }) {
    return MenuItemPhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      urlLarge: urlLarge ?? this.urlLarge,
      urlThumb: urlThumb ?? this.urlThumb,
      upVotes: upVotes ?? this.upVotes,
      downVotes: downVotes ?? this.downVotes,
      myVote: myVote ?? this.myVote,
    );
  }

  MenuItemPhoto withVote(int vote) {
    final prev = myVote ?? 0;
    var up = upVotes;
    var down = downVotes;
    if (prev == 1) up = (up - 1).clamp(0, 1 << 30);
    if (prev == -1) down = (down - 1).clamp(0, 1 << 30);
    if (vote == 1) up = (up + 1).clamp(0, 1 << 30);
    if (vote == -1) down = (down + 1).clamp(0, 1 << 30);
    return copyWith(upVotes: up, downVotes: down, myVote: vote);
  }

  factory MenuItemPhoto.fromMap(Map<String, dynamic> map) {
    final url = _asString(map, ['url', 'source_url']) ?? '';
    final urlLarge = _asString(map, ['url_large', 'large_url']) ?? url;
    final urlThumb = _asString(map, ['url_thumb', 'thumb_url']) ?? urlLarge;
    return MenuItemPhoto(
      id: _asString(map, ['id', 'photo_id']) ?? '',
      url: url,
      urlLarge: urlLarge,
      urlThumb: urlThumb,
      upVotes: _asInt(map, ['up_votes', 'upvotes', 'up', 'positive']) ?? 0,
      downVotes:
          _asInt(map, ['down_votes', 'downvotes', 'down', 'negative']) ?? 0,
      myVote: _asInt(map, ['my_vote', 'myVote', 'vote']),
    );
  }
}

class MenuItemPriceStatus {
  MenuItemPriceStatus({
    required this.status,
    this.priceCents,
    this.okVotes = 0,
    this.badVotes = 0,
    this.myVote,
    this.lastVerifiedAt,
    this.confidenceScore = 0,
    this.verifiedSources48h = 0,
    this.safeToTrust = false,
    this.consensusStatus = 'weak',
  });

  final String status;
  final int? priceCents;
  final int okVotes;
  final int badVotes;
  final int? myVote;
  final DateTime? lastVerifiedAt;
  final double confidenceScore;
  final int verifiedSources48h;
  final bool safeToTrust;
  final String consensusStatus;

  MenuItemPriceStatus copyWith({
    String? status,
    int? priceCents,
    int? okVotes,
    int? badVotes,
    int? myVote,
    DateTime? lastVerifiedAt,
    double? confidenceScore,
    int? verifiedSources48h,
    bool? safeToTrust,
    String? consensusStatus,
  }) {
    return MenuItemPriceStatus(
      status: status ?? this.status,
      priceCents: priceCents ?? this.priceCents,
      okVotes: okVotes ?? this.okVotes,
      badVotes: badVotes ?? this.badVotes,
      myVote: myVote ?? this.myVote,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      verifiedSources48h: verifiedSources48h ?? this.verifiedSources48h,
      safeToTrust: safeToTrust ?? this.safeToTrust,
      consensusStatus: consensusStatus ?? this.consensusStatus,
    );
  }

  MenuItemPriceStatus withVote(int vote) {
    final prev = myVote ?? 0;
    var ok = okVotes;
    var bad = badVotes;
    if (prev == 1) ok = (ok - 1).clamp(0, 1 << 30);
    if (prev == -1) bad = (bad - 1).clamp(0, 1 << 30);
    if (vote == 1) ok = (ok + 1).clamp(0, 1 << 30);
    if (vote == -1) bad = (bad + 1).clamp(0, 1 << 30);
    return copyWith(okVotes: ok, badVotes: bad, myVote: vote);
  }

  factory MenuItemPriceStatus.fromMap(Map<String, dynamic> map) {
    return MenuItemPriceStatus(
      status: _asString(map, ['status', 'price_status']) ?? 'unknown',
      priceCents: _asInt(map, ['price_cents', 'priceCents', 'price']),
      okVotes: _asInt(map, ['ok_votes', 'positive', 'up_votes']) ?? 0,
      badVotes: _asInt(map, ['bad_votes', 'negative', 'down_votes']) ?? 0,
      myVote: _asInt(map, ['my_vote', 'myVote', 'vote']),
      lastVerifiedAt: _asDateNullable(map['last_verified_at']),
      confidenceScore: _asDouble(map, ['confidence_score', 'confidence']) ?? 0,
      verifiedSources48h:
          _asInt(map, ['verified_sources_48h', 'verified_sources']) ?? 0,
      safeToTrust: _asBool(map, ['safe_to_trust', 'safeToTrust']) ?? false,
      consensusStatus:
          _asString(map, ['consensus_status', 'consensusStatus']) ?? 'weak',
    );
  }
}

class MenuItemPriceHistoryEntry {
  MenuItemPriceHistoryEntry({
    required this.priceCents,
    this.oldPriceCents,
    required this.currency,
    required this.source,
    required this.createdAt,
  });

  final int priceCents;
  final int? oldPriceCents;
  final String currency;
  final String source;
  final DateTime createdAt;

  factory MenuItemPriceHistoryEntry.fromMap(Map<String, dynamic> map) {
    return MenuItemPriceHistoryEntry(
      priceCents: _asInt(map, ['price_cents', 'price']) ?? 0,
      oldPriceCents: _asInt(map, ['old_price_cents', 'old_price']),
      currency: _asString(map, ['currency']) ?? 'TRY',
      source: _asString(map, ['source']) ?? 'unknown',
      createdAt: _asDate(map['created_at']),
    );
  }
}

class MenuItemValueScore {
  MenuItemValueScore({
    required this.score,
    required this.verifiedRatio,
    required this.recentPositiveRatio,
    required this.priceStability,
    required this.priceChanges30d,
  });

  final double score;
  final double verifiedRatio;
  final double recentPositiveRatio;
  final double priceStability;
  final int priceChanges30d;

  factory MenuItemValueScore.fromMap(Map<String, dynamic> map) {
    final breakdown =
        (map['breakdown'] as Map?)?.cast<String, dynamic>() ?? const {};
    return MenuItemValueScore(
      score: _asDouble(map, ['score']) ?? 0,
      verifiedRatio: _asDouble(breakdown, ['verified_ratio']) ?? 0,
      recentPositiveRatio: _asDouble(breakdown, ['recent_positive_ratio']) ?? 0,
      priceStability: _asDouble(breakdown, ['price_stability']) ?? 0,
      priceChanges30d: _asInt(breakdown, ['price_changes_30d']) ?? 0,
    );
  }
}

class BusinessPriceTrust {
  BusinessPriceTrust({required this.verifiedCount, required this.totalCount});

  final int verifiedCount;
  final int totalCount;

  factory BusinessPriceTrust.fromMap(Map<String, dynamic> map) {
    return BusinessPriceTrust(
      verifiedCount: _asInt(map, ['verified_count', 'verified']) ?? 0,
      totalCount: _asInt(map, ['total_count', 'total']) ?? 0,
    );
  }
}

String? _asString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

int? _asInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

double? _asDouble(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '.');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

bool? _asBool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
  }
  return null;
}

List<String> _asStringList(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        final inner = trimmed.substring(1, trimmed.length - 1);
        if (inner.trim().isEmpty) return const [];
        return inner
            .split(',')
            .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
      return [trimmed];
    }
  }
  return const [];
}

DateTime _asDate(Object? v) {
  if (v is DateTime) return v;
  return DateTime.tryParse((v ?? '').toString()) ?? DateTime.now();
}

DateTime? _asDateNullable(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
