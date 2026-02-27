import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/security/app_role_providers.dart';
import '../../owner_businesses/domain/owner_business_state.dart';
import '../domain/owner_kpi_provider.dart';
import '../domain/owner_moat_provider.dart';
import '../domain/owner_quality_score_provider.dart';
import '../../owner_monetization/data/owner_monetization_repository.dart';
import '../../../shared/ui/components/app_card.dart';
import '../../../shared/ui/components/app_section_header.dart';

class OwnerDashboardPage extends ConsumerStatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  ConsumerState<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends ConsumerState<OwnerDashboardPage> {
  final _phoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _impressionsCtrl = TextEditingController();
  var _surface = 'discovery';
  bool _submitting = false;
  Object? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _categoryCtrl.dispose();
    _budgetCtrl.dispose();
    _impressionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessId = ref.watch(selectedOwnerBusinessIdProvider);
    if (businessId != null && businessId.isNotEmpty) {
      final canManageAsync = ref.watch(canManageBusinessProvider(businessId));
      final canManage = canManageAsync.when<bool?>(
        loading: () => null,
        error: (_, _) => false,
        data: (value) => value,
      );
      if (canManage == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!canManage) {
        return const Center(child: Text('Bu iÃ…Å¸letme iÃƒÂ§in yetkiniz yok.'));
      }
    }
    final scoreAsync = ref.watch(ownerQualityScoreProvider(businessId));
    final kpiAsync = ref.watch(ownerKpiSummaryProvider(businessId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionHeader(title: 'Genel bakÃ„Â±Ã…Å¸'),
        const SizedBox(height: 12),
        AppCard(
          child: kpiAsync.when(
            loading: () => const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KPI yÃƒÂ¼kleniyor...',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(minHeight: 8),
              ],
            ),
            error: (e, _) => Text(
              e.toString(),
              style: const TextStyle(color: AppColors.danger),
            ),
            data: (kpi) {
              if (businessId == null || businessId.isEmpty) {
                return const Text(
                  'KPI iÃƒÂ§in ÃƒÂ¶nce bir iÃ…Å¸letme seÃƒÂ§.',
                  style: TextStyle(color: AppColors.muted),
                );
              }
              if (kpi == null) {
                return const Text(
                  'KPI bulunamadÃ„Â±.',
                  style: TextStyle(color: AppColors.muted),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KPI (30 gÃƒÂ¼n)',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _OwnerStatCard(
                        title: 'GÃƒÂ¶rÃƒÂ¼ntÃƒÂ¼lenme',
                        value: '${kpi.businessViews}',
                      ),
                      _OwnerStatCard(
                        title: 'TÃ„Â±klama',
                        value: '${kpi.outboundClicks}',
                      ),
                      _OwnerStatCard(
                        title: 'Yol tarifi',
                        value: '${kpi.directionsClicks}',
                      ),
                      _OwnerStatCard(
                        title: 'Arama gÃƒÂ¶sterimi',
                        value: '${kpi.searchImpressions}',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: scoreAsync.when(
            loading: () => const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kalite skoru yÃƒÂ¼kleniyor...',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(minHeight: 8),
              ],
            ),
            error: (e, _) => Text(
              e.toString(),
              style: const TextStyle(color: AppColors.danger),
            ),
            data: (quality) {
              if (businessId == null || businessId.isEmpty) {
                return const Text(
                  'Skor iÃƒÂ§in ÃƒÂ¶nce bir iÃ…Å¸letme seÃƒÂ§.',
                  style: TextStyle(color: AppColors.muted),
                );
              }
              if (quality == null) {
                return const Text(
                  'Skor bulunamadÃ„Â±.',
                  style: TextStyle(color: AppColors.muted),
                );
              }

              final progress = (quality.score / 100).clamp(0, 1).toDouble();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MenÃƒÂ¼ kalite skoru: ${quality.score}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    quality.score >= 80
                        ? 'Skor iyi seviyede.'
                        : 'Hedef 80+: aÃ…Å¸aÃ„Å¸Ã„Â±daki gÃƒÂ¶revleri tamamla.',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  if (quality.tips.isEmpty)
                    const Text('Ã…Âu an iÃƒÂ§in ek gÃƒÂ¶rev yok.')
                  else
                    ...quality.tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _OwnerMoatCard(businessId: businessId),
        const SizedBox(height: 12),
        _buildProCard(context, businessId),
      ],
    );
  }

  Widget _buildProCard(BuildContext context, String? businessId) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yeedoy Pro',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Yeedoy Pro: kampanya ve gÃƒÂ¶rÃƒÂ¼nÃƒÂ¼rlÃƒÂ¼k araÃƒÂ§larÃ„Â±.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          _featureRow('Sponsorlu etiket (Ã…Å¸effaf gÃƒÂ¶sterim)'),
          _featureRow('GeliÃ…Å¸miÃ…Å¸ analiz ve dÃƒÂ¶nÃƒÂ¼Ã…Å¸ÃƒÂ¼m metrikleri'),
          _featureRow('Kampanya / duyuru alanlarÃ„Â±'),
          _featureRow('Ãƒâ€“ne ÃƒÂ§Ã„Â±kan alan (etiketli ve ÃƒÂ¶lÃƒÂ§ÃƒÂ¼mlÃƒÂ¼)'),
          _featureRow('Ãƒâ€¡ok Ã…Å¸ube tek panel yÃƒÂ¶netimi'),
          const SizedBox(height: 12),
          const Text(
            'Sponsorlu alanlar organik kalite sirasini bozmaz.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_surface),
            initialValue: _surface,
            items: const [
              DropdownMenuItem(value: 'discovery', child: Text('KeÃ…Å¸fet')),
              DropdownMenuItem(
                value: 'business_page',
                child: Text('Ã„Â°Ã…Å¸letme sayfasÃ„Â±'),
              ),
            ],
            onChanged: (v) => setState(() => _surface = v ?? 'discovery'),
            decoration: const InputDecoration(labelText: 'Tercih edilen alan'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cityCtrl,
            decoration: const InputDecoration(
              labelText: 'Hedef Ã…Å¸ehirler (virgÃƒÂ¼lle)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _districtCtrl,
            decoration: const InputDecoration(
              labelText: 'Hedef ilÃƒÂ§eler (virgÃƒÂ¼lle)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(
              labelText: 'Hedef kategoriler (virgulle)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'AylÃ„Â±k bÃƒÂ¼tÃƒÂ§e (opsiyonel)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _impressionsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'AylÃ„Â±k gÃƒÂ¶sterim hedefi (opsiyonel)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Telefon (opsiyonel)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Not (opsiyonel)',
              hintText: 'Hedef bÃƒÂ¶lge veya kampanya notu...',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error.toString(),
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting
                  ? null
                  : () => _submitProLead(context, businessId),
              child: Text(
                _submitting ? 'GÃƒÂ¶nderiliyor...' : 'Pro talebi gÃƒÂ¶nder',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _submitProLead(BuildContext context, String? businessId) async {
    if (businessId == null || businessId.isEmpty) {
      setState(() => _error = 'Ãƒâ€“nce bir iÃ…Å¸letme seÃƒÂ§melisin.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(ownerMonetizationRepositoryProvider);
      final targeting = <String, dynamic>{};
      final cities = _parseList(_cityCtrl.text);
      if (cities.isNotEmpty) targeting['city'] = cities;
      final districts = _parseList(_districtCtrl.text);
      if (districts.isNotEmpty) targeting['district'] = districts;
      final categories = _parseList(_categoryCtrl.text);
      if (categories.isNotEmpty) targeting['category'] = categories;
      final budget = _parseInt(_budgetCtrl.text);
      if (budget != null) targeting['monthly_budget'] = budget;
      final impressions = _parseInt(_impressionsCtrl.text);
      if (impressions != null) targeting['monthly_impressions'] = impressions;
      await repo.submitSponsorshipLead(
        businessId: businessId,
        phone: _phoneCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        preferredSurface: _surface,
        preferredTargeting: targeting,
      );
      if (!context.mounted) return;
      _phoneCtrl.clear();
      _messageCtrl.clear();
      _cityCtrl.clear();
      _districtCtrl.clear();
      _categoryCtrl.clear();
      _budgetCtrl.clear();
      _impressionsCtrl.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Talebini aldÃ„Â±k.')));
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<String> _parseList(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  int? _parseInt(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
}

class _OwnerStatCard extends StatelessWidget {
  const _OwnerStatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _OwnerMoatCard extends ConsumerWidget {
  const _OwnerMoatCard({required this.businessId});

  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moatAsync = ref.watch(ownerMoatSummaryProvider(businessId));
    return AppCard(
      child: moatAsync.when(
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Savunma duvarÃ„Â± yÃƒÂ¼kleniyor...',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 10),
            LinearProgressIndicator(minHeight: 8),
          ],
        ),
        error: (e, _) =>
            Text(e.toString(), style: const TextStyle(color: AppColors.danger)),
        data: (moat) {
          if (businessId == null || businessId!.isEmpty) {
            return const Text(
              'SkorlarÃ„Â± gÃƒÂ¶rmek iÃƒÂ§in ÃƒÂ¶nce bir iÃ…Å¸letme seÃƒÂ§.',
              style: TextStyle(color: AppColors.muted),
            );
          }
          if (moat == null) {
            return const Text(
              'Skor verisi bulunamadÃ„Â±.',
              style: TextStyle(color: AppColors.muted),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uzun Vadeli Savunma Duvari',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bu skorlar arama sÃ„Â±ralamasÃ„Â±, ÃƒÂ¶ne ÃƒÂ§Ã„Â±karma ve sponsor filtrelerinde kullanÃ„Â±lÃ„Â±r.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _OwnerStatCard(
                    title: 'Ã„Â°Ã…Å¸letme gÃƒÂ¼veni',
                    value: '${moat.businessTrustScore}',
                  ),
                  _OwnerStatCard(
                    title: 'MenÃƒÂ¼ gÃƒÂ¼ncellik',
                    value: '${moat.menuFreshnessScore}',
                  ),
                  _OwnerStatCard(
                    title: 'Fiyat doÃ„Å¸ruluk',
                    value: '${moat.priceAccuracyScore}',
                  ),
                  _OwnerStatCard(
                    title: 'KatkÃ„Â± gÃƒÂ¼ven',
                    value: '${moat.contributionTrustScore}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Sinyaller: ${moat.uniqueValidators} farklÃ„Â± doÃ„Å¸rulayÃ„Â±cÃ„Â±'
                '${moat.lastPriceVerificationAt != null ? ' - son doÃ„Å¸rulama ${_fmtDateTime(moat.lastPriceVerificationAt!)}' : ''}',
                style: const TextStyle(color: AppColors.textStrong),
              ),
              const SizedBox(height: 4),
              Text(
                'KanÃ„Â±t oranÃ„Â±: %${(moat.evidenceRate * 100).round()} - GeÃƒÂ§miÃ…Å¸ katkÃ„Â± kalitesi: %${(moat.contributionQualityRate * 100).round()}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                moat.districtRank == null
                    ? 'Yerel mikro veri: bugÃƒÂ¼n menÃƒÂ¼ bakma ${moat.menuViewsToday}'
                    : 'Yerel mikro veri: bugÃƒÂ¼n menÃƒÂ¼ bakma ${moat.menuViewsToday} - ilÃƒÂ§e sÃ„Â±rasÃ„Â± #${moat.districtRank}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _fmtDateTime(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

