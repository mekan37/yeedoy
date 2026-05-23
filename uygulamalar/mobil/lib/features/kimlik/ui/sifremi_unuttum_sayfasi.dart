import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../features/shared/ui/bilesenler/uygulama_iskele.dart';
import '../data/kimlik_servisi_saglayicisi.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Geçerli bir e-posta adresi girin.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Şifre Sıfırla')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _sent ? _SuccessView(email: _emailCtrl.text.trim()) : _FormView(
          emailCtrl: _emailCtrl,
          loading: _loading,
          error: _error,
          onSend: _send,
          onBack: () => context.pop(),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.emailCtrl,
    required this.loading,
    required this.error,
    required this.onSend,
    required this.onBack,
  });

  final TextEditingController emailCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_outlined, size: 48, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          'Şifrenizi sıfırlamak için\ne-posta adresinizi girin',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Size sıfırlama bağlantısı içeren bir e-posta göndereceğiz.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
            ),
            child: Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSend(),
          decoration: const InputDecoration(
            labelText: 'E-posta adresi',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: loading ? null : onSend,
          icon: loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_outlined, size: 18),
          label: Text(loading ? 'Gönderiliyor…' : 'Sıfırlama Linki Gönder'),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: onBack, child: const Text('Geri dön')),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.success),
        const SizedBox(height: 16),
        const Text(
          'E-posta Gönderildi!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '$email adresine şifre sıfırlama bağlantısı gönderildi.\nLütfen gelen kutunuzu kontrol edin.',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go('/login'),
          child: const Text('Giriş sayfasına dön'),
        ),
      ],
    );
  }
}



