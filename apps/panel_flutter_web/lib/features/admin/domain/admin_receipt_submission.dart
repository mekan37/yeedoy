class AdminReceiptSubmission {
  AdminReceiptSubmission({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.userId,
    required this.imageUrl,
    required this.matchesCount,
    required this.createdAt,
    required this.reviewStatus,
    this.city,
    this.district,
    this.chainId,
    this.chainName,
    this.reviewNote,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String userId;
  final String imageUrl;
  final int matchesCount;
  final DateTime createdAt;
  final String reviewStatus;
  final String? city;
  final String? district;
  final String? chainId;
  final String? chainName;
  final String? reviewNote;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  AdminReceiptSubmission copyWith({
    String? reviewStatus,
    String? reviewNote,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return AdminReceiptSubmission(
      id: id,
      businessId: businessId,
      businessName: businessName,
      userId: userId,
      imageUrl: imageUrl,
      matchesCount: matchesCount,
      createdAt: createdAt,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      city: city,
      district: district,
      chainId: chainId,
      chainName: chainName,
      reviewNote: reviewNote ?? this.reviewNote,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  factory AdminReceiptSubmission.fromMap(Map<String, dynamic> map) {
    int asInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('${value ?? ''}') ?? 0;
    }

    DateTime? asDate(Object? value) {
      final raw = (value ?? '').toString();
      if (raw.trim().isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    String? asNullable(Object? value) {
      final raw = (value ?? '').toString().trim();
      return raw.isEmpty ? null : raw;
    }

    return AdminReceiptSubmission(
      id: (map['receipt_id'] ?? map['id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      matchesCount: asInt(map['matches_count']),
      createdAt: asDate(map['created_at']) ?? DateTime.now(),
      reviewStatus: (map['review_status'] ?? 'pending').toString(),
      city: asNullable(map['city']),
      district: asNullable(map['district']),
      chainId: asNullable(map['chain_id']),
      chainName: asNullable(map['chain_name']),
      reviewNote: asNullable(map['review_note']),
      reviewedAt: asDate(map['reviewed_at']),
      reviewedBy: asNullable(map['reviewed_by']),
    );
  }
}

class AdminReceiptSubmissionSummary {
  AdminReceiptSubmissionSummary({
    required this.totalCount,
    required this.pendingCount,
    required this.reviewedCount,
    required this.needsFollowupCount,
    required this.zeroMatchCount,
    required this.businessCount,
    required this.recent24hCount,
  });

  final int totalCount;
  final int pendingCount;
  final int reviewedCount;
  final int needsFollowupCount;
  final int zeroMatchCount;
  final int businessCount;
  final int recent24hCount;

  factory AdminReceiptSubmissionSummary.fromMap(Map<String, dynamic> map) {
    int asInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('${value ?? ''}') ?? 0;
    }

    return AdminReceiptSubmissionSummary(
      totalCount: asInt(map['total_count']),
      pendingCount: asInt(map['pending_count']),
      reviewedCount: asInt(map['reviewed_count']),
      needsFollowupCount: asInt(map['needs_followup_count']),
      zeroMatchCount: asInt(map['zero_match_count']),
      businessCount: asInt(map['business_count']),
      recent24hCount: asInt(map['recent_24h_count']),
    );
  }
}

class AdminReceiptSubmissionMatch {
  AdminReceiptSubmissionMatch({
    required this.menuItemId,
    required this.itemName,
    required this.detectedPriceCents,
    required this.currentPriceCents,
    required this.deltaCents,
  });

  final String menuItemId;
  final String itemName;
  final int detectedPriceCents;
  final int currentPriceCents;
  final int deltaCents;

  factory AdminReceiptSubmissionMatch.fromMap(Map<String, dynamic> map) {
    int asInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('${value ?? ''}') ?? 0;
    }

    return AdminReceiptSubmissionMatch(
      menuItemId: (map['menu_item_id'] ?? '').toString(),
      itemName: (map['item_name'] ?? '').toString(),
      detectedPriceCents: asInt(map['detected_price_cents']),
      currentPriceCents: asInt(map['current_price_cents']),
      deltaCents: asInt(map['delta_cents']),
    );
  }
}

class AdminReceiptBatchOpportunity {
  AdminReceiptBatchOpportunity({
    required this.businessId,
    required this.businessName,
    required this.pendingCount,
    required this.zeroMatchCount,
    required this.lastSubmittedAt,
    this.chainId,
    this.chainName,
  });

  final String businessId;
  final String businessName;
  final int pendingCount;
  final int zeroMatchCount;
  final DateTime lastSubmittedAt;
  final String? chainId;
  final String? chainName;

  factory AdminReceiptBatchOpportunity.fromMap(Map<String, dynamic> map) {
    int asInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('${value ?? ''}') ?? 0;
    }

    String? asNullable(Object? value) {
      final raw = (value ?? '').toString().trim();
      return raw.isEmpty ? null : raw;
    }

    return AdminReceiptBatchOpportunity(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      pendingCount: asInt(map['pending_count']),
      zeroMatchCount: asInt(map['zero_match_count']),
      lastSubmittedAt:
          DateTime.tryParse('${map['last_submitted_at'] ?? ''}') ??
          DateTime.now(),
      chainId: asNullable(map['chain_id']),
      chainName: asNullable(map['chain_name']),
    );
  }
}
