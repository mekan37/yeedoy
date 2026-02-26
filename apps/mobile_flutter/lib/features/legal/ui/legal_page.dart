import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/product_guardrail_overrides.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/shared/ui/components/app_card.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/components/app_section_header.dart';

class LegalPage extends ConsumerWidget {
  const LegalPage({super.key});

  static const _supportEmail = 'support@yeedoy.com';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final guardrails = ref.watch(productGuardrailOverridesProvider);
    return AppScaffold(
      appBar: AppBar(
        title: Text(
          t.legalPageTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AppSectionHeader(title: t.legalKvkkSectionTitle),
          const SizedBox(height: 6),
          Text(
            t.legalKvkkIntro,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.legalKvkkCategoriesAndRights,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(AppConfig.privacyPolicyUrl),
                      icon: const Icon(Icons.shield_outlined),
                      label: Text(t.legalPrivacyPolicy),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(AppConfig.kvkkUrl),
                      icon: const Icon(Icons.gavel_outlined),
                      label: Text(t.legalKvkkText),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(AppConfig.gdprUrl),
                      icon: const Icon(Icons.public_outlined),
                      label: Text(t.legalGdprText),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t.legalApplicationByEmail,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppSectionHeader(title: t.legalCopyrightSectionTitle),
          const SizedBox(height: 6),
          Text(
            t.legalCopyrightIntro,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.legalCopyrightDetails,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _openUrl(AppConfig.copyrightPolicyUrl),
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(t.legalCopyrightPolicy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppSectionHeader(title: t.legalOwnershipAppealSectionTitle),
          const SizedBox(height: 6),
          Text(
            t.legalOwnershipAppealIntro,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.legalOwnershipAppealRequiredInfo,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  t.legalOwnershipAppealRequiredList,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _sendMail(_supportEmail),
                  icon: const Icon(Icons.mail_outline),
                  label: Text(t.legalSendAppealEmail),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppSectionHeader(title: t.legalProductPrinciplesSectionTitle),
          const SizedBox(height: 6),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.legalDontsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  t.legalDontsList,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  t.legalPolicySummary(
                    guardrails.requireSponsoredLabel,
                    guardrails.minSponsoredTrustScore.toStringAsFixed(2),
                    guardrails.ownerCanDeleteReviews,
                  ),
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            t.legalFooter,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Future<void> _sendMail(String email) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {'subject': 'Yeedoy - Sahiplik İtirazı'},
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

