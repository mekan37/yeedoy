part of '../account_security_page.dart';

// ── İki Adımlı Doğrulama sheet ───────────────────────────────────────────────

enum TfaState { checking, notEnrolled, enrolling, enrolled, disabling }

class _TwoFactorSheet extends StatefulWidget {
  const _TwoFactorSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_TwoFactorSheet> createState() => _TwoFactorSheetState();
}

class _TwoFactorSheetState extends State<_TwoFactorSheet> {
  TfaState _state = TfaState.checking;
  String? _factorId;
  String? _totpUri;
  String? _totpSecret;
  String? _error;
  bool _loading = false;
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkEnrollment();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkEnrollment() async {
    try {
      final client = widget.ref.read(supabaseProvider);
      final res = await client.auth.mfa.listFactors();
      final verified =
          (res.totp as List?)
              ?.where((f) => (f.status as String?) == 'verified')
              .toList() ??
          [];
      if (mounted) {
        setState(() {
          if (verified.isNotEmpty) {
            _state = TfaState.enrolled;
            _factorId = (verified.first as dynamic).id as String?;
          } else {
            _state = TfaState.notEnrolled;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = TfaState.notEnrolled);
    }
  }

  Future<void> _startEnroll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = widget.ref.read(supabaseProvider);
      final res = await client.auth.mfa.enroll(factorType: FactorType.totp);
      final data = res as dynamic;
      if (!mounted) return;
      setState(() {
        _totpUri = (data.totp?.uri ?? data.data?.totp?.uri) as String?;
        _totpSecret = (data.totp?.secret ?? data.data?.totp?.secret) as String?;
        _factorId = (data.id ?? data.data?.id) as String?;
        _state = TfaState.enrolling;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.accountSecurity2faEnrollStartError;
        _loading = false;
      });
    }
  }

  Future<void> _verifyAndActivate() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = context.l10n.accountSecurity2faCodeRequiredError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = widget.ref.read(supabaseProvider);
      final challenge = await client.auth.mfa.challenge(factorId: _factorId!);
      final challengeId =
          ((challenge as dynamic).id ?? (challenge as dynamic).data?.id)
              as String?;
      await client.auth.mfa.verify(
        factorId: _factorId!,
        challengeId: challengeId!,
        code: code,
      );
      if (mounted) {
        setState(() {
          _state = TfaState.enrolled;
          _loading = false;
          _codeCtrl.clear();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.accountSecurity2faVerifyCodeInvalid;
        _loading = false;
      });
    }
  }

  Future<void> _disableConfirm() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = context.l10n.accountSecurity2faCodeRequiredError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = widget.ref.read(supabaseProvider);
      final challenge = await client.auth.mfa.challenge(factorId: _factorId!);
      final challengeId =
          ((challenge as dynamic).id ?? (challenge as dynamic).data?.id)
              as String?;
      await client.auth.mfa.verify(
        factorId: _factorId!,
        challengeId: challengeId!,
        code: code,
      );
      await client.auth.mfa.unenroll(_factorId!);
      if (mounted) {
        setState(() {
          _state = TfaState.notEnrolled;
          _loading = false;
          _factorId = null;
          _codeCtrl.clear();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.accountSecurity2faDisableCodeInvalid;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
                  Icons.smartphone_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.accountSecurity2faTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.textStrong,
                      ),
                    ),
                    Text(
                      context.l10n.accountSecurity2faSheetSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_state == TfaState.checking)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_state == TfaState.notEnrolled)
            _buildNotEnrolled()
          else if (_state == TfaState.enrolling)
            _buildEnrolling()
          else if (_state == TfaState.enrolled)
            _buildEnrolled()
          else if (_state == TfaState.disabling)
            _buildDisabling(),
        ],
      ),
    );
  }

  Widget _buildNotEnrolled() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          context.l10n.accountSecurity2faNotEnrolledBody,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(
          _error!,
          style: const TextStyle(color: AppColors.danger, fontSize: 13),
        ),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _loading ? null : _startEnroll,
        icon: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.lock_open_rounded, size: 18),
        label: Text(
          _loading
              ? context.l10n.accountSecurity2faStartingLabel
              : context.l10n.accountSecurity2faStartSetupButton,
        ),
      ),
    ],
  );

  Widget _buildEnrolling() {
    final uri = _totpUri ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.accountSecurity2faStep1,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textStrong,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        if (uri.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: uri,
                version: QrVersions.auto,
                size: 180,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.textStrong,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textStrong,
                ),
              ),
            ),
          ),
        if (_totpSecret != null) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.accountSecurity2faSecretLabel,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _totpSecret!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.accountSecurity2faSecretCopied),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _totpSecret!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        letterSpacing: 1.5,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          context.l10n.accountSecurity2faStep2,
          style: const TextStyle(fontSize: 13, color: AppColors.textStrong),
        ),
        const SizedBox(height: 8),
        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(color: AppColors.danger, fontSize: 13),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: TextStyle(color: AppColors.muted, letterSpacing: 8),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : _verifyAndActivate,
          child: Text(
            _loading
                ? context.l10n.accountSecurity2faVerifyingLabel
                : context.l10n.accountSecurity2faVerifyButton,
          ),
        ),
      ],
    );
  }

  Widget _buildEnrolled() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.accountSecurity2faEnabledBanner,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF15803D),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => setState(() => _state = TfaState.disabling),
        icon: const Icon(
          Icons.lock_open_rounded,
          size: 16,
          color: AppColors.danger,
        ),
        label: Text(
          context.l10n.accountSecurity2faDisableButton,
          style: const TextStyle(color: AppColors.danger),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.danger),
        ),
      ),
    ],
  );

  Widget _buildDisabling() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          context.l10n.accountSecurity2faDisablePrompt,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (_error != null) ...[
        Text(
          _error!,
          style: const TextStyle(color: AppColors.danger, fontSize: 13),
        ),
        const SizedBox(height: 6),
      ],
      TextField(
        controller: _codeCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
        ),
        decoration: const InputDecoration(
          counterText: '',
          hintText: '000000',
          hintStyle: TextStyle(color: AppColors.muted, letterSpacing: 8),
        ),
      ),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: _loading ? null : _disableConfirm,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
        ),
        child: Text(
          _loading
              ? context.l10n.accountSecurity2faProcessingLabel
              : context.l10n.accountSecurity2faDisableButton,
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => setState(() {
          _state = TfaState.enrolled;
          _error = null;
          _codeCtrl.clear();
        }),
        child: Text(context.l10n.accountSecurityCancelButton),
      ),
    ],
  );
}

