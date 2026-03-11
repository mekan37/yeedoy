import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/brand/brand_widgets.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../legal/legal_linking.dart';
import '../../legal/legal_providers.dart';
import '../../legal/legal_repository.dart';
import '../../legal/ui/widgets/legal_required_consent_card.dart';
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
  bool acceptedRequiredPolicies = false;
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

    if (!acceptedRequiredPolicies) {
      setState(() {
        loading = false;
        errorMessage =
            'Kayıt olmadan önce Kullanım Şartları ve Gizlilik Politikası’nı kabul etmelisiniz.';
      });
      return;
    }

    try {
      final response = await ref
          .read(authServiceProvider)
          .signUpWithEmail(emailCtrl.text.trim(), passCtrl.text);
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
          Text(t.appName, style: TextStyle(fontWeight: FontWeight.w600)),
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
                const Text(
                  'Kayıt işlemi sürüm bazlı olarak saklanır. Yeni bir kullanım şartı veya gizlilik sürümü yayınlanırsa uygulama yeniden onay ister.',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                LegalRequiredConsentCard(
                  value: acceptedRequiredPolicies,
                  disabled: loading,
                  helperText:
                      'Bu kabul yalnızca kayıt oluştururken zorunludur. Giriş yapan kullanıcılar için gerekli kontroller oturum sonrası ayrıca yapılır.',
                  onChanged: (value) {
                    setState(() {
                      acceptedRequiredPolicies = value ?? false;
                    });
                  },
                  onOpenLink: _openLegalUrl,
                ),
              ],
            ),
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

  Future<void> _openLegalUrl(String url) async {
    try {
      await openLegalUrl(url);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(error))),
      );
    }
  }
}
