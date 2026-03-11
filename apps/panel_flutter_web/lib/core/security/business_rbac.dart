enum BusinessPermission {
  businessRead('business_read'),
  businessWrite('business_write'),
  menuWrite('menu_write'),
  mediaUpload('media_upload'),
  qrManage('qr_manage'),
  analyticsView('analytics_view'),
  teamManage('team_manage');

  const BusinessPermission(this.rpcName);

  final String rpcName;
}

enum OwnerTeamRole {
  owner('owner'),
  manager('manager'),
  editor('editor'),
  staff('staff'),
  viewer('viewer');

  const OwnerTeamRole(this.value);

  final String value;

  static OwnerTeamRole fromValue(String raw) {
    return OwnerTeamRole.values.firstWhere(
      (role) => role.value == raw.trim().toLowerCase(),
      orElse: () => OwnerTeamRole.viewer,
    );
  }
}

enum TeamAccessScope {
  thisBusiness('this_business'),
  allBranches('all_branches');

  const TeamAccessScope(this.value);

  final String value;

  static TeamAccessScope fromValue(String raw) {
    return TeamAccessScope.values.firstWhere(
      (scope) => scope.value == raw.trim().toLowerCase(),
      orElse: () => TeamAccessScope.thisBusiness,
    );
  }
}

extension OwnerTeamRoleLabel on OwnerTeamRole {
  String get title {
    switch (this) {
      case OwnerTeamRole.owner:
        return 'Owner';
      case OwnerTeamRole.manager:
        return 'Manager';
      case OwnerTeamRole.editor:
        return 'Editor';
      case OwnerTeamRole.staff:
        return 'Staff';
      case OwnerTeamRole.viewer:
        return 'Viewer';
    }
  }
}

extension TeamAccessScopeLabel on TeamAccessScope {
  String get title {
    switch (this) {
      case TeamAccessScope.thisBusiness:
        return 'Only this branch';
      case TeamAccessScope.allBranches:
        return 'All branches';
    }
  }
}
