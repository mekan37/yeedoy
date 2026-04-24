import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/business_rbac.dart';
import '../../../core/security/business_rbac_localizations.dart';
import '../../../features/owner_businesses/domain/owner_business_providers.dart';
import '../../../features/owner_businesses/domain/owner_business_state.dart';
import '../../../shared/ui/components/owner_business_guard.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../data/owner_team_repository.dart';
import '../domain/owner_team_models.dart';

final _teamMembersProvider =
    FutureProvider.autoDispose.family<List<OwnerTeamMember>, String>((ref, businessId) {
      return ref.read(ownerTeamRepositoryProvider).listMembers(businessId);
    });

class OwnerTeamPage extends ConsumerStatefulWidget {
  const OwnerTeamPage({super.key, this.businessId});

  final String? businessId;

  @override
  ConsumerState<OwnerTeamPage> createState() => _OwnerTeamPageState();
}

class _OwnerTeamPageState extends ConsumerState<OwnerTeamPage> {
  final _emailController = TextEditingController();
  OwnerTeamRole _role = OwnerTeamRole.manager;
  TeamAccessScope _scope = TeamAccessScope.thisBusiness;
  bool _saving = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedOwnerBusinessIdProvider);
    final businessId = widget.businessId?.trim().isNotEmpty == true
        ? widget.businessId!.trim()
        : (selectedId ?? '');
    return OwnerBusinessGuard(
      businessId: businessId,
      permission: BusinessPermission.teamManage,
      builder: (context, ref) {
        final businessesAsync = ref.watch(ownerBusinessesProvider);
        final membersAsync = ref.watch(_teamMembersProvider(businessId));
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_teamMembersProvider(businessId));
            ref.invalidate(ownerBusinessesProvider);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              PanelPageHeader(
                eyebrow: 'Owner',
                title: Text(context.l10n.ownerTeamTitle),
                description: context.l10n.ownerTeamDescription,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                businessesAsync.maybeWhen(
                  data: (items) {
                    String? businessName;
                    for (final item in items) {
                      if (item.businessId == businessId) {
                        businessName = item.businessName;
                        break;
                      }
                    }
                    return _BusinessSummaryCard(businessName: businessName);
                  },
                  orElse: SizedBox.new,
                ),
                const SizedBox(height: 16),
                _InviteCard(
                  emailController: _emailController,
                  selectedRole: _role,
                  selectedScope: _scope,
                  saving: _saving,
                  onRoleChanged: (value) => setState(() => _role = value),
                  onScopeChanged: (value) => setState(() => _scope = value),
                  onSubmit: () => _submitInvite(businessId),
                ),
                const SizedBox(height: 16),
                membersAsync.when(
                  loading: () => const OwnerPanelFeedback.loading(cardCount: 2),
                  error: (error, _) => OwnerPanelFeedback.error(
                    title: context.l10n.ownerTeamLoadErrorTitle,
                    description: AppErrorMapper.message(error),
                    onRetry: () => ref.invalidate(_teamMembersProvider(businessId)),
                  ),
                  data: (members) {
                    if (members.isEmpty) {
                      return OwnerPanelFeedback.empty(
                        icon: Icons.groups_outlined,
                        title: context.l10n.ownerTeamEmptyTitle,
                        description: context.l10n.ownerTeamEmptyDescription,
                      );
                    }
                    return Column(
                      children: [
                        for (final member in members)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TeamMemberCard(
                              member: member,
                              saving: _saving,
                              onChanged: member.isReadOnly || member.membershipId == null
                                  ? null
                                  : (role, scope) =>
                                        _updateMember(businessId, member, role, scope),
                              onRevoke: member.isReadOnly || member.membershipId == null
                                  ? null
                                  : () => _revokeMember(businessId, member.membershipId!),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitInvite(String businessId) async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack(context.l10n.ownerTeamEmailRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(ownerTeamRepositoryProvider)
          .inviteOrAssign(
            businessId: businessId,
            email: email,
            role: _role,
            scope: _scope,
          );
      if (!mounted) return;
      _emailController.clear();
      ref.invalidate(_teamMembersProvider(businessId));
      _showSnack(context.l10n.ownerTeamSaved);
    } catch (error) {
      if (!mounted) return;
      _showSnack(AppErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateMember(
    String businessId,
    OwnerTeamMember member,
    OwnerTeamRole role,
    TeamAccessScope scope,
  ) async {
    final membershipId = member.membershipId;
    if (membershipId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(ownerTeamRepositoryProvider)
          .updateMember(
            businessId: businessId,
            membershipId: membershipId,
            role: role,
            scope: scope,
          );
      if (!mounted) return;
      ref.invalidate(_teamMembersProvider(businessId));
      _showSnack(context.l10n.ownerTeamUpdated);
    } catch (error) {
      if (!mounted) return;
      _showSnack(AppErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _revokeMember(String businessId, String membershipId) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(ownerTeamRepositoryProvider)
          .revokeMember(
            businessId: businessId,
            membershipId: membershipId,
          );
      if (!mounted) return;
      ref.invalidate(_teamMembersProvider(businessId));
      _showSnack(context.l10n.ownerTeamRemoved);
    } catch (error) {
      if (!mounted) return;
      _showSnack(AppErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BusinessSummaryCard extends StatelessWidget {
  const _BusinessSummaryCard({this.businessName});

  final String? businessName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.apartment_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              businessName == null || businessName!.isEmpty
                  ? context.l10n.ownerTeamSelectedBranchFallback
                  : businessName!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            context.l10n.ownerTeamScopeAwareBadge,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.emailController,
    required this.selectedRole,
    required this.selectedScope,
    required this.saving,
    required this.onRoleChanged,
    required this.onScopeChanged,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final OwnerTeamRole selectedRole;
  final TeamAccessScope selectedScope;
  final bool saving;
  final ValueChanged<OwnerTeamRole> onRoleChanged;
  final ValueChanged<TeamAccessScope> onScopeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.ownerTeamInviteTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: context.l10n.ownerTeamEmailLabel,
              hintText: context.l10n.ownerTeamEmailHint,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<OwnerTeamRole>(
                  initialValue: selectedRole,
                  items: [
                    for (final role in OwnerTeamRole.values)
                      DropdownMenuItem(
                        value: role,
                        child: Text(context.l10n.ownerTeamRoleLabel(role)),
                      ),
                  ],
                  onChanged: saving ? null : (value) => onRoleChanged(value!),
                  decoration: InputDecoration(
                    labelText: context.l10n.ownerTeamRoleFieldLabel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<TeamAccessScope>(
                  initialValue: selectedScope,
                  items: [
                    for (final scope in TeamAccessScope.values)
                      DropdownMenuItem(
                        value: scope,
                        child: Text(context.l10n.ownerTeamScopeLabel(scope)),
                      ),
                  ],
                  onChanged: saving ? null : (value) => onScopeChanged(value!),
                  decoration: InputDecoration(
                    labelText: context.l10n.ownerTeamScopeFieldLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: saving ? null : onSubmit,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_outlined),
            label: Text(
              saving
                  ? context.l10n.saving
                  : context.l10n.ownerTeamSaveMemberAction,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMemberCard extends StatefulWidget {
  const _TeamMemberCard({
    required this.member,
    required this.saving,
    this.onChanged,
    this.onRevoke,
  });

  final OwnerTeamMember member;
  final bool saving;
  final Future<void> Function(OwnerTeamRole role, TeamAccessScope scope)? onChanged;
  final VoidCallback? onRevoke;

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<_TeamMemberCard> {
  late OwnerTeamRole _role = widget.member.role;
  late TeamAccessScope _scope = widget.member.scope;

  @override
  Widget build(BuildContext context) {
    final editable = widget.onChanged != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.member.email,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _StatusChip(
                label: widget.member.isPending
                    ? context.l10n.ownerTeamStatusPendingInvite
                    : context.l10n.ownerTeamStatusActive,
                danger: widget.member.isPending,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.ownerTeamSourceValue(
              _sourceLabel(context, widget.member.source),
            ),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<OwnerTeamRole>(
                  initialValue: _role,
                  items: [
                    for (final role in OwnerTeamRole.values)
                      DropdownMenuItem(
                        value: role,
                        child: Text(context.l10n.ownerTeamRoleLabel(role)),
                      ),
                  ],
                  onChanged: editable && !widget.saving
                      ? (value) => setState(() => _role = value!)
                      : null,
                  decoration: InputDecoration(
                    labelText: context.l10n.ownerTeamRoleFieldLabel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<TeamAccessScope>(
                  initialValue: _scope,
                  items: [
                    for (final scope in TeamAccessScope.values)
                      DropdownMenuItem(
                        value: scope,
                        child: Text(context.l10n.ownerTeamScopeLabel(scope)),
                      ),
                  ],
                  onChanged: editable && !widget.saving
                      ? (value) => setState(() => _scope = value!)
                      : null,
                  decoration: InputDecoration(
                    labelText: context.l10n.ownerTeamScopeFieldLabel,
                  ),
                ),
              ),
            ],
          ),
          if (editable) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: widget.saving
                      ? null
                      : () => widget.onChanged?.call(_role, _scope),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(context.l10n.ownerTeamUpdateAction),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: widget.saving ? null : widget.onRevoke,
                  icon: const Icon(Icons.person_remove_outlined),
                  label: Text(context.l10n.ownerTeamRemoveAction),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _sourceLabel(BuildContext context, String source) {
  switch (source.trim().toLowerCase()) {
    case 'owner_claim':
      return context.l10n.ownerTeamSourceOwnerClaim;
    case 'chain_membership':
      return context.l10n.ownerTeamSourceChainMembership;
    case 'direct':
      return context.l10n.ownerTeamSourceDirect;
    default:
      return source;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    this.danger = false,
  });

  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: danger
            ? AppColors.danger.withValues(alpha: 0.12)
            : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: danger ? AppColors.danger : AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
