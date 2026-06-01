import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/colors.dart';
import '../data/consent_provider.dart';
import '../domain/consent_state.dart';

/// KVKK onay alt sayfasını gösterir.
///
/// Kullanıcı karar vermeden sayfayı kapatamaz (isDismissible: false).
Future<void> showConsentBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _ConsentSheet(),
  );
}

class _ConsentSheet extends ConsumerStatefulWidget {
  const _ConsentSheet();

  @override
  ConsumerState<_ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends ConsumerState<_ConsentSheet> {
  bool _analyticsEnabled = true;
  bool _marketingEnabled = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(consentNotifierProvider);
    if (saved.analytics != ConsentStatus.unknown) {
      _analyticsEnabled = saved.analytics == ConsentStatus.granted;
    }
    if (saved.marketing != ConsentStatus.unknown) {
      _marketingEnabled = saved.marketing == ConsentStatus.granted;
    }
  }

  Future<void> _acceptAll() async {
    await ref.read(consentNotifierProvider.notifier).grantAll();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _acceptSelected() async {
    await ref.read(consentNotifierProvider.notifier).update(
          analytics: _analyticsEnabled
              ? ConsentStatus.granted
              : ConsentStatus.denied,
          marketing: _marketingEnabled
              ? ConsentStatus.granted
              : ConsentStatus.denied,
          dataRetention: ConsentStatus.granted,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('yeedoy://yasal');
    if (!await launchUrl(uri)) {
      // Fallback: web URL
      await launchUrl(
        Uri.parse('https://yeedoy.com/yasal'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: tokens.space16,
        right: tokens.space16,
        top: tokens.space20,
        bottom: tokens.space24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(tokens.radius12),
              ),
            ),
          ),
          SizedBox(height: tokens.space16),

          // ── Başlık ────────────────────────────────────────────────────
          Text(
            'Veri Kullanım Tercihleri',
            style: context.sectionTitleStyle,
          ),
          SizedBox(height: tokens.space8),

          // ── Açıklama ──────────────────────────────────────────────────
          Text(
            'Yeedoy deneyimini iyileştirmek için bazı verilerini kullanmak '
            'istiyoruz. KVKK kapsamında seçimlerini değiştirebilirsin.',
            style: context.subtitleStyle,
          ),
          SizedBox(height: tokens.space16),

          // ── Toggle: Kullanım Analitiği ─────────────────────────────────
          _ConsentToggle(
            title: 'Kullanım Analitiği',
            subtitle: 'Uygulama performansını ve kullanım kalıplarını '
                'anlamamıza yardımcı olur.',
            value: _analyticsEnabled,
            onChanged: (v) => setState(() => _analyticsEnabled = v),
          ),
          SizedBox(height: tokens.space4),

          // ── Toggle: Kampanya Bildirimleri ─────────────────────────────
          _ConsentToggle(
            title: 'Kampanya Bildirimleri',
            subtitle: 'Sana özel teklifler ve restoran kampanyaları '
                'hakkında bildirim gönderilsin.',
            value: _marketingEnabled,
            onChanged: (v) => setState(() => _marketingEnabled = v),
          ),
          SizedBox(height: tokens.space20),

          // ── Butonlar ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _acceptAll,
              child: const Text('Tümünü Kabul Et'),
            ),
          ),
          SizedBox(height: tokens.space8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _acceptSelected,
              child: const Text('Sadece Zorunlu'),
            ),
          ),
          SizedBox(height: tokens.space12),

          // ── Gizlilik Politikası bağlantısı ────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _openPrivacyPolicy,
              child: Text(
                'Gizlilik Politikası →',
                style: context.captionStyle.copyWith(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentToggle extends StatelessWidget {
  const _ConsentToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: tokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                ),
                SizedBox(height: tokens.space4),
                Text(subtitle, style: context.captionStyle),
              ],
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
        ),
      ],
    );
  }
}
