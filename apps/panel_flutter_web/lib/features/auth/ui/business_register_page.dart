import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../legal/legal_routes.dart';
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
  bool _acceptedBusinessTerms = false;
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
    final t = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
      _ok = null;
    });
    try {
      final pass = _passwordCtrl.text;
      if (pass.length < 6) {
        setState(() {
          _error = t.businessRegisterPasswordMinError;
        });
        return;
      }
      if (pass != _passwordRepeatCtrl.text) {
        setState(() {
          _error = t.businessRegisterPasswordMismatchError;
        });
        return;
      }
      if (!_acceptedBusinessTerms) {
        setState(() {
          _error = 'Devam etmek için İşletme Kullanım Koşulları’nı kabul edin.';
        });
        return;
      }
      await ref
          .read(authServiceProvider)
          .signUpWithEmail(_emailCtrl.text.trim(), pass);
      if (!mounted) return;
      setState(() {
        _ok = t.businessRegisterSuccess;
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
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.businessRegisterTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.all(20),
            shrinkWrap: true,
            children: [
              Text(
                t.businessRegisterIntro,
                style: TextStyle(color: Color(0xFF334155)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: t.businessAuthEmailLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t.businessAuthPasswordLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordRepeatCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t.businessAuthPasswordRepeatLabel,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _acceptedBusinessTerms,
                      onChanged: _loading
                          ? null
                          : (value) {
                              setState(() {
                                _acceptedBusinessTerms = value ?? false;
                              });
                            },
                      title: const Text(
                        'İşletme Kullanım Koşulları’nı kabul ediyorum.',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loading
                          ? null
                          : () => context.go(
                              LegalRoutes.detail(LegalRoutes.businessSlug),
                            ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('İşletme koşullarını görüntüle'),
                    ),
                  ],
                ),
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
                child: Text(
                  _loading ? t.businessRegisterSubmitting : t.register,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _loading ? null : () => context.go('/isletme-giris'),
                child: Text(t.businessRegisterBackToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
