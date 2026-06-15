import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/brand/brand_widgets.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/route_sanitizer.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../legal/legal_linking.dart';
import '../../legal/legal_providers.dart';
import '../../legal/legal_repository.dart';
import '../../legal/ui/widgets/legal_required_consent_card.dart';
import '../../../app/theme/colors.dart';
import '../data/auth_service_provider.dart';

enum _AuthMode { email, phone, google }

enum _AuthAction { signIn, signUp, googleSignIn, phoneOtp }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialSignup = false});

  final bool initialSignup;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Email
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Telefon OTP
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;

  // UI State
  _AuthMode _mode = _AuthMode.email;
  bool _loading = false;
  bool _acceptedRequiredPolicies = false;
  String? _errorMessage;
  _AuthAction? _lastAction;
  bool _showSignupPrompt = false;
  late bool _signupIntent;

  @override
  void initState() {
    super.initState();
    _signupIntent = widget.initialSignup;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ── Navigasyon ────────────────────────────────────────────────────────────

  void _navigateAfterLogin() {
    if (!mounted) return;
    final rawRedirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    final target = sanitizeInternalRedirect(rawRedirect) ?? '/discover';
    context.go(target);
  }

  // ── Email işlemleri ───────────────────────────────────────────────────────

  Future<void> _signIn() async {
    _setLoading(_AuthAction.signIn);
    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.loginSuccess,
            source: 'login_page_email',
          );
      _navigateAfterLogin();
    } catch (e) {
      ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.loginFailure,
            source: 'login_page_email',
            meta: {'error': AppErrorMapper.message(e)},
          );
      _setError(e);
    } finally {
      _clearLoading();
    }
  }

  Future<void> _signUp() async {
    if (!_acceptedRequiredPolicies) {
      setState(() {
        _errorMessage =
            'Kayıt olmadan önce Kullanım Şartları ve Gizlilik Politikası\'nı kabul etmelisiniz.';
      });
      return;
    }
    _setLoading(_AuthAction.signUp);
    try {
      final response = await ref
          .read(authServiceProvider)
          .signUpWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      if (response.session != null) {
        try {
          final snapshot = await ref
              .read(legalRepositoryProvider)
              .loadAcceptanceSnapshot();
          if (snapshot != null && snapshot.pendingRequiredVersions.isNotEmpty) {
            await ref
                .read(legalRepositoryProvider)
                .acceptPolicyVersions(snapshot.pendingRequiredVersions);
          }
        } finally {
          ref.invalidate(legalAcceptanceSnapshotProvider);
        }
      }
      ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.signupSuccess,
            source: 'login_page_email',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loginSignupSuccessMessage)),
      );
    } catch (e) {
      ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.signupFailure,
            source: 'login_page_email',
            meta: {'error': AppErrorMapper.message(e)},
          );
      _setError(e);
    } finally {
      _clearLoading();
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    _setLoading(_AuthAction.googleSignIn);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.loginSuccess,
            source: 'login_page_google',
          );
      _navigateAfterLogin();
    } catch (e) {
      ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.loginFailure,
            source: 'login_page_google',
            meta: {'error': AppErrorMapper.message(e)},
          );
      _setError(e);
    } finally {
      _clearLoading();
    }
  }

  // ── Telefon OTP ────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _errorMessage = 'Geçerli bir telefon numarası girin.');
      return;
    }
    // E.164 formatına çevir
    final e164 = _toE164(phone);
    _setLoading(_AuthAction.phoneOtp);
    try {
      await ref.read(authServiceProvider).sendPhoneOtp(e164);
      setState(() {
        _otpSent = true;
        _errorMessage = null;
      });
    } catch (e) {
      _setError(e);
    } finally {
      _clearLoading();
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _toE164(_phoneCtrl.text.trim());
    final token = _otpCtrl.text.trim();
    if (token.length < 4) {
      setState(() => _errorMessage = 'Geçersiz OTP kodu.');
      return;
    }
    _setLoading(_AuthAction.phoneOtp);
    try {
      await ref
          .read(authServiceProvider)
          .verifyPhoneOtp(phone: phone, token: token);
      _navigateAfterLogin();
    } catch (e) {
      _setError(e);
    } finally {
      _clearLoading();
    }
  }

  String _toE164(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'\s|-|\(|\)'), '');
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('0')) cleaned = cleaned.substring(1);
      cleaned = '+90$cleaned';
    }
    return cleaned;
  }

  // ── State yardımcıları ─────────────────────────────────────────────────────

  void _setLoading(_AuthAction action) {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _showSignupPrompt = false;
      _lastAction = action;
    });
  }

  void _clearLoading() {
    if (mounted) setState(() => _loading = false);
  }

  void _setError(Object e) {
    if (!mounted) return;
    final t = context.l10n;
    final localizedMsg = _localizeAuthError(e, t);
    final showSignup = _lastAction == _AuthAction.signIn &&
        (e.toString().toLowerCase().contains('invalid login') ||
            e.toString().toLowerCase().contains('invalid_credentials') ||
            e.toString().toLowerCase().contains('user not found') ||
            e.toString().toLowerCase().contains('no user'));
    setState(() {
      _errorMessage = localizedMsg;
      _showSignupPrompt = showSignup;
    });
  }

  String _localizeAuthError(Object error, AppLocalizations t) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('email not confirmed')) {
      return t.authErrorEmailNotConfirmed;
    }
    if (msg.contains('invalid login') ||
        msg.contains('invalid_credentials') ||
        msg.contains('credentials')) {
      return t.authErrorInvalidCredentials;
    }
    if (msg.contains('too many requests') || msg.contains('rate')) {
      return t.authErrorTooManyRequests;
    }
    if (msg.contains('user not found') || msg.contains('no user')) {
      return t.authErrorUserNotFound;
    }
    // Bilinmeyen AuthException → generic mesaj
    if (error.toString().contains('AuthException') ||
        error.toString().contains('AuthApiException')) {
      return t.authErrorGeneric;
    }
    return AppErrorMapper.message(error);
  }

  Future<void> _retryLastAction() async {
    switch (_lastAction) {
      case _AuthAction.signIn:
        await _signIn();
      case _AuthAction.signUp:
        await _signUp();
      case _AuthAction.googleSignIn:
        await _signInWithGoogle();
      case _AuthAction.phoneOtp:
        _otpSent ? await _verifyOtp() : await _sendOtp();
      case null:
        return;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppScaffold(
      appBar: AppBar(title: Text(t.loginPageTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          if (_loading) ...[
            const AppSkeletonLine(width: double.infinity),
            const SizedBox(height: 10),
          ],
          if (_errorMessage != null) ...[
            AppEmptyState(
              icon: Icons.wifi_off_outlined,
              title: t.loginActionFailedTitle,
              description: _errorMessage ?? '',
              ctaLabel: _lastAction == null ? null : t.retry,
              onCta: _lastAction == null ? null : _retryLastAction,
            ),
            if (_showSignupPrompt) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _showSignupPrompt = false;
                    _errorMessage = null;
                    _mode = _AuthMode.email;
                    _signupIntent = true;
                  }),
                  child: const Text(
                    'Hesap oluşturmak ister misiniz? Kayıt Ol',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          const BrandMascot(size: 56),
          const SizedBox(height: 10),
          Text(t.appName, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),

          // ── Mod seçim sekmeleri ─────────────────────────────────────────
          _ModeTabBar(
            selected: _mode,
            onSelect: (mode) => setState(() {
              _mode = mode;
              _otpSent = false;
              _errorMessage = null;
            }),
          ),
          const SizedBox(height: 20),

          // ── Aktif moda göre içerik ─────────────────────────────────────
          if (_mode == _AuthMode.email) ...[
            _EmailForm(
              emailCtrl: _emailCtrl,
              passCtrl: _passCtrl,
              loading: _loading,
              acceptedPolicies: _acceptedRequiredPolicies,
              signupIntent: _signupIntent,
              onAcceptPolicies: (v) =>
                  setState(() => _acceptedRequiredPolicies = v ?? false),
              onSignIn: _signIn,
              onSignUp: _signUp,
              onOpenLegalUrl: _openLegalUrl,
              onForgotPassword: () => context.push('/forgot-password'),
            ),
          ] else if (_mode == _AuthMode.phone) ...[
            _PhoneForm(
              phoneCtrl: _phoneCtrl,
              otpCtrl: _otpCtrl,
              loading: _loading,
              otpSent: _otpSent,
              onSendOtp: _sendOtp,
              onVerifyOtp: _verifyOtp,
              onBack: () => setState(() => _otpSent = false),
            ),
          ] else ...[
            _GoogleSignInSection(
              loading: _loading,
              onSignIn: _signInWithGoogle,
            ),
          ],

          const SizedBox(height: 24),

          // ── Diğer yöntemlerle giriş (email modunda Google göster) ───────
          if (_mode == _AuthMode.email) ...[
            const _Divider(label: 'veya'),
            const SizedBox(height: 16),
            _SocialButton(
              icon: _GoogleIcon(),
              label: 'Google ile devam et',
              loading: _loading,
              onTap: _signInWithGoogle,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openLegalUrl(String url) async {
    try {
      await openLegalUrl(url);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(error))));
    }
  }
}

// ── Mod Sekme Çubuğu ──────────────────────────────────────────────────────────

class _ModeTabBar extends StatelessWidget {
  const _ModeTabBar({required this.selected, required this.onSelect});

  final _AuthMode selected;
  final ValueChanged<_AuthMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _Tab(
            icon: Icons.email_outlined,
            label: 'E-posta',
            active: selected == _AuthMode.email,
            onTap: () => onSelect(_AuthMode.email),
          ),
          _Tab(
            icon: Icons.phone_outlined,
            label: 'Telefon',
            active: selected == _AuthMode.phone,
            onTap: () => onSelect(_AuthMode.phone),
          ),
          _Tab(
            icon: Icons.account_circle_outlined,
            label: 'Google',
            active: selected == _AuthMode.google,
            onTap: () => onSelect(_AuthMode.google),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    const BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.primary : AppColors.muted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Email Formu ────────────────────────────────────────────────────────────────

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.emailCtrl,
    required this.passCtrl,
    required this.loading,
    required this.acceptedPolicies,
    required this.signupIntent,
    required this.onAcceptPolicies,
    required this.onSignIn,
    required this.onSignUp,
    required this.onOpenLegalUrl,
    required this.onForgotPassword,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool loading;
  final bool acceptedPolicies;
  final bool signupIntent;
  final ValueChanged<bool?> onAcceptPolicies;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final Future<void> Function(String) onOpenLegalUrl;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: t.loginEmailLabel,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passCtrl,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSignIn(),
          decoration: InputDecoration(
            labelText: t.loginPasswordLabel,
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 14),
        if (signupIntent) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kayıt işlemi sürüm bazlıdır. Yeni şartlar yayınlanırsa uygulama yeniden onay ister.',
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                LegalRequiredConsentCard(
                  value: acceptedPolicies,
                  disabled: loading,
                  helperText: 'Bu kabul yalnızca kayıt oluştururken zorunludur.',
                  onChanged: onAcceptPolicies,
                  onOpenLink: onOpenLegalUrl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 16),
        if (signupIntent) ...[
          FilledButton(
            onPressed: loading ? null : onSignUp,
            child: Text(loading ? t.loginSigningUpAction : t.loginSignupAction),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: loading ? null : onSignIn,
            child: Text(
              loading ? t.loginSigningInAction : t.loginPrimaryAction,
            ),
          ),
        ] else ...[
          FilledButton(
            onPressed: loading ? null : onSignIn,
            child: Text(
              loading ? t.loginSigningInAction : t.loginPrimaryAction,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: loading ? null : onSignUp,
            child: Text(loading ? t.loginSigningUpAction : t.loginSignupAction),
          ),
        ],
        const SizedBox(height: 4),
        TextButton(
          onPressed: loading ? null : onForgotPassword,
          child: const Text('Şifremi unuttum'),
        ),
      ],
    );
  }
}

// ── Telefon OTP Formu ──────────────────────────────────────────────────────────

class _PhoneForm extends StatelessWidget {
  const _PhoneForm({
    required this.phoneCtrl,
    required this.otpCtrl,
    required this.loading,
    required this.otpSent,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onBack,
  });

  final TextEditingController phoneCtrl;
  final TextEditingController otpCtrl;
  final bool loading;
  final bool otpSent;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (!otpSent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Telefon numaranıza SMS ile doğrulama kodu gönderilecek.',
                    style: TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
            ],
            onSubmitted: (_) => onSendOtp(),
            decoration: const InputDecoration(
              labelText: 'Telefon numarası',
              hintText: '05XX XXX XX XX',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'Türkiye: 0 ile başlayan 11 haneli numara',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : onSendOtp,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(loading ? 'Gönderiliyor…' : 'SMS Kodu Gönder'),
          ),
        ],
      );
    }

    // OTP girişi
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${phoneCtrl.text} numarasına SMS gönderildi.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: otpCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onVerifyOtp(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 12,
          ),
          decoration: const InputDecoration(
            labelText: 'Doğrulama kodu',
            hintText: '000000',
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: loading ? null : onVerifyOtp,
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.verified_outlined, size: 18),
          label: Text(loading ? 'Doğrulanıyor…' : 'Kodu Doğrula'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: loading ? null : onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Farklı numara kullan'),
        ),
      ],
    );
  }
}

