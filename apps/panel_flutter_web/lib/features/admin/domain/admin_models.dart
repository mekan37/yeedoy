class AdminQueueCounts {
  const AdminQueueCounts({
    required this.reportsOpen,
    required this.claimsPending,
    required this.suggestionsPending,
  });

  final int reportsOpen;
  final int claimsPending;
  final int suggestionsPending;

  factory AdminQueueCounts.fromMap(Map<String, dynamic> m) => AdminQueueCounts(
    reportsOpen: _asInt(m['reports_open']),
    claimsPending: _asInt(m['claims_pending']),
    suggestionsPending: _asInt(m['suggestions_pending']),
  );
}

class AdminReportItem {
  AdminReportItem({
    required this.id,
    required this.status,
    required this.reason,
    required this.createdAt,
    this.details,
    this.businessId,
    this.reviewId,
    this.menuItemPhotoId,
    this.targetType,
    this.targetId,
    this.adminNote,
    this.reporterId,
    this.assignedTo,
    this.assignedAt,
    this.autoModerated = false,
    required this.ageHours,
    required this.slaBreached,
  });

  final String id;
  final String status;
  final String reason;
  final DateTime createdAt;
  final String? details;
  final String? businessId;
  final String? reviewId;
  final String? menuItemPhotoId;
  final String? targetType;
  final String? targetId;
  final String? adminNote;
  final String? reporterId;
  final String? assignedTo;
  final DateTime? assignedAt;
  final bool autoModerated;
  final double ageHours;
  final bool slaBreached;

  factory AdminReportItem.fromMap(Map<String, dynamic> m) {
    final createdAt = _asDate(m['created_at']);
    final ageHours = _asDoubleNullable(m['age_hours']) ?? _ageHours(createdAt);
    return AdminReportItem(
      id: _string(m, const ['report_id', 'id']) ?? '',
      status: _string(m, const ['status']) ?? 'open',
      reason: _string(m, const ['reason']) ?? 'other',
      details: _string(m, const ['details', 'detail']),
      businessId: _string(m, const ['business_id']),
      reviewId: _string(m, const ['review_id']),
      menuItemPhotoId: _string(m, const ['menu_item_photo_id']),
      targetType: _string(m, const ['target_type']),
      targetId: _string(m, const ['target_id']),
      adminNote: _string(m, const ['admin_note']),
      reporterId: _string(m, const ['user_id', 'reporter_id']),
      assignedTo: _string(m, const ['assigned_to']),
      assignedAt: _asDateNullable(m['assigned_at']),
      autoModerated: _asBool(m['auto_moderated']),
      ageHours: ageHours,
      slaBreached: _asBool(m['sla_breached']),
      createdAt: createdAt,
    );
  }
}

class AdminOwnerClaimItem {
  AdminOwnerClaimItem({
    required this.id,
    required this.status,
    required this.fullName,
    required this.phone,
    required this.createdAt,
    this.businessId,
    this.evidenceUrl,
    this.note,
    this.adminNote,
    this.assignedTo,
    this.assignedAt,
    this.autoModerated = false,
    required this.ageDays,
    required this.slaBreached,
  });

  final String id;
  final String status;
  final String fullName;
  final String phone;
  final DateTime createdAt;
  final String? businessId;
  final String? evidenceUrl;
  final String? note;
  final String? adminNote;
  final String? assignedTo;
  final DateTime? assignedAt;
  final bool autoModerated;
  final double ageDays;
  final bool slaBreached;

  factory AdminOwnerClaimItem.fromMap(Map<String, dynamic> m) {
    final createdAt = _asDate(m['created_at']);
    final ageDays = _asDoubleNullable(m['age_days']) ?? _ageDays(createdAt);
    return AdminOwnerClaimItem(
      id: _string(m, const ['claim_id', 'id']) ?? '',
      status: _string(m, const ['status']) ?? 'pending',
      fullName: _string(m, const ['full_name', 'name']) ?? '',
      phone: _string(m, const ['phone']) ?? '',
      businessId: _string(m, const ['business_id']),
      evidenceUrl: _string(m, const ['evidence_url']),
      note: _string(m, const ['note']),
      adminNote: _string(m, const ['admin_note']),
      assignedTo: _string(m, const ['assigned_to']),
      assignedAt: _asDateNullable(m['assigned_at']),
      autoModerated: _asBool(m['auto_moderated']),
      ageDays: ageDays,
      slaBreached: _asBool(m['sla_breached']),
      createdAt: createdAt,
    );
  }
}

