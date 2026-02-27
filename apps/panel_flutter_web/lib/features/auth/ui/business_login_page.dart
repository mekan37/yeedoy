import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/security/app_role_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/business_auth_redirect.dart';
import '../data/auth_service_provider.dart';

class BusinessLoginPage extends ConsumerStatefulWidget {
  const BusinessLoginPage({super.key});

  @override
  ConsumerState<BusinessLoginPage> createState() => _BusinessLoginPageState();
}

class _BusinessLoginPageState extends ConsumerState<BusinessLoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      final role = await ref.refresh(appRoleProvider.future);
      if (!mounted) return;

      switch (role) {
        case AppRole.admin:
        case AppRole.communityMod:
        case AppRole.owner:
          context.go(
            resolveBusinessPostLoginPath(
              role: role,
              encodedRedirect:
                  GoRouterState.of(context).uri.queryParameters['redirect'],
            ),
          );
          return;
        case AppRole.user:
          setState(() {
            _error = t.businessLoginNoPermissionError;
          });
          return;
      }
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
      appBar: AppBar(title: Text(t.businessLoginTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.all(20),
            shrinkWrap: true,
            children: [
              Text(
                t.businessLoginIntro,
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
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? t.businessLoginSubmitting : t.login),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _loading ? null : () => context.go('/isletme-kayit'),
                child: Text(t.businessLoginGoRegister),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
