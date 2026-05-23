import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../shared/ui/bilesenler/uygulama_iskele.dart';
import '../yasal_katalog.dart';
import '../yasal_baglanti.dart';
import '../yasal_modeller.dart';
import '../yasal_saglayicilari.dart';
import '../yasal_deposu.dart';
import 'yardimci_bilesenler/yasal_gerekli_onay_karti.dart';

class LegalAcceptancePage extends ConsumerStatefulWidget {
  const LegalAcceptancePage({super.key, this.fromPath});

  final String? fromPath;

  @override
  ConsumerState<LegalAcceptancePage> createState() =>
      _LegalAcceptancePageState();
}

class _LegalAcceptancePageState extends ConsumerState<LegalAcceptancePage> {
  bool _acceptedRequiredPolicies = false;
  bool _marketingOptIn = false;
  bool _analyticsOptIn = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(legalAcceptanceSnapshotProvider);
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Yasal Kabul'),
      ),
      body: snapshotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppErrorMapper.message(error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(legalAcceptanceSnapshotProvider),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (snapshot) {
          if (snapshot == null || !snapshot.requiresMandatoryAcceptance) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.go(widget.fromPath ?? '/discover');
            });
            return const Center(child: CircularProgressIndicator());
          }

          final pendingVersions = snapshot.pendingRequiredVersions;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Devam etmek için güncel sözleşmeleri onaylayın.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Yeedoy, kullanım şartları ve gizlilik politikası sürümlerini kullanıcı bazında kaydeder. Yeni sürüm yayınlandığında uygulamaya devam etmeden önce tekrar onay istenir.',
                      style: TextStyle(color: AppColors.muted, height: 1.6),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetaChip(label: '${pendingVersions.length} zorunlu sürüm'),
                        const _MetaChip(label: 'Kaynak: yeedoy.com/legal'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (final version in pendingVersions) ...[
                      _VersionTile(version: version),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: LegalRequiredConsentCard(
                  value: _acceptedRequiredPolicies,
                  disabled: _saving,
                  includeCookiesLink: true,
                  linkStyle: LegalConsentLinkStyle.outlined,
                  helperText:
                      'Bu onay verilmeden uygulama oturumu açılmış olsa bile içerik yüzeylerine geçilmez.',
                  onChanged: (value) {
                    setState(() {
                      _acceptedRequiredPolicies = value ?? false;
                    });
                  },
                  onOpenLink: _openLegalUrl,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İsteğe bağlı tercihler',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _marketingOptIn,
                      onChanged: _saving
                          ? null
                          : (value) {
                              setState(() {
                                _marketingOptIn = value;
                              });
                            },
                      title: const Text('Kampanya ve bildirim izinleri'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _analyticsOptIn,
                      onChanged: _saving
                          ? null
                          : (value) {
                              setState(() {
                                _analyticsOptIn = value;
                              });
                            },
                      title: const Text('Ürün analitiği iyileştirme izni'),
                    ),
                    const Text(
                      'Bu tercihler zorunlu sözleşme kabulünden ayrı tutulur ve daha sonra profil ayarlarından güncellenebilir.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : () => _submit(pendingVersions),
                child: Text(
                  _saving ? 'Kaydediliyor...' : 'Kabul Et ve Devam Et',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(List<PolicyVersionRecord> versions) async {
    if (!_acceptedRequiredPolicies) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Devam etmek için gerekli sözleşmeleri kabul etmelisiniz.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(legalRepositoryProvider).acceptPolicyVersions(versions);
      ref.invalidate(legalAcceptanceSnapshotProvider);
      if (!mounted) return;
      context.go(widget.fromPath ?? '/discover');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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

class _VersionTile extends StatelessWidget {
  const _VersionTile({required this.version});

  final PolicyVersionRecord version;

  @override
  Widget build(BuildContext context) {
    final descriptor = LegalCatalog.byPolicyType(version.policyType);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            descriptor?.title ?? version.policyType,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${version.versionLabel} • ${_formatDate(version.publishedAt)}',
            style: const TextStyle(color: AppColors.muted),
          ),
          if (descriptor != null) ...[
            const SizedBox(height: 6),
            Text(
              descriptor.description,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textStrong,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  const months = <int, String>{
    1: 'Ocak',
    2: 'Şubat',
    3: 'Mart',
    4: 'Nisan',
    5: 'Mayıs',
    6: 'Haziran',
    7: 'Temmuz',
    8: 'Ağustos',
    9: 'Eylül',
    10: 'Ekim',
    11: 'Kasım',
    12: 'Aralık',
  };
  return '${value.day} ${months[value.month]} ${value.year}';
}




