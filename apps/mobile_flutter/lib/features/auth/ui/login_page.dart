import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/brand/brand_widgets.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import '../data/auth_service_provider.dart';

enum _AuthAction { signIn, signUp }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;
  String? errorMessage;
  _AuthAction? lastAction;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      loading = true;
      errorMessage = null;
      lastAction = _AuthAction.signIn;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmail(emailCtrl.text.trim(), passCtrl.text);
      if (!mounted) return;

      final redirect = GoRouterState.of(
        context,
      ).uri.queryParameters['redirect'];
      final target =
          (redirect != null && redirect.isNotEmpty && redirect != '/login')
          ? Uri.decodeComponent(redirect)
          : '/discover';
      context.go(target);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = AppErrorMapper.message(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    setState(() {
      loading = true;
      errorMessage = null;
      lastAction = _AuthAction.signUp;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signUpWithEmail(emailCtrl.text.trim(), passCtrl.text);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loginSignupSuccessMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = AppErrorMapper.message(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _retryLastAction() async {
    switch (lastAction) {
      case _AuthAction.signIn:
        await _signIn();
      case _AuthAction.signUp:
        await _signUp();
      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppScaffold(
      appBar: AppBar(title: Text(t.loginPageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (loading) ...[
            const AppSkeletonLine(width: double.infinity),
            const SizedBox(height: 10),
          ],
          if (errorMessage != null) ...[
            AppEmptyState(
              icon: Icons.wifi_off_outlined,
              title: t.loginActionFailedTitle,
              description: t.loginActionFailedDescription(errorMessage ?? ''),
              ctaLabel: lastAction == null ? null : t.retry,
              onCta: lastAction == null ? null : _retryLastAction,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          const BrandMascot(size: 56),
          const SizedBox(height: 10),
          Text(
            t.appName,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: t.loginEmailLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: InputDecoration(labelText: t.loginPasswordLabel),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading ? null : _signIn,
              child: Text(
                loading ? t.loginSigningInAction : t.loginPrimaryAction,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: loading ? null : _signUp,
              child: Text(
                loading ? t.loginSigningUpAction : t.loginSignupAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

