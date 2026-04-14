import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/admin_impersonation_provider.dart';
import '../../../core/security/business_rbac.dart';
import '../../../core/security/business_rbac_localizations.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../../shared/ui/components/permission_denied_view.dart';
import '../data/admin_user_access_repository.dart';
import '../domain/admin_access_provider.dart';
import '../domain/admin_user_access_models.dart';

final _userBusinessAccessProvider = FutureProvider.autoDispose.family<
  List<AdminUserBusinessAccess>,
  (String, OwnerTeamRole?)
>((ref, request) {
  return ref
      .read(adminUserAccessRepositoryProvider)
      .listBusinessAccess(userId: request.$1, roleOverride: request.$2);
});

class AdminUserAccessPage extends ConsumerStatefulWidget {
  const AdminUserAccessPage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserAccessPage> createState() => _AdminUserAccessPageState();
}

class _AdminUserAccessPageState extends ConsumerState<AdminUserAccessPage> {
  OwnerTeamRole? _roleOverride;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(adminAccessProvider);
    return accessAsync.when(
      loading: () => const Scaffold(body: OwnerPanelFeedback.loading()),
      error: (error, _) => Scaffold(body: Center(child: Text(error.toString()))),
      data: (allowed) {
        if (!allowed) {
          return Scaffold(
            body: PermissionDeniedView(
              title: context.l10n.forbiddenTitle,
              description: context.l10n.adminUserAccessForbiddenDescription,
            ),
          );
        }
        final accessListAsync = ref.watch(
          _userBusinessAccessProvider((widget.userId, _roleOverride)),
        );
        final impersonation = ref.watch(adminImpersonationProvider);
        final isActive = impersonation.userId == widget.userId;
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              PanelPageHeader(
                padding: EdgeInsets.zero,
                title: Text(context.l10n.adminUserAccessTitle),
                description: context.l10n.adminUserAccessDescription(
                  widget.userId,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<OwnerTeamRole?>(
                        key: ValueKey(_roleOverride),
                        initialValue: _roleOverride,
                        items: [
                          DropdownMenuItem<OwnerTeamRole?>(
                            value: null,
                            child: Text(context.l10n.adminImpersonationUseActualRoleOption),
                          ),
                          for (final role in OwnerTeamRole.values)
                            DropdownMenuItem<OwnerTeamRole?>(
                              value: role,
                              child: Text(context.l10n.ownerTeamRoleLabel(role)),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _roleOverride = value),
                        decoration: InputDecoration(
                          labelText: context.l10n.adminImpersonationRoleOverrideLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : _startImpersonation,
                      icon: const Icon(Icons.switch_account_outlined),
                      label: Text(
                        isActive
                            ? context.l10n.adminImpersonationRefreshAction
                            : context.l10n.adminImpersonationStartAction,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _busy || !isActive
                          ? null
                          : _stopImpersonation,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(context.l10n.adminImpersonationStopAction),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              accessListAsync.when(
                loading: () => const OwnerPanelFeedback.loading(cardCount: 2),
                error: (error, _) => OwnerPanelFeedback.error(
                  title: context.l10n.adminUserAccessLoadErrorTitle,
                  description: error.toString(),
                  onRetry: () => ref.invalidate(
                    _userBusinessAccessProvider((widget.userId, _roleOverride)),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return OwnerPanelFeedback.empty(
                      icon: Icons.no_accounts_outlined,
                      title: context.l10n.adminUserAccessEmptyTitle,
                      description: context.l10n.adminUserAccessEmptyDescription,
                    );
                  }
                  return Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.businessName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.l10n.adminUserAccessBusinessMeta(
                                          item.city,
                                          item.district,
                                          context.l10n.ownerTeamRoleLabel(item.role),
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      if ((item.chainName ?? '').isNotEmpty)
                                        Text(
                                          '${item.chainName} • ${item.branchLabel ?? '-'}',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => context.go(
                                    '/owner/businesses?businessId=${item.businessId}',
                                  ),
                                  child: Text(
                                    context.l10n.adminUserAccessOpenOwnerPanelAction,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startImpersonation() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminImpersonationActionsProvider)
          .start(
            userId: widget.userId,
            roleOverride: _roleOverride,
            userLabel: widget.userId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminImpersonationStarted)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopImpersonation() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminImpersonationActionsProvider).stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminImpersonationStopped)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
