import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../uygulama/marka/marka_bilesenleri.dart';
import '../../../core/analitik/analitik_deposu.dart';
import '../../../core/analitik/uygulama_olaylari.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/depolama/biyometrik_tercihleri.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../../yasal/yasal_baglanti.dart';
import '../../yasal/yasal_saglayicilari.dart';
import '../../yasal/yasal_deposu.dart';
import '../../yasal/ui/yardimci_bilesenler/yasal_gerekli_onay_karti.dart';
import '../../../uygulama/tema/renkler.dart';
import '../data/kimlik_servisi_saglayicisi.dart';

enum _AuthMode { email, phone, google }

enum _AuthAction { signIn, signUp, googleSignIn, appleSignIn, phoneOtp }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialSignup = false});

  final bool initialSignup;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
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

  // M-6: Biyometrik
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _hasStoredSession = false;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final enabled = await BiyometrikTercihleri.isEnabled();
      final hasTokens = await BiyometrikTercihleri.hasStoredTokens();
      if (mounted) {
        setState(() {
          _biometricAvailable = canCheck && isSupported;
          _biometricEnabled = enabled;
          _hasStoredSession = hasTokens;
        });
        // Oturum varsa otomatik biometric tetikle
        if (_biometricAvailable && enabled && hasTokens) {
          await Future.delayed(const Duration(milliseconds: 400));
          await _signInWithBiometric();
        }
      }
    } catch (_) {}
  }

  Future<void> _signInWithBiometric() async {
    if (!_biometricAvailable || !_biometricEnabled) return;
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Yeedoy\'a giriş yapmak için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!didAuth) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      // Token'ları restore et
      final tokens = await BiyometrikTercihleri.loadTokens();
      if (tokens.accessToken == null || tokens.refreshToken == null) {
        await BiyometrikTercihleri.clearTokens();
        if (mounted) setState(() { _loading = false; _hasStoredSession = false; });
        return;
      }
      final response = await Supabase.instance.client.auth.setSession(
        tokens.accessToken!,
      );
      if (response.session == null) {
        // Access token süresi dolmuş, refresh ile dene
        final refreshed = await Supabase.instance.client.auth.refreshSession();
        if (refreshed.session == null) {
          await BiyometrikTercihleri.clearTokens();
          if (mounted) setState(() { _loading = false; _hasStoredSession = false; });
          return;
        }
        // Yeni token'ları kaydet
        await BiyometrikTercihleri.saveTokens(
          accessToken:  refreshed.session!.accessToken,
          refreshToken: refreshed.session!.refreshToken!,
        );
      }
      HapticFeedback.lightImpact();
      _navigateAfterLogin();
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _errorMessage = 'Biyometrik doğrulama başarısız.'; });
        _shakeAndVibrate();
      }
    }
  }

  // M-10: Hata silkeleme animasyonu
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _shakeAnim = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -8, end: 8),  weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8, end: -6),  weight: 2),
    TweenSequenceItem(tween: Tween(begin: -6, end: 6),  weight: 2),
    TweenSequenceItem(tween: Tween(begin: 6, end: 0),   weight: 1),
  ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

  Future<void> _saveSessionIfBiometricEnabled() async {
    try {
      if (!await BiyometrikTercihleri.isEnabled()) return;
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null || session.refreshToken == null) return;
      await BiyometrikTercihleri.saveTokens(
        accessToken:  session.accessToken,
        refreshToken: session.refreshToken!,
      );
    } catch (_) {}
  }

  Future<void> _shakeAndVibrate() async {
    HapticFeedback.heavyImpact(); // M-8
    await _shakeCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Navigasyon ────────────────────────────────────────────────────────────

  void _navigateAfterLogin() {
    if (!mounted) return;
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    final target =
        (redirect != null && redirect.isNotEmpty && redirect != '/login')
        ? Uri.decodeComponent(redirect)
        : '/discover';
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
      await _saveSessionIfBiometricEnabled();
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

  // ── Apple Sign-In ──────────────────────────────────────────────────────────

  Future<void> _signInWithApple() async {
    _setLoading(_AuthAction.appleSignIn);
    try {
      await ref.read(authServiceProvider).signInWithApple();
      ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.loginSuccess,
            source: 'login_page_apple',
          );
      _navigateAfterLogin();
    } catch (e) {
      ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.loginFailure,
            source: 'login_page_apple',
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
      _lastAction = action;
    });
  }

  void _clearLoading() {
    if (mounted) setState(() => _loading = false);
  }

  void _setError(Object e) {
    if (mounted) {
      setState(() => _errorMessage = AppErrorMapper.message(e));
      _shakeAndVibrate();
    }
  }

  Future<void> _retryLastAction() async {
    switch (_lastAction) {
      case _AuthAction.signIn:
        await _signIn();
      case _AuthAction.signUp:
        await _signUp();
      case _AuthAction.googleSignIn:
        await _signInWithGoogle();
      case _AuthAction.appleSignIn:
        await _signInWithApple();
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
      appBar: AppBar(
        title: Text(t.loginPageTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8, -0.8),
                  radius: 1.4,
                  colors: [Color(0x1A7F1D1D), Color(0x00F9FAFB)],
                ),
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7F1D1D).withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDC2626).withValues(alpha: 0.04),
              ),
            ),
          ),
          // Content
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (_loading) ...[
                const AppSkeletonLine(width: double.infinity),
                const SizedBox(height: 10),
              ],
              if (_errorMessage != null) ...[
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  ),
                  child: AppEmptyState(
                    icon: Icons.wifi_off_outlined,
                    title: t.loginActionFailedTitle,
                    description: t.loginActionFailedDescription(
                      _errorMessage ?? '',
                    ),
                    ctaLabel: _lastAction == null ? null : t.retry,
                    onCta: _lastAction == null ? null : _retryLastAction,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              const BrandMascot(size: 56),
              const SizedBox(height: 10),
              Text(
                t.appName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
                  signupIntent: widget.initialSignup,
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

              // ── Biyometrik giriş ───────────────────────────────────────────
              if (_biometricAvailable && _biometricEnabled && _hasStoredSession) ...[
                const _Divider(label: 'veya'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _signInWithBiometric,
                  icon: const Icon(Icons.fingerprint_rounded, size: 22),
                  label: const Text(
                    'Biyometrik ile giriş yap',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // ── Sosyal giriş butonları (email modunda göster) ──────────────
              if (_mode == _AuthMode.email) ...[
                const _Divider(label: 'veya'),
                const SizedBox(height: 16),
                _SocialButton(
                  icon: _GoogleIcon(),
                  label: 'Google ile devam et',
                  loading: _loading,
                  onTap: _signInWithGoogle,
                ),
                const SizedBox(height: 10),
                _SocialButton(
                  icon: const _AppleIcon(),
                  label: 'Apple ile devam et',
                  loading: _loading,
                  onTap: _signInWithApple,
                  dark: true,
                ),
              ],
            ],
          ), // ListView
        ],
      ), // Stack
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

// ── Şifre güç yardımcıları ────────────────────────────────────────────────────

class _PassKriter {
  const _PassKriter(this.label, this.test);
  final String label;
  final bool Function(String) test;
}

const _passKriterler = [
  _PassKriter('En az 8 karakter',  _len8),
  _PassKriter('Büyük harf',        _buyuk),
  _PassKriter('Küçük harf',        _kucuk),
  _PassKriter('Rakam',             _rakam),
  _PassKriter('Özel karakter',     _ozel),
];

bool _len8(String p)  => p.length >= 8;
bool _buyuk(String p) => RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(p);
bool _kucuk(String p) => RegExp(r'[a-zçğışöü]').hasMatch(p);
bool _rakam(String p) => RegExp(r'[0-9]').hasMatch(p);
bool _ozel(String p)  => RegExp(r'[^a-zA-Z0-9çğışöüÇĞİÖŞÜ]').hasMatch(p);

int _passGucSeviye(String p) {
  final met = _passKriterler.where((k) => k.test(p)).length;
  if (met <= 2) return 0;
  if (met == 3) return 1;
  if (met == 4) return 2;
  return 3;
}

Color _passGucRenk(int level) => switch (level) {
  0 => const Color(0xFFEF4444),
  1 => const Color(0xFFEAB308),
  2 => const Color(0xFFF97316),
  _ => const Color(0xFF22C55E),
};

String _passGucLabel(int level) => switch (level) {
  0 => 'Zayıf',
  1 => 'Orta',
  2 => 'İyi',
  _ => 'Güçlü',
};

// ── Email Formu ────────────────────────────────────────────────────────────────

class _EmailForm extends StatefulWidget {
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
  State<_EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<_EmailForm> {
  bool _obscurePass = true;
  String _passText = '';

  @override
  void initState() {
    super.initState();
    widget.passCtrl.addListener(_onPassChange);
  }

  void _onPassChange() {
    if (mounted) setState(() => _passText = widget.passCtrl.text);
  }

  @override
  void dispose() {
    widget.passCtrl.removeListener(_onPassChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final strength = _passGucSeviye(_passText);
    final showStrength = widget.signupIntent && _passText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: t.loginEmailLabel,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.passCtrl,
          obscureText: _obscurePass,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => widget.onSignIn(),
          decoration: InputDecoration(
            labelText: t.loginPasswordLabel,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.muted,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
              tooltip: _obscurePass ? 'Şifreyi göster' : 'Şifreyi gizle',
            ),
          ),
        ),
        // Şifre güç göstergesi (sadece kayıt modunda)
        if (showStrength) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (strength + 1) / 5,
                    minHeight: 5,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(_passGucRenk(strength)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _passGucLabel(strength),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _passGucRenk(strength),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _passKriterler.map((k) {
              final ok = k.test(_passText);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 13,
                    color: ok ? const Color(0xFF22C55E) : AppColors.muted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    k.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: ok ? const Color(0xFF22C55E) : AppColors.muted,
                      fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
        ],
        const SizedBox(height: 14),
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
                value: widget.acceptedPolicies,
                disabled: widget.loading,
                helperText: 'Bu kabul yalnızca kayıt oluştururken zorunludur.',
                onChanged: widget.onAcceptPolicies,
                onOpenLink: widget.onOpenLegalUrl,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.signupIntent) ...[
          FilledButton(
            onPressed: widget.loading ? null : widget.onSignUp,
            child: Text(widget.loading ? t.loginSigningUpAction : t.loginSignupAction),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: widget.loading ? null : widget.onSignIn,
            child: Text(
              widget.loading ? t.loginSigningInAction : t.loginPrimaryAction,
            ),
          ),
        ] else ...[
          FilledButton(
            onPressed: widget.loading ? null : widget.onSignIn,
            child: Text(
              widget.loading ? t.loginSigningInAction : t.loginPrimaryAction,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: widget.loading ? null : widget.onSignUp,
            child: Text(widget.loading ? t.loginSigningUpAction : t.loginSignupAction),
          ),
        ],
        const SizedBox(height: 4),
        TextButton(
          onPressed: widget.loading ? null : widget.onForgotPassword,
          child: const Text('Şifremi unuttum'),
        ),
      ],
    );
  }
}

// ── Telefon OTP Formu ──────────────────────────────────────────────────────────

class _PhoneForm extends StatefulWidget {
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
  State<_PhoneForm> createState() => _PhoneFormState();
}

class _PhoneFormState extends State<_PhoneForm> {
  int _countdown = 0;
  Timer? _timer;

  @override
  void didUpdateWidget(_PhoneForm old) {
    super.didUpdateWidget(old);
    // OTP gönderildi → geri sayımı başlat
    if (widget.otpSent && !old.otpSent) {
      _startCountdown();
    }
    // Farklı numara kullan → sayacı sıfırla
    if (!widget.otpSent && old.otpSent) {
      _stopCountdown();
    }
  }

  void _startCountdown() {
    _stopCountdown();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_countdown <= 1) {
        _stopCountdown();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() => _countdown = 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.otpSent) {
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
            controller: widget.phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
            ],
            onSubmitted: (_) => widget.onSendOtp(),
            decoration: const InputDecoration(
              labelText: 'Telefon numarası',
              hintText: '05XX XXX XX XX',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'Türkiye: 0 ile başlayan 11 haneli numara',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.loading ? null : widget.onSendOtp,
            icon: widget.loading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(widget.loading ? 'Gönderiliyor…' : 'SMS Kodu Gönder'),
          ),
        ],
      );
    }

    // OTP girişi
    final canResend = _countdown == 0 && !widget.loading;
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
              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.phoneCtrl.text} numarasına SMS gönderildi.',
                  style: const TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: widget.otpCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => widget.onVerifyOtp(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 12),
          decoration: const InputDecoration(
            labelText: 'Doğrulama kodu',
            hintText: '000000',
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.loading ? null : widget.onVerifyOtp,
          icon: widget.loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.verified_outlined, size: 18),
          label: Text(widget.loading ? 'Doğrulanıyor…' : 'Kodu Doğrula'),
        ),
        const SizedBox(height: 8),
        // Tekrar gönder butonu + geri sayım
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: canResend ? () { widget.onSendOtp(); _startCountdown(); } : null,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                _countdown > 0
                    ? 'Tekrar gönder (${_countdown}s)'
                    : 'Tekrar gönder',
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: widget.loading ? null : widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Farklı numara'),
            ),
          ],
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
    this.dark = false,
  });

  final Widget icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton(
      onPressed: loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const FaIcon(
      FontAwesomeIcons.apple,
      size: 20,
      color: Colors.white,
    );
  }
}
