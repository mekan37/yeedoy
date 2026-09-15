part of '../account_security_page.dart';

// ── Oturum Yönetimi sheet ─────────────────────────────────────────────────────

class _SessionManagementSheet extends StatelessWidget {
  const _SessionManagementSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final client = ref.read(supabaseProvider);
    final user = client.auth.currentUser;
    final email = user?.email ?? '';
    final lastSignIn = user?.lastSignInAt;
    final createdAt = user?.createdAt;

    String fmt(String? raw) {
      if (raw == null) return context.l10n.accountSecurityUnknown;
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt == null) return context.l10n.accountSecurityUnknown;
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '${formatShortDate(context, dt)}  $hh:$mm';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.key_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.accountSecuritySessionsTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.textStrong,
                    ),
                  ),
                  Text(
                    context.l10n.accountSecuritySessionsSheetSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Current session card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.l10n.accountSecurityActiveSessionBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SessionRow(
                  label: context.l10n.accountSecuritySessionEmailLabel,
                  value: email,
                ),
                const SizedBox(height: 6),
                _SessionRow(
                  label: context.l10n.accountSecuritySessionLastLoginLabel,
                  value: fmt(lastSignIn),
                ),
                const SizedBox(height: 6),
                _SessionRow(
                  label: context.l10n.accountSecuritySessionCreatedLabel,
                  value: fmt(createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFEDEAA)),
            ),
            child: Text(
              context.l10n.accountSecuritySessionWarning,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(
                    dialogContext.l10n.accountSecurityLogoutAllDialogTitle,
                  ),
                  content: Text(
                    dialogContext.l10n.accountSecurityLogoutAllDialogBody,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(
                        dialogContext.l10n.accountSecurityCancelButton,
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      child: Text(
                        dialogContext.l10n.accountSecurityLogoutAllCloseButton,
                      ),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                Navigator.pop(context);
                await ref.read(sessionCleanupServiceProvider).signOut();
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(context.l10n.accountSecurityLogoutAllButton),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textStrong),
          ),
        ),
      ],
    );
  }
}