class AdminSuspendedClaimItem {
  AdminSuspendedClaimItem({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.businessId,
    required this.businessName,
    required this.amountCents,
    required this.currency,
    required this.claimantId,
    required this.claimantName,
    required this.mealMessage,
    required this.note,
    required this.ageHours,
    required this.slaBreached,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final String businessId;
  final String businessName;
  final int amountCents;
  final String currency;
  final String claimantId;
  final String claimantName;
  final String mealMessage;
  final String note;
  final double ageHours;
  final bool slaBreached;

  factory AdminSuspendedClaimItem.fromMap(Map<String, dynamic> m) {
    final createdAt = _asDate(m['created_at']);
    final ageHours = _asDoubleNullable(m['age_hours']) ?? _ageHours(createdAt);
    return AdminSuspendedClaimItem(
      id: _string(m, const ['claim_id', 'id']) ?? '',
      status: _string(m, const ['status']) ?? 'pending',
      businessId: _string(m, const ['business_id']) ?? '',
      businessName: _string(m, const ['business_name', 'business']) ?? '',
      amountCents: _asInt(m['amount_cents']),
      currency: _string(m, const ['currency']) ?? 'TRY',
      claimantId: _string(m, const ['claimant_id', 'user_id']) ?? '',
      claimantName: _string(m, const ['claimant_name', 'name']) ?? '',
      mealMessage: _string(m, const ['meal_message', 'message']) ?? '',
      note: _string(m, const ['note']) ?? '',
      ageHours: ageHours,
      slaBreached: _asBool(m['sla_breached']),
      createdAt: createdAt,
    );
  }
}

class AdminSuggestionItem {
  AdminSuggestionItem({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    this.city,
    this.district,
    this.category,
    this.adminNote,
    this.approvedBusinessId,
    this.assignedTo,
    this.assignedAt,
    required this.ageDays,
    required this.slaBreached,
  });

  final String id;
  final String name;
  final String status;
  final DateTime createdAt;
  final String? city;
  final String? district;
  final String? category;
  final String? adminNote;
  final String? approvedBusinessId;
  final String? assignedTo;
  final DateTime? assignedAt;
  final double ageDays;
  final bool slaBreached;

  factory AdminSuggestionItem.fromMap(Map<String, dynamic> m) {
    final createdAt = _asDate(m['created_at']);
    final ageDays = _asDoubleNullable(m['age_days']) ?? _ageDays(createdAt);
    return AdminSuggestionItem(
      id: _string(m, const ['suggestion_id', 'id']) ?? '',
      name: _string(m, const ['name']) ?? '',
      status: _string(m, const ['status']) ?? 'pending',
      city: _string(m, const ['city']),
      district: _string(m, const ['district']),
      category: _string(m, const ['category']),
      adminNote: _string(m, const ['admin_note']),
      approvedBusinessId: _string(m, const ['approved_business_id']),
      assignedTo: _string(m, const ['assigned_to']),
      assignedAt: _asDateNullable(m['assigned_at']),
      ageDays: ageDays,
      slaBreached: _asBool(m['sla_breached']),
      createdAt: createdAt,
    );
  }
}

class AdminMenuPriceSuggestionItem {
  AdminMenuPriceSuggestionItem({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.businessId,
    required this.businessName,
    this.city,
    this.district,
    required this.menuItemId,
    required this.menuItemName,
    required this.currentPriceCents,
    required this.suggestedPriceCents,
    required this.currency,
    required this.createdBy,
    this.assignedTo,
    this.assignedAt,
    required this.ageHours,
    required this.slaBreached,
    required this.qualityConfidence,
    required this.anomalyScore,
    required this.anomalyFlags,
    required this.conflictState,
    required this.conflictVariants24h,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final String businessId;
  final String businessName;
  final String? city;
  final String? district;
  final String menuItemId;
  final String menuItemName;
  final int currentPriceCents;
  final int suggestedPriceCents;
  final String currency;
  final String createdBy;
  final String? assignedTo;
  final DateTime? assignedAt;
  final double ageHours;
  final bool slaBreached;
  final double qualityConfidence;
  final double anomalyScore;
  final List<String> anomalyFlags;
  final String conflictState;
  final int conflictVariants24h;

  factory AdminMenuPriceSuggestionItem.fromMap(Map<String, dynamic> m) {
    final createdAt = _asDate(m['created_at']);
    final ageHours = _asDoubleNullable(m['age_hours']) ?? _ageHours(createdAt);
    return AdminMenuPriceSuggestionItem(
      id: _string(m, const ['suggestion_id', 'id']) ?? '',
      status: _string(m, const ['status']) ?? 'pending',
      businessId: _string(m, const ['business_id']) ?? '',
      businessName: _string(m, const ['business_name', 'business']) ?? '',
      city: _string(m, const ['city']),
      district: _string(m, const ['district']),
      menuItemId: _string(m, const ['menu_item_id']) ?? '',
      menuItemName: _string(m, const ['menu_item_name', 'item_name']) ?? '',
      currentPriceCents: _asInt(m['current_price_cents']),
      suggestedPriceCents: _asInt(m['suggested_price_cents']),
      currency: _string(m, const ['currency']) ?? 'TRY',
      createdBy: _string(m, const ['created_by', 'user_id']) ?? '',
      assignedTo: _string(m, const ['assigned_to', 'handled_by']),
      assignedAt: _asDateNullable(m['assigned_at'] ?? m['handled_at']),
      ageHours: ageHours,
      slaBreached: _asBool(m['sla_breached']),
      qualityConfidence: _asDoubleNullable(m['quality_confidence']) ?? 0,
      anomalyScore: _asDoubleNullable(m['anomaly_score']) ?? 0,
      anomalyFlags: _asStringList(m['anomaly_flags']),
      conflictState: _string(m, const ['conflict_state']) ?? 'none',
      conflictVariants24h: _asInt(m['conflict_variants_24h']),
      createdAt: createdAt,
    );
  }
}

class AdminBusinessItem {
  AdminBusinessItem({
    required this.id,
    required this.name,
    required this.createdAt,
    this.category,
    this.address,
    this.city,
    this.district,
    this.lat,
    this.lng,
    this.logoUrl,
    this.coverUrl,
    this.assignedTo,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? category;
  final String? address;
  final String? city;
  final String? district;
  final double? lat;
  final double? lng;
  final String? logoUrl;
  final String? coverUrl;
  final String? assignedTo;
  final bool isVerified;

  factory AdminBusinessItem.fromMap(Map<String, dynamic> m) =>
      AdminBusinessItem(
        id: _string(m, const ['id', 'business_id']) ?? '',
        name: _string(m, const ['name']) ?? '',
        category: _string(m, const ['category']),
        address: _string(m, const ['address']),
        city: _string(m, const ['city']),
        district: _string(m, const ['district']),
        lat: _asDoubleNullable(m['lat']),
        lng: _asDoubleNullable(m['lng']),
        logoUrl: _string(m, const ['logo_url', 'logo']),
        coverUrl: _string(m, const ['cover_url', 'cover']),
        assignedTo: _string(m, const ['assigned_to']),
        isVerified: _asBool(m['is_verified']),
        createdAt: _asDate(m['created_at']),
      );
}

class AdminSponsorshipPackage {
  AdminSponsorshipPackage({
    required this.id,
    required this.name,
    required this.surface,
    required this.durationDays,
    required this.priceDisplay,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String surface;
  final int durationDays;
  final String priceDisplay;
  final bool isActive;
  final DateTime createdAt;

  factory AdminSponsorshipPackage.fromMap(Map<String, dynamic> m) =>
      AdminSponsorshipPackage(
        id: _string(m, const ['id']) ?? '',
        name: _string(m, const ['name']) ?? '',
        surface: _string(m, const ['surface']) ?? '',
        durationDays: _asInt(m['duration_days']),
        priceDisplay: _string(m, const ['price_display']) ?? '',
        isActive: _asBool(m['is_active']),
        createdAt: _asDate(m['created_at']),
      );
}

class AdminSponsorshipItem {
  AdminSponsorshipItem({
    required this.id,
    required this.status,
    required this.surface,
    required this.createdAt,
    required this.businessId,
    required this.businessName,
    this.city,
    this.district,
    required this.packageId,
    this.startsAt,
    this.endsAt,
    this.dailyCap,
    this.totalCap,
    required this.source,
    this.createdBy,
  });

  final String id;
  final String status;
  final String surface;
  final DateTime createdAt;
  final String businessId;
  final String businessName;
  final String? city;
  final String? district;
  final String packageId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? dailyCap;
  final int? totalCap;
  final String source;
  final String? createdBy;

  factory AdminSponsorshipItem.fromMap(Map<String, dynamic> m) =>
      AdminSponsorshipItem(
        id: _string(m, const ['sponsorship_id', 'id']) ?? '',
        status: _string(m, const ['status']) ?? 'pending',
        surface: _string(m, const ['surface']) ?? '',
        createdAt: _asDate(m['created_at']),
        businessId: _string(m, const ['business_id']) ?? '',
        businessName: _string(m, const ['business_name', 'business']) ?? '',
        city: _string(m, const ['city']),
        district: _string(m, const ['district']),
        packageId: _string(m, const ['package_id']) ?? '',
        startsAt: _asDateNullable(m['starts_at']),
        endsAt: _asDateNullable(m['ends_at']),
        dailyCap: _asIntNullable(m['daily_cap']),
        totalCap: _asIntNullable(m['total_cap']),
        source: _string(m, const ['source']) ?? '',
        createdBy: _string(m, const ['created_by']),
      );
}

class AdminSponsorshipLead {
  AdminSponsorshipLead({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.businessId,
    required this.businessName,
    this.city,
    this.district,
    required this.ownerUserId,
    this.phone,
    this.message,
    required this.preferredSurface,
    required this.preferredTargeting,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final String businessId;
  final String businessName;
  final String? city;
  final String? district;
  final String ownerUserId;
  final String? phone;
  final String? message;
  final String preferredSurface;
  final Map<String, dynamic> preferredTargeting;

  factory AdminSponsorshipLead.fromMap(Map<String, dynamic> m) =>
      AdminSponsorshipLead(
        id: _string(m, const ['lead_id', 'id']) ?? '',
        status: _string(m, const ['status']) ?? 'new',
        createdAt: _asDate(m['created_at']),
        businessId: _string(m, const ['business_id']) ?? '',
        businessName: _string(m, const ['business_name', 'business']) ?? '',
        city: _string(m, const ['city']),
        district: _string(m, const ['district']),
        ownerUserId: _string(m, const ['owner_user_id']) ?? '',
        phone: _string(m, const ['phone']),
        message: _string(m, const ['message']),
        preferredSurface: _string(m, const ['preferred_surface']) ?? '',
        preferredTargeting:
            (m['preferred_targeting'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}

class DuplicateBusiness {
  DuplicateBusiness({
    required this.id,
    required this.name,
    required this.score,
    this.city,
    this.district,
    this.address,
  });

  final String id;
  final String name;
  final double score;
  final String? city;
  final String? district;
  final String? address;

  factory DuplicateBusiness.fromMap(Map<String, dynamic> m) =>
      DuplicateBusiness(
        id: _string(m, const ['id', 'business_id']) ?? '',
        name: _string(m, const ['name']) ?? '',
        score: _asDouble(m['score']),
        city: _string(m, const ['city']),
        district: _string(m, const ['district']),
        address: _string(m, const ['address']),
      );
}

class AdminSlaMetrics {
  const AdminSlaMetrics({
    required this.reportsAvgMinutesToAssign,
    required this.reportsAvgMinutesToClose,
    required this.claimsAvgMinutesToAssign,
    required this.claimsAvgMinutesToDecide,
  });

  final double reportsAvgMinutesToAssign;
  final double reportsAvgMinutesToClose;
  final double claimsAvgMinutesToAssign;
  final double claimsAvgMinutesToDecide;

  factory AdminSlaMetrics.fromMap(Map<String, dynamic> m) => AdminSlaMetrics(
    reportsAvgMinutesToAssign: _asDouble(m['reports_avg_minutes_to_assign']),
    reportsAvgMinutesToClose: _asDouble(m['reports_avg_minutes_to_close']),
    claimsAvgMinutesToAssign: _asDouble(m['claims_avg_minutes_to_assign']),
    claimsAvgMinutesToDecide: _asDouble(m['claims_avg_minutes_to_decide']),
  );
}

String? _string(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return null;
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse((v ?? '').toString()) ?? 0;
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

bool _asBool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = (v ?? '').toString().toLowerCase();
  return s == 'true' || s == '1';
}

double _asDouble(Object? v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse((v ?? '').toString()) ?? 0.0;
}

double? _asDoubleNullable(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _asIntNullable(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

List<String> _asStringList(Object? raw) {
  if (raw is List) {
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  final text = (raw ?? '').toString().trim();
  if (text.isEmpty || text == '[]') return const [];
  return text
      .replaceAll('[', '')
      .replaceAll(']', '')
      .split(',')
      .map((e) => e.trim().replaceAll('"', ''))
      .where((e) => e.isNotEmpty)
      .toList();
}

double _ageHours(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  return diff.inMinutes / 60.0;
}

double _ageDays(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  return diff.inHours / 24.0;
}
