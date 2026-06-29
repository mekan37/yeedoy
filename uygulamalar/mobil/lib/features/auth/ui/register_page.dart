import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/security/route_sanitizer.dart';
import '../../legal/legal_linking.dart';
import '../../legal/legal_providers.dart';
import '../../legal/legal_repository.dart';
import '../data/auth_service_provider.dart';
import 'widgets/auth_segmented_tab_bar.dart';
import 'widgets/auth_shell_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();

  bool _passVisible = false;
  bool _passConfirmVisible = false;
  bool _accepted = false;
  bool _loading = false;
  String? _errorMessage;
  DateTime? _birthDate;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _signUp() async {
    if (!_accepted) {
      setState(() {
        _errorMessage =
            'Devam etmek için Kullanım Şartları ve Gizlilik Politikası\'nı kabul etmelisiniz.';
      });
      return;
    }
    if (_passCtrl.text != _passConfirmCtrl.text) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor.');
      return;
    }
    if (_passCtrl.text.length < 8) {
      setState(
        () => _errorMessage =
            'Şifreniz en az 8 karakter olmalı ve harf, rakam içermelidir.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabınız oluşturuldu! E-postanızı doğrulayın.'),
        ),
      );
      context.go('/discover');
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = AppErrorMapper.message(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      final redirect = GoRouterState.of(
        context,
      ).uri.queryParameters['redirect'];
      context.go(sanitizeInternalRedirect(redirect) ?? '/discover');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'Doğum tarihinizi seçin',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _openLegalUrl(String url) async {
    try {
      await openLegalUrl(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AuthShellScaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const AuthSegmentedTabBar(selectedTab: AuthSegmentedTab.register),
              const SizedBox(height: 24),

              // ── Başlık ───────────────────────────────────────────────
              const Text(
                'Hesap oluşturun',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hemen kaydolun, tüm özelliklerden yararlanmaya başlayın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // ── Error banner ─────────────────────────────────────────
              if (_errorMessage != null) ...[
                _ErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: 16),
              ],

              // ── Ad | Soyad ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _RegField(
                      controller: _firstNameCtrl,
                      hint: 'Ad',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RegField(
                      controller: _lastNameCtrl,
                      hint: 'Soyad',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── E-posta ──────────────────────────────────────────────
              _RegField(
                controller: _emailCtrl,
                hint: 'E-posta adresi',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // ── Telefon ──────────────────────────────────────────────
              _PhoneField(controller: _phoneCtrl),
              const SizedBox(height: 12),

              // ── Şifre ────────────────────────────────────────────────
              _RegField(
                controller: _passCtrl,
                hint: 'Şifre',
                icon: Icons.lock_outline_rounded,
                obscureText: !_passVisible,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  icon: Icon(
                    _passVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _passVisible = !_passVisible),
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Şifreniz en az 8 karakter olmalı ve harf, rakam içermelidir.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Şifre (Tekrar) ───────────────────────────────────────
              _RegField(
                controller: _passConfirmCtrl,
                hint: 'Şifre (Tekrar)',
                icon: Icons.lock_outline_rounded,
                obscureText: !_passConfirmVisible,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  icon: Icon(
                    _passConfirmVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  onPressed: () => setState(
                    () => _passConfirmVisible = !_passConfirmVisible,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Doğum tarihi ─────────────────────────────────────────
              GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _birthDate == null
                              ? 'Doğum tarihi'
                              : '${_birthDate!.day.toString().padLeft(2, '0')}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _birthDate == null
                                ? AppColors.muted
                                : AppColors.textStrong,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.muted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Yasal onay ───────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _accepted,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textStrong,
                          height: 1.5,
                        ),
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => _openLegalUrl(AppConfig.termsUrl),
                              child: const Text(
                                'Kullanım Şartları',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' ve '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () =>
                                  _openLegalUrl(AppConfig.privacyPolicyUrl),
                              child: const Text(
                                'Gizlilik Politikası',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: '\'nı okudum, kabul ediyorum.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Kayıt Ol butonu ──────────────────────────────────────
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _signUp,
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
                          'Kayıt Ol',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // ── "veya" bölücü ────────────────────────────────────────
              const _OrDivider(),
              const SizedBox(height: 20),

              // ── Sosyal butonlar ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _SocialIconButton(
                      icon: const _GoogleIcon(),
                      label: 'Google ile\nkaydol',
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
                      label: 'Apple ile\nkaydol',
                      onTap: null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SocialIconButton(
                      icon: const _FacebookIcon(),
                      label: 'Facebook ile\nkaydol',
                      onTap: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Güvenli Kayıt kartı ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Güvenli Kayıt',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.textStrong,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bilgileriniz 256-bit SSL ile korunmaktadır.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared input field ────────────────────────────────────────────────────────

class _RegField extends StatelessWidget {
  const _RegField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
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

// ── Phone field ───────────────────────────────────────────────────────────────

class _PhoneField extends StatefulWidget {
  const _PhoneField({required this.controller});
  final TextEditingController controller;

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  String _code = '+90';

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
          const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showCodePicker(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _code,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 22, color: AppColors.border),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 14, color: AppColors.textStrong),
              decoration: const InputDecoration(
                hintText: 'Telefon numarası',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCodePicker() {
    const entries = [
      ('+90', '🇹🇷 Türkiye'),
      ('+1', '🇺🇸 ABD'),
      ('+44', '🇬🇧 Birleşik Krallık'),
      ('+49', '🇩🇪 Almanya'),
      ('+33', '🇫🇷 Fransa'),
      ('+31', '🇳🇱 Hollanda'),
      ('+43', '🇦🇹 Avusturya'),
      ('+41', '🇨🇭 İsviçre'),
    ];

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ülke Kodu',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        title: Text(entry.$2),
                        trailing: Text(
                          entry.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        onTap: () {
                          setState(() => _code = entry.$1);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'veya',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
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

// ── Google icon ───────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
