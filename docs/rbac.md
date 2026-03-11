# Panel RBAC Contract

Date: `2026-03-03`  
Workspace: `C:\yeedoy`

## Discovery Summary

- Existing owner/admin role detection already existed via `current_user_role_v1`, `get_app_role_v1`, `is_admin`, `can_manage_business_v1`.
- Existing franchise/branch model was not `businesses.parent_id`; it is `businesses.chain_id` + `businesses.branch_label`.
- Existing chain-level access existed via `public.chain_memberships`.
- Missing before this change:
  - business-scoped team memberships
  - branch-scoped/team RPCs such as `list_team_members_v1`
  - impersonation audit RPC
  - permission-aware business access preview for admin

## Role Set

- `owner`
- `manager`
- `editor`
- `staff`
- `viewer`

## Permission Set

| Permission | owner | manager | editor | staff | viewer |
| --- | --- | --- | --- | --- | --- |
| `business_read` | yes | yes | yes | yes | yes |
| `business_write` | yes | yes | no | no | no |
| `menu_write` | yes | yes | yes | no | no |
| `media_upload` | yes | yes | yes | yes | no |
| `qr_manage` | yes | yes | yes | no | no |
| `analytics_view` | yes | yes | yes | yes | yes |
| `team_manage` | yes | yes | no | no | no |

## Schema Additions

New table:

- `public.business_team_memberships`

Purpose:

- branch-only access: `business_id`
- all-branches access: `chain_id`
- accepted members: `user_id`
- pending invites: `invite_email`

Security:

- RLS enabled
- direct read limited to `admin` or the member row owner
- mutations are expected through security-definer RPCs

## New / Updated RPCs

New:

- `business_role_rank_v1`
- `business_role_has_permission_v1`
- `get_business_role_v1`
- `has_business_permission_v1`
- `can_view_business_v1`
- `can_manage_branch_v1`
- `owner_list_accessible_businesses_v1`
- `list_team_members_v1`
- `upsert_team_member_v1`
- `update_team_member_v1`
- `revoke_team_member_v1`
- `admin_list_user_business_access_v1`
- `admin_log_impersonation_v1`

Updated:

- `current_user_role_v1`
- `is_owner_of_business`
- `can_manage_business_v1`

## Panel Surface

Owner:

- `/owner/team`
  - selected business context aware
  - invite by email
  - role change
  - scope change: `Only this branch` / `All branches`
  - revoke member

Admin:

- `/admin/users/:id`
  - preview accessible businesses
  - role override preview
  - start impersonation
  - stop impersonation
  - every start/stop action is written to `admin_audit_log`

Cross-panel:

- owner shell shows active impersonation banner
- admin shell shows active impersonation banner
- business permission checks use `has_business_permission_v1`

## Current Tradeoff

This is a migration-friendly first cut, not the final end-state.

- Legacy owner RPCs still gate mostly through `is_owner_of_business`.
- `is_owner_of_business` now maps to `menu_write`, so `owner/manager/editor` can pass legacy owner write gates.
- This keeps existing owner flows working without rewriting every historical RPC in one turn.
- If stricter separation is needed later, legacy owner RPCs should be migrated one by one from `is_owner_of_business(...)` to explicit `has_business_permission_v1(..., '<permission>')`.

## Smoke Plan

### Owner

1. Login as an owner who has an approved `owner_claim`.
2. Open `/owner/businesses` and verify accessible businesses are listed.
3. Select a business and open `/owner/team`.
4. Add one `manager` with `Only this branch`.
5. Add one `editor` with `All branches` on a chain business.
6. Confirm both entries are visible in the team list.

### Manager

1. Login as the invited/linked manager.
2. Confirm `current_user_role_v1` resolves panel access to owner routes.
3. Open `/owner/businesses` and verify only scoped businesses appear.
4. Open `/owner/team` for the scoped branch.
5. Confirm team page is accessible and role/scope updates are allowed.

### Staff

1. Login as a linked `staff` member.
2. Open `/owner/businesses` and verify scoped businesses appear.
3. Open `/owner`.
4. Confirm dashboard/read surfaces are available.
5. Attempt `/owner/team` and confirm access is denied.
6. Attempt menu editing paths and confirm manage access is denied by UI gate.

### Admin Impersonation

1. Login as admin.
2. Open `/admin/users/<target-user-id>`.
3. Verify business access preview loads.
4. Start impersonation with actual role.
5. Confirm owner shell shows impersonation banner.
6. Stop impersonation.
7. Verify `admin_audit_log` contains `admin.impersonation.start` and `admin.impersonation.stop`.

## Verification

- `flutter analyze`
- `flutter build web --release --target lib/main_web_owner.dart --dart-define=DEV_TOOLS_ENABLED=false`
- `flutter build web --release --target lib/main_web_admin.dart --dart-define=DEV_TOOLS_ENABLED=false`
