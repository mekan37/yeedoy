class OwnerAnalyticsSnapshot {
  const OwnerAnalyticsSnapshot({
    required this.summary,
    required this.daily,
    required this.topItems,
    required this.topCategories,
    required this.sourceBreakdown,
    required this.branchCompare,
  });

  final OwnerAnalyticsSummary summary;
  final List<OwnerAnalyticsDailyPoint> daily;
  final List<OwnerAnalyticsCountRow> topItems;
  final List<OwnerAnalyticsCountRow> topCategories;
  final List<OwnerAnalyticsCountRow> sourceBreakdown;
  final List<OwnerAnalyticsBranchRow> branchCompare;

  factory OwnerAnalyticsSnapshot.fromMap(Map<String, dynamic> map) {
    return OwnerAnalyticsSnapshot(
      summary: OwnerAnalyticsSummary.fromMap(
        (map['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      daily: _listOfMap(map['daily'])
          .map(OwnerAnalyticsDailyPoint.fromMap)
          .toList(growable: false),
      topItems: _listOfMap(map['top_items'])
          .map(OwnerAnalyticsCountRow.fromMap)
          .toList(growable: false),
      topCategories: _listOfMap(map['top_categories'])
          .map(OwnerAnalyticsCountRow.fromMap)
          .toList(growable: false),
      sourceBreakdown: _listOfMap(map['source_breakdown'])
          .map(OwnerAnalyticsCountRow.fromMap)
          .toList(growable: false),
      branchCompare: _listOfMap(map['branch_compare'])
          .map(OwnerAnalyticsBranchRow.fromMap)
          .toList(growable: false),
    );
  }
}

class OwnerAnalyticsSummary {
  const OwnerAnalyticsSummary({
    required this.qrScans,
    required this.menuOpens,
    required this.categoryViews,
    required this.itemClicks,
    required this.sourceTotal,
  });

  final int qrScans;
  final int menuOpens;
  final int categoryViews;
  final int itemClicks;
  final int sourceTotal;

  factory OwnerAnalyticsSummary.fromMap(Map<String, dynamic> map) {
    return OwnerAnalyticsSummary(
      qrScans: _asInt(map['qr_scans']),
      menuOpens: _asInt(map['menu_opens']),
      categoryViews: _asInt(map['category_views']),
      itemClicks: _asInt(map['item_clicks']),
      sourceTotal: _asInt(map['source_total']),
    );
  }
}

class OwnerAnalyticsDailyPoint {
  const OwnerAnalyticsDailyPoint({
    required this.day,
    required this.qrScans,
    required this.menuOpens,
    required this.menuViews,
    required this.itemClicks,
  });

  final String day;
  final int qrScans;
  final int menuOpens;
  final int menuViews;
  final int itemClicks;

  factory OwnerAnalyticsDailyPoint.fromMap(Map<String, dynamic> map) {
    return OwnerAnalyticsDailyPoint(
      day: (map['day'] ?? '').toString(),
      qrScans: _asInt(map['qr_scans']),
      menuOpens: _asInt(map['menu_opens']),
      menuViews: _asInt(map['menu_views']),
      itemClicks: _asInt(map['item_clicks']),
    );
  }
}

class OwnerAnalyticsCountRow {
  const OwnerAnalyticsCountRow({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  factory OwnerAnalyticsCountRow.fromMap(Map<String, dynamic> map) {
    return OwnerAnalyticsCountRow(
      label: (map['label'] ?? '').toString(),
      count: _asInt(map['count']),
    );
  }
}

class OwnerAnalyticsBranchRow {
  const OwnerAnalyticsBranchRow({
    required this.businessId,
    required this.label,
    required this.menuOpens,
    required this.qrScans,
    required this.menuViews,
    required this.selected,
  });

  final String businessId;
  final String label;
  final int menuOpens;
  final int qrScans;
  final int menuViews;
  final bool selected;

  factory OwnerAnalyticsBranchRow.fromMap(Map<String, dynamic> map) {
    return OwnerAnalyticsBranchRow(
      businessId: (map['business_id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      menuOpens: _asInt(map['menu_opens']),
      qrScans: _asInt(map['qr_scans']),
      menuViews: _asInt(map['menu_views']),
      selected: map['selected'] == true,
    );
  }
}

class OwnerAnalyticsHourlySnapshot {
  const OwnerAnalyticsHourlySnapshot({
    required this.summary,
    required this.hourly,
  });

  final OwnerAnalyticsSummary summary;
  final List<OwnerAnalyticsHourlyPoint> hourly;

  factory OwnerAnalyticsHourlySnapshot.fromMap(Map<String, dynamic> map) {
    return OwnerAnalyticsHourlySnapshot(
      summary: OwnerAnalyticsSummary.fromMap(
        (map['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      hourly: _listOfMap(map['hourly'])
          .map(OwnerAnalyticsHourlyPoint.fromMap)
          .toList(growable: false),
    );
  }
}

class OwnerAnalyticsHourlyPoint {
  const OwnerAnalyticsHourlyPoint({
    required this.hour,
    required this.qrScans,
    required this.menuOpens,
    required this.menuViews,
    required this.itemClicks,
  });

  final int hour;
  final int qrScans;
  final int menuOpens;
  final int menuViews;
  final int itemClicks;

  factory OwnerAnalyticsHourlyPoint.fromMap(Map<String, dynamic> map) {
    return OwnerAnalyticsHourlyPoint(
      hour: _asInt(map['hour']),
      qrScans: _asInt(map['qr_scans']),
      menuOpens: _asInt(map['menu_opens']),
      menuViews: _asInt(map['menu_views']),
      itemClicks: _asInt(map['item_clicks']),
    );
  }
}

List<Map<String, dynamic>> _listOfMap(Object? value) {
  final list = (value as List?) ?? const [];
  return list
      .whereType<Map>()
      .map((row) => row.cast<String, dynamic>())
      .toList(growable: false);
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}
