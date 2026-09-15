part of '../account_security_page.dart';

// ── Şifre değiştirme sheet ────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _requiresReauth =>
      widget.ref.read(authServiceProvider).hasPasswordIdentity;

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pass = _newPassCtrl.text;
    if (_requiresReauth && _currentPassCtrl.text.isEmpty) {
      setState(
        () => _error =
            context.l10n.accountSecurityChangePasswordErrorReauthRequired,
      );
      return;
    }
    if (pass.length < 6) {
      setState(
        () => _error = context.l10n.accountSecurityChangePasswordErrorTooShort,
      );
      return;
    }
    if (pass != _confirmCtrl.text) {
      setState(
        () => _error = context.l10n.accountSecurityChangePasswordErrorMismatch,
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
              _error =
                  context.l10n.accountSecurityChangePasswordErrorReauthFailed;
              _loading = false;
            });
          }
          return;
        }
      }
      await authService.updatePassword(pass);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountSecurityPasswordUpdated)),
        );
      }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.accountSecurityChangePasswordTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          if (_requiresReauth) ...[
            TextField(
              controller: _currentPassCtrl,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.accountSecurityCurrentPasswordLabel,
                prefixIcon: const Icon(Icons.lock_person_outlined),
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _newPassCtrl,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.l10n.accountSecurityNewPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: context.l10n.accountSecurityNewPasswordConfirmLabel,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: Text(
              _loading
                  ? context.l10n.accountSecuritySavingLabel
                  : context.l10n.accountSecurityUpdatePasswordButton,
            ),
          ),
        ],
      ),
    );
  }
}

