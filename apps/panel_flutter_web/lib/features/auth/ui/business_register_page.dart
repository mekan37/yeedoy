import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../data/auth_service_provider.dart';

class BusinessRegisterPage extends ConsumerStatefulWidget {
  const BusinessRegisterPage({super.key});

  @override
  ConsumerState<BusinessRegisterPage> createState() =>
      _BusinessRegisterPageState();
}

class _BusinessRegisterPageState extends ConsumerState<BusinessRegisterPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordRepeatCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _ok;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordRepeatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _ok = null;
    });
    try {
      final pass = _passwordCtrl.text;
      if (pass.length < 6) {
        setState(() {
          _error = 'Sifre en az 6 karakter olmali.';
        });
        return;
      }
      if (pass != _passwordRepeatCtrl.text) {
        setState(() {
          _error = 'Sifreler ayni degil.';
        });
        return;
      }
      await ref
          .read(authServiceProvider)
          .signUpWithEmail(_emailCtrl.text.trim(), pass);
      if (!mounted) return;
      setState(() {
        _ok =
            'Kayit olusturuldu. Dogrulama adimini tamamladiktan sonra isletme girisi yapabilirsin.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppErrorMapper.message(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isletme Kaydi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.all(20),
            shrinkWrap: true,
            children: [
              const Text(
                'Isletme paneline erismek icin kayit olustur.',
                style: TextStyle(color: Color(0xFF334155)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Sifre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordRepeatCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Sifre (tekrar)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              if (_ok != null) ...[
                const SizedBox(height: 12),
                Text(_ok!, style: const TextStyle(color: Color(0xFF166534))),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? 'Kayit olusturuluyor...' : 'Kayit Ol'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _loading ? null : () => context.go('/isletme-giris'),
                child: const Text('Isletme Girisine Don'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
