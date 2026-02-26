import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/config/dev_overrides.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/config/product_guardrail_overrides.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../../../features/auth/domain/auth_providers.dart';
import '../../../ui/design_system.dart';

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
    final userId = _achievementUserIdCtrl.text.trim();
    final achievementId = _achievementIdCtrl.text.trim();
    final reason = _achievementReasonCtrl.text.trim();

    if (userId.isEmpty || achievementId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı ID ve Başarı ID zorunlu.')),
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
        ).showSnackBar(SnackBar(content: Text('Reset başarısız: $error')));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleted
                ? 'Başarı resetlendi ve denetim kayda yazıldı.'
                : 'Kayıt bulunmadı ama denetim kayda yazıldı.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
            const AppSectionHeader(title: 'Geliştirici Araçları'),
            const SizedBox(height: 6),
            const Text(
              'Özellik, test kullanıcı ve test şehir ayarları.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Başarı Moderasyonu',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gerekirse başarı kaydını sil ve profile XP/leveli yeniden hesapla.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _achievementUserIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı ID (uuid)',
                      hintText: 'yazar kullanıcı id',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _achievementIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Başarı ID',
                      hintText: 'ornek: trusted_contributor',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _achievementReasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Neden (opsiyonel)',
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
                          ? 'Resetleniyor...'
                          : 'Başarı Reset',
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
                  const Text(
                    'Korkuluk Eşikleri',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Canlı kalite eşiklerini admin panelinden ayarla.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sponsor etiketi zorunlu'),
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
                    title: const Text('İşletme yorum silebilir'),
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
                    title: const Text('Düşük kalite büyüme bypass'),
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
                          decoration: const InputDecoration(
                            labelText: 'Min sponsor trust (0-1)',
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
                          decoration: const InputDecoration(
                            labelText: 'Min sponsor rating (0-5)',
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
                              const SnackBar(
                                content: Text('Geçerli eşik değerleri gir.'),
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
                        child: const Text('Eşikleri Kaydet'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(productGuardrailOverridesProvider.notifier)
                            .resetDefaults(),
                        child: const Text('Varsayılan'),
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
                  const Text(
                    'Özellik Bayrakları',
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
                  const Text(
                    'Test kullanıcı',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aktif kullanıcı: ${user?.id ?? '-'}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Test kullanıcı UID',
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
                        child: const Text('Kaydet'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(devOverridesProvider.notifier)
                            .setTestUserId(null),
                        child: const Text('Temizle'),
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
                  const Text(
                    'Test Şehir',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Konum geçersiz bırakıldığında otomatik konum akışı devre dışı kalır.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(labelText: 'Şehir'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _districtCtrl,
                          decoration: const InputDecoration(labelText: 'İlçe'),
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
                        child: const Text('Kaydet'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(devOverridesProvider.notifier)
                            .clearTestLocation(),
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                  if (overrides.hasTestLocation) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Aktif: ${overrides.testCity} / ${overrides.testDistrict}',
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

