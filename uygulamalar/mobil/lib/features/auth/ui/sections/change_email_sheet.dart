part of '../account_security_page.dart';

// ── E-posta değiştirme sheet ──────────────────────────────────────────────────

class _ChangeEmailSheet extends StatefulWidget {
  const _ChangeEmailSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  final _emailCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  bool get _requiresReauth =>
      widget.ref.read(authServiceProvider).hasPasswordIdentity;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _currentPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(
        () => _error = context.l10n.accountSecurityChangeEmailErrorInvalid,
      );
      return;
    }
    if (_requiresReauth && _currentPassCtrl.text.isEmpty) {
      setState(
        () =>
            _error = context.l10n.accountSecurityChangeEmailErrorReauthRequired,
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authService = widget.ref.read(authServiceProvider);
      if (_requiresReauth) {
        try {
          await authService.verifyCurrentPassword(_currentPassCtrl.text);
        } catch (_) {
          if (mounted) {
            setState(() {
              _error = context.l10n.accountSecurityChangeEmailErrorReauthFailed;
              _loading = false;
            });
          }
          return;
        }
      }
      await authService.updateEmail(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _sent
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 40,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.accountSecurityChangeEmailSentBody(
                    _emailCtrl.text.trim(),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.accountSecurityOkButton),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.accountSecurityChangeEmailTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.accountSecurityChangeEmailSubtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.l10n.accountSecurityNewEmailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                if (_requiresReauth) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _currentPassCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText:
                          context.l10n.accountSecurityCurrentPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_person_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: Text(
                    _loading
                        ? context.l10n.accountSecuritySendingLabel
                        : context
                              .l10n
                              .accountSecuritySendVerificationLinkButton,
                  ),
                ),
              ],
            ),
    );
  }
}
