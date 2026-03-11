import '../i18n/app_localizations.dart';
import 'business_rbac.dart';

extension BusinessRbacLocalizations on AppLocalizations {
  String ownerTeamRoleLabel(OwnerTeamRole role) {
    switch (role) {
      case OwnerTeamRole.owner:
        return ownerTeamRoleOwner;
      case OwnerTeamRole.manager:
        return ownerTeamRoleManager;
      case OwnerTeamRole.editor:
        return ownerTeamRoleEditor;
      case OwnerTeamRole.staff:
        return ownerTeamRoleStaff;
      case OwnerTeamRole.viewer:
        return ownerTeamRoleViewer;
    }
  }

  String ownerTeamScopeLabel(TeamAccessScope scope) {
    switch (scope) {
      case TeamAccessScope.thisBusiness:
        return ownerTeamScopeThisBusiness;
      case TeamAccessScope.allBranches:
        return ownerTeamScopeAllBranches;
    }
  }
}
