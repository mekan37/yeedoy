class AdminGrowthDay {
  const AdminGrowthDay({
    required this.day,
    required this.menuLinkOpened,
    required this.qrScanned,
    required this.menuShared,
    required this.appInstallFromMenu,
  });

  final DateTime day;
  final int menuLinkOpened;
  final int qrScanned;
  final int menuShared;
  final int appInstallFromMenu;

  factory AdminGrowthDay.fromMap(Map<String, dynamic> map) {
    return AdminGrowthDay(
      day: DateTime.tryParse((map['day'] ?? '').toString()) ?? DateTime.now(),
      menuLinkOpened: _asInt(map['menu_link_opened']),
      qrScanned: _asInt(map['qr_scanned']),
      menuShared: _asInt(map['menu_shared']),
      appInstallFromMenu: _asInt(map['app_install_from_menu']),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString()) ?? 0;
  }
}

class AdminGrowthSummary {
  const AdminGrowthSummary({
    required this.menuLinkOpened,
    required this.qrScanned,
    required this.menuShared,
    required this.appInstallFromMenu,
  });

  final int menuLinkOpened;
  final int qrScanned;
  final int menuShared;
  final int appInstallFromMenu;
}
