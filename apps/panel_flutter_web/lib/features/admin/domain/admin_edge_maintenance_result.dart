class AdminEdgeMaintenanceResult {
  const AdminEdgeMaintenanceResult({
    required this.ok,
    required this.label,
    required this.summary,
    this.raw = const <String, dynamic>{},
  });

  final bool ok;
  final String label;
  final String summary;
  final Map<String, dynamic> raw;
}
