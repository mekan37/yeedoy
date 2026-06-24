import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/route_sanitizer.dart';
import '../../legal/legal_linking.dart';
import '../data/auth_service_provider.dart';
import 'widgets/auth_segmented_tab_bar.dart';
import 'widgets/auth_shell_scaffold.dart';

enum _AuthAction { signIn, googleSignIn }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _loading = false;
  bool _passVisible = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _navigateAfterLogin() {
    if (!mounted) return;
    final rawRedirect = GoRouterState.of(
      context,
    ).uri.queryParameters['redirect'];
    final target = sanitizeInternalRedirect(rawRedirect) ?? '/discover';
    context.go(target);
  }

  // ── Auth actions ─────────────────────────────────────────────────────────────

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

  // ── State helpers ────────────────────────────────────────────────────────────

  void _setLoading(_AuthAction action) {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
  }

  void _clearLoading() {
    if (mounted) setState(() => _loading = false);
  }

  void _setError(Object e) {
    if (!mounted) return;
    final t = context.l10n;
    final msg = e.toString().toLowerCase();
    String localized;
    if (msg.contains('email not confirmed')) {
      localized = t.authErrorEmailNotConfirmed;
    } else if (msg.contains('invalid login') ||
        msg.contains('invalid_credentials') ||
        msg.contains('credentials')) {
      localized = t.authErrorInvalidCredentials;
    } else if (msg.contains('too many requests') || msg.contains('rate')) {
      localized = t.authErrorTooManyRequests;
    } else if (msg.contains('user not found') || msg.contains('no user')) {
      localized = t.authErrorUserNotFound;
    } else if (e.toString().contains('AuthException') ||
        e.toString().contains('AuthApiException')) {
      localized = t.authErrorGeneric;
    } else {
      localized = AppErrorMapper.message(e);
    }
    setState(() => _errorMessage = localized);
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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AuthShellScaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: AuthSegmentedTabBar(selectedTab: AuthSegmentedTab.login),
            ),

            // ── Scrollable body ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),

                    // Error banner
                    if (_errorMessage != null) ...[
                      _ErrorBanner(
                        message: _errorMessage!,
                        onDismiss: () => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email field
                    _AuthTextField(
                      controller: _emailCtrl,
                      hint: 'E-posta adresiniz',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    // Password field
                    _AuthTextField(
                      controller: _passCtrl,
                      hint: 'Şifreniz',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_passVisible,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _signIn(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.muted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _passVisible = !_passVisible),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Beni hatırla + Şifremi unuttum
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Beni hatırla',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textStrong,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: GestureDetector(
                            onTap: () => context.push('/forgot-password'),
                            child: const Text(
                              'Şifremi unuttum?',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Primary action button
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _loading ? null : _signIn,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Giriş Yap',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // "veya" divider
                    const _OrDivider(),
                    const SizedBox(height: 20),

                    // Social buttons row
                    Row(
                      children: [
                        Expanded(
                          child: _SocialIconButton(
                            icon: _GoogleIcon(),
                            label: 'Google ile\ngiriş yap',
                            onTap: _loading ? null : _signInWithGoogle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SocialIconButton(
                            icon: const Icon(
                              Icons.apple_rounded,
                              size: 26,
                              color: Colors.black,
                            ),
                            label: 'Apple ile\ngiriş yap',
                            onTap: null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SocialIconButton(
                            icon: const _FacebookIcon(),
                            label: 'Facebook ile\ngiriş yap',
                            onTap: null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Feature highlights
                    Row(
                      children: [
                        Expanded(
                          child: _FeatureChip(
                            icon: Icons.shield_outlined,
                            lines: ['Güvenli', 've Korunaklı'],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FeatureChip(
                            icon: Icons.card_giftcard_outlined,
                            lines: ['Sana Özel', 'Fırsatlar'],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FeatureChip(
                            icon: Icons.notifications_outlined,
                            lines: ['Anlık Bildirim', 've Güncellemeler'],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Legal footer
                    _LegalFooter(onOpenUrl: _openLegalUrl),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Auth text field ───────────────────────────────────────────────────────────

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              obscureText: obscureText,
              onSubmitted: onSubmitted,
              style: const TextStyle(fontSize: 14, color: AppColors.textStrong),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffixIcon != null) ...[suffixIcon!, const SizedBox(width: 4)],
        ],
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.danger,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ── "veya" divider ────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'veya',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

// ── Social icon button ────────────────────────────────────────────────────────

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feature chip ──────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.lines});
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Text(
              line,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Legal footer ──────────────────────────────────────────────────────────────

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.onOpenUrl});
  final Future<void> Function(String) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.muted,
          height: 1.6,
        ),
        children: [
          const TextSpan(text: 'Devam ederek '),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => onOpenUrl('https://yeedoy.com/legal/terms'),
              child: const Text(
                'Kullanım Şartları',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const TextSpan(text: '\'nı yeri '),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => onOpenUrl('https://yeedoy.com/legal/privacy'),
              child: const Text(
                'Gizlilik Politikası',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const TextSpan(text: '\'nı kabul etmiş olursunuz.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ── Google "G" icon ───────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  static const double size = 26;

  @override
  Widget build(BuildContext context) {
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
    _arc(canvas, cx, cy, r, -30, 120, const Color(0xFFEA4335));
    _arc(canvas, cx, cy, r, 90, 60, const Color(0xFFFBBC05));
    _arc(canvas, cx, cy, r, 150, 90, const Color(0xFF34A853));
    _arc(canvas, cx, cy, r, 240, 90, const Color(0xFF4285F4));
  }

  void _arc(
    Canvas c,
    double cx,
    double cy,
    double r,
    double startDeg,
    double sweepDeg,
    Color color,
  ) {
    const d2r = 3.14159265 / 180.0;
    c.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      startDeg * d2r,
      sweepDeg * d2r,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.28,
    );
  }

  @override
  bool shouldRepaint(_GoogleGPainter _) => false;
}

// ── Facebook icon ─────────────────────────────────────────────────────────────

class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();
  static const double size = 26;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ── Phone OTP form (push route veya dialog) ───────────────────────────────────
// (Phone OTP flow kept available via _sendOtp/_verifyOtp, not exposed in new UI)

// ignore: unused_element
class _PhoneOtpForm extends StatelessWidget {
  const _PhoneOtpForm({
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
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
            ],
            onSubmitted: (_) => onSendOtp(),
            decoration: const InputDecoration(
              labelText: 'Telefon numarası',
              hintText: '05XX XXX XX XX',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading ? null : onSendOtp,
            child: Text(loading ? 'Gönderiliyor…' : 'SMS Kodu Gönder'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => onVerifyOtp(),
          decoration: const InputDecoration(
            labelText: 'Doğrulama kodu',
            hintText: '000000',
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: loading ? null : onVerifyOtp,
          child: Text(loading ? 'Doğrulanıyor…' : 'Kodu Doğrula'),
        ),
        TextButton(
          onPressed: loading ? null : onBack,
          child: const Text('Farklı numara kullan'),
        ),
      ],
    );
  }
}