// ── Google Sign-In Bölümü ──────────────────────────────────────────────────────

class _GoogleSignInSection extends StatelessWidget {
  const _GoogleSignInSection({required this.loading, required this.onSignIn});

  final bool loading;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _GoogleIcon(size: 40),
              const SizedBox(height: 12),
              const Text(
                'Google hesabınızla devam edin',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Hızlı ve güvenli giriş için Google hesabınızı kullanın.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _SocialButton(
                icon: _GoogleIcon(),
                label: 'Google ile giriş yap',
                loading: loading,
                onTap: onSignIn,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Paylaşılan yardımcı widget'lar ────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.border),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            icon,
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon({this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    // Google renkli "G" harfi
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Kırmızı yay
    _drawArc(canvas, cx, cy, r, -30, 120, const Color(0xFFEA4335));
    // Sarı yay
    _drawArc(canvas, cx, cy, r, 90, 60, const Color(0xFFFBBC05));
    // Yeşil yay
    _drawArc(canvas, cx, cy, r, 150, 90, const Color(0xFF34A853));
    // Mavi yay
    _drawArc(canvas, cx, cy, r, 240, 90, const Color(0xFF4285F4));
  }

  void _drawArc(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double startDeg,
    double sweepDeg,
    Color color,
  ) {
    const d2r = 3.14159265 / 180.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.28;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      startDeg * d2r,
      sweepDeg * d2r,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GoogleGPainter _) => false;
}
