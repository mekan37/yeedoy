class BusinessCrowdStatus {
  BusinessCrowdStatus({
    required this.state,
    required this.count60m,
    this.userCanReport = true,
  });

  final String state;
  final int count60m;
  final bool userCanReport;

  factory BusinessCrowdStatus.fromMap(Map<String, dynamic> map) {
    return BusinessCrowdStatus(
      state: (map['state'] ?? map['crowd'] ?? 'unknown').toString(),
      count60m: _asInt(map, ['count_60m', 'count60m', 'count']) ?? 0,
      userCanReport: _asBool(map, ['user_can_report', 'can_report']) ?? true,
    );
  }
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
