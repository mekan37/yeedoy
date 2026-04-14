import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/dev_overrides.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/config/product_guardrail_overrides.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/supabase_provider.dart';
import '../../auth/domain/auth_providers.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../../shared/ui/design_system.dart';

class AdminDevToolsPage extends ConsumerStatefulWidget {
  const AdminDevToolsPage({super.key});

  @override
  ConsumerState<AdminDevToolsPage> createState() => _AdminDevToolsPageState();
}

class _AdminDevToolsPageState extends ConsumerState<AdminDevToolsPage> {
  final _userIdCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _minTrustCtrl = TextEditingController();
  final _minRatingCtrl = TextEditingController();
  final _achievementUserIdCtrl = TextEditingController();
  final _achievementIdCtrl = TextEditingController();
  final _achievementReasonCtrl = TextEditingController();
  bool _resettingAchievement = false;

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _minTrustCtrl.dispose();
    _minRatingCtrl.dispose();
    _achievementUserIdCtrl.dispose();
    _achievementIdCtrl.dispose();
    _achievementReasonCtrl.dispose();
    super.dispose();
  }

  void _syncController(TextEditingController ctrl, String nextValue) {
    if (ctrl.text == nextValue) return;
    ctrl.text = nextValue;
    ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: ctrl.text.length),
    );
  }

  Future<void> _resetAchievement(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final userId = _achievementUserIdCtrl.text.trim();
    final achievementId = _achievementIdCtrl.text.trim();
    final reason = _achievementReasonCtrl.text.trim();

    if (userId.isEmpty || achievementId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDevToolsAchievementRequired)),
      );
      return;
    }

    setState(() => _resettingAchievement = true);
    try {
      final client = ref.read(supabaseProvider);
      final res = await client.rpc(
        'admin_reset_user_achievement_v1',
        params: {
          'p_user_id': userId,
          'p_achievement_id': achievementId,
          'p_reason': reason.isEmpty ? null : reason,
        },
      );
      final map = (res is Map)
          ? res.cast<String, dynamic>()
          : const <String, dynamic>{};
      final ok = map['ok'] == true;
      final deleted = map['deleted'] == true;
      if (!context.mounted) return;
      if (!ok) {
        final error = (map['error'] ?? 'rpc_failed').toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(l10n.adminDevToolsResetFailed(error))),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleted
                ? l10n.adminDevToolsAchievementResetLogged
                : l10n.adminDevToolsNoRecordButLogged,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(l10n.adminDevToolsError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _resettingAchievement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flagsState = ref.watch(featureFlagsProvider);
    final overrides = ref.watch(devOverridesProvider);
    final guardrails = ref.watch(productGuardrailOverridesProvider);
    final user = ref.watch(userProvider);
    final l10n = context.l10n;

    _syncController(_userIdCtrl, overrides.testUserId ?? '');
    _syncController(_cityCtrl, overrides.testCity ?? '');
    _syncController(_districtCtrl, overrides.testDistrict ?? '');
    _syncController(
      _minTrustCtrl,
      guardrails.minSponsoredTrustScore.toStringAsFixed(2),
    );
    _syncController(
      _minRatingCtrl,
      guardrails.minSponsoredRating.toStringAsFixed(1),
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PanelPageHeader(
              padding: EdgeInsets.zero,
              title: Text(l10n.adminDevToolsTitle),
              description: l10n.adminDevToolsSubtitle,
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminDevToolsAchievementModerationTitle,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.adminDevToolsAchievementModerationDescription,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _achievementUserIdCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.adminDevToolsUserIdUuidLabel,
                      hintText: l10n.adminDevToolsWriterUserIdHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _achievementIdCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.adminDevToolsAchievementIdLabel,
                      hintText: l10n.adminDevToolsAchievementIdHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _achievementReasonCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.adminDevToolsReasonOptionalLabel,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _resettingAchievement
                        ? null
                        : () => _resetAchievement(context, ref),
                    icon: const Icon(Icons.restart_alt),
                    label: Text(
                      _resettingAchievement
                          ? l10n.adminDevToolsResettingAction
                          : l10n.adminDevToolsAchievementResetAction,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminDevToolsGuardrailThresholdsTitle,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.adminDevToolsGuardrailThresholdsDescription,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminDevToolsRequireSponsoredLabel),
                    value: guardrails.requireSponsoredLabel,
                    onChanged: (value) => ref
                        .read(productGuardrailOverridesProvider.notifier)
                        .save(
                          guardrails.copyWith(requireSponsoredLabel: value),
                        ),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminDevToolsOwnerCanDeleteReviews),
                    value: guardrails.ownerCanDeleteReviews,
                    onChanged: (value) => ref
                        .read(productGuardrailOverridesProvider.notifier)
                        .save(
                          guardrails.copyWith(ownerCanDeleteReviews: value),
                        ),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminDevToolsLowQualityGrowthBypass),
                    value: guardrails.allowLowQualityGrowthBypass,
                    onChanged: (value) => ref
                        .read(productGuardrailOverridesProvider.notifier)
                        .save(
                          guardrails.copyWith(
                            allowLowQualityGrowthBypass: value,
                          ),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minTrustCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.adminDevToolsMinSponsorTrustLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _minRatingCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.adminDevToolsMinSponsorRatingLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () async {
                          final trust = double.tryParse(
                            _minTrustCtrl.text.replaceAll(',', '.').trim(),
                          );
                          final rating = double.tryParse(
                            _minRatingCtrl.text.replaceAll(',', '.').trim(),
                          );
                          if (trust == null || rating == null) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.adminDevToolsEnterValidThresholds),
                              ),
                            );
                            return;
                          }
                          final next = guardrails.copyWith(
                            minSponsoredTrustScore: trust
                                .clamp(0, 1)
                                .toDouble(),
                            minSponsoredRating: rating.clamp(0, 5).toDouble(),
                          );
                          await ref
                              .read(productGuardrailOverridesProvider.notifier)
                              .save(next);
                        },
                        child: Text(l10n.adminDevToolsSaveThresholdsAction),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(productGuardrailOverridesProvider.notifier)
                            .resetDefaults(),
                        child: Text(l10n.adminDevToolsDefaultAction),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminDevToolsFeatureFlagsTitle,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  for (final def in featureFlagDefs)
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(def.label),
                      subtitle: Text(
                        def.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                      value:
                          flagsState.localFlags[def.flag] ?? def.defaultValue,
                      onChanged: (value) => ref
                          .read(featureFlagsProvider.notifier)
                          .setFlag(def.flag, value),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminDevToolsTestUserTitle,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.adminDevToolsActiveUser(user?.id ?? '-'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userIdCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.adminDevToolsTestUserUidLabel,
                      hintText: 'uuid',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () => ref
                            .read(devOverridesProvider.notifier)
                            .setTestUserId(_userIdCtrl.text),
                        child: Text(l10n.save),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(devOverridesProvider.notifier)
                            .setTestUserId(null),
                        child: Text(l10n.adminDevToolsClearAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminDevToolsTestCityTitle,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.adminDevToolsTestCityDescription,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityCtrl,
                          decoration: InputDecoration(labelText: l10n.city),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _districtCtrl,
                          decoration: InputDecoration(labelText: l10n.district),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () => ref
                            .read(devOverridesProvider.notifier)
                            .setTestLocation(
                              city: _cityCtrl.text,
                              district: _districtCtrl.text,
                            ),
                        child: Text(l10n.save),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(devOverridesProvider.notifier)
                            .clearTestLocation(),
                        child: Text(l10n.adminDevToolsClearAction),
                      ),
                    ],
                  ),
                  if (overrides.hasTestLocation) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.adminDevToolsActiveLocation(
                        overrides.testCity ?? '-',
                        overrides.testDistrict ?? '-',
                      ),
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

