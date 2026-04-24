import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/owner_business_guard.dart';
import '../../../shared/ui/components/panel_action_button.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../domain/owner_custom_domain_controller.dart';
import '../domain/owner_custom_domain_models.dart';

class OwnerCustomDomainPage extends ConsumerStatefulWidget {
  const OwnerCustomDomainPage({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<OwnerCustomDomainPage> createState() =>
      _OwnerCustomDomainPageState();
}

class _OwnerCustomDomainPageState
    extends ConsumerState<OwnerCustomDomainPage> {
  final _domainCtrl = TextEditingController();

  @override
  void dispose() {
    _domainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OwnerBusinessGuard(
      businessId: widget.businessId,
      builder: (context, ref) {
        final st = ref.watch(
            ownerCustomDomainControllerProvider(widget.businessId));
        final ctrl = ref.read(
            ownerCustomDomainControllerProvider(widget.businessId).notifier);

        // Sync text field with loaded info
        if (st.info != null && _domainCtrl.text.isEmpty) {
          _domainCtrl.text = st.info!.domain;
        }

        return Column(
          children: [
            PanelPageHeader(
              eyebrow: l10n.ownerShellPanelTitle,
              title: const Text('Özel Domain'),
              description:
                  'Menünüzü kendi alan adınızdan yayınlayın. '
                  'Örn: menu.bistrobodrum.com → yeedoy.com/m/bistrobodrum',
              actions: [
                PanelActionButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Yenile',
                  variant: PanelActionButtonVariant.neutral,
                  onPressed: ctrl.refresh,
                ),
              ],
            ),
            Expanded(
              child: st.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (st.error != null)
                          _Banner(
                            message: st.error.toString(),
                            isError: true,
                          ),
                        if (st.message != null)
                          _Banner(
                            message: st.message!,
                            isError: false,
                          ),
                        // ── Step 1: Domain input ──────────────────────────
                        _SectionCard(
                          title: 'Adım 1 — Alan Adını Gir',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Menü için kullanmak istediğiniz alt alan adını girin.',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.muted),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _domainCtrl,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Alan adı (örn. menu.bistrobodrum.com)',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  PanelActionButton(
                                    icon: Icons.save_rounded,
                                    tooltip: 'Kaydet',
                                    label: st.isSaving
                                        ? 'Kaydediliyor…'
                                        : 'Kaydet',
                                    variant: PanelActionButtonVariant.primary,
                                    onPressed: st.isSaving
                                        ? null
                                        : () => ctrl
                                            .saveDomain(_domainCtrl.text.trim()),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Step 2: DNS TXT record ────────────────────────
                        if (st.info != null) ...[
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Adım 2 — DNS TXT Kaydını Ekle',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DNS yöneticinizde (Cloudflare, GoDaddy, vs.) aşağıdaki TXT kaydını ekleyin:',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.muted),
                                ),
                                const SizedBox(height: 12),
                                _DnsTxtCard(
                                  domain: st.info!.domain,
                                  token: st.info!.dnsTxtToken,
                                ),
                              ],
                            ),
                          ),

                          // ── Step 3: Verify ────────────────────────────
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Adım 3 — Doğrula',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (st.info!.isVerified) ...[
                                  _StatusChip(
                                    label: 'Doğrulandı ✓',
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Alan adınız doğrulandı ve menünüz bu adresten yayınlanıyor.',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.muted),
                                  ),
                                ] else ...[
                                  const Text(
                                    'TXT kaydını ekledikten sonra "Doğrula" butonuna basın. '
                                    'DNS yayılması 5-30 dakika sürebilir.',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.muted),
                                  ),
                                  const SizedBox(height: 12),
                                  PanelActionButton(
                                    icon: Icons.verified_rounded,
                                    tooltip: 'DNS TXT kaydını doğrula',
                                    label: st.isVerifying
                                        ? 'Doğrulanıyor…'
                                        : 'Doğrula',
                                    variant: PanelActionButtonVariant.primary,
                                    onPressed: st.isVerifying
                                        ? null
                                        : ctrl.verifyDomain,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // ── Remove domain ─────────────────────────────
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: PanelActionButton(
                              icon: Icons.delete_outline_rounded,
                              tooltip: 'Özel domaini kaldır',
                              label: 'Özel Domaini Kaldır',
                              variant: PanelActionButtonVariant.danger,
                              onPressed: st.isSaving
                                  ? null
                                  : () => _confirmDelete(context, ctrl),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, OwnerCustomDomainController ctrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Özel Domain Kaldır'),
        content: const Text(
            'Bu işlem geri alınamaz. Alan adı doğrulaması sıfırlanacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ctrl.deleteDomain();
  }
}

// ── DNS TXT card ──────────────────────────────────────────────────────────────

class _DnsTxtCard extends StatelessWidget {
  const _DnsTxtCard({required this.domain, required this.token});
  final String domain;
  final String token;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DnsRow(label: 'Tür', value: 'TXT'),
          _DnsRow(label: 'Host', value: '@'),
          _DnsRow(label: 'TTL', value: '3600'),
          _DnsRow(label: 'Değer', value: token, canCopy: true),
        ],
      ),
    );
  }
}

class _DnsRow extends StatelessWidget {
  const _DnsRow({
    required this.label,
    required this.value,
    this.canCopy = false,
  });
  final String label;
  final String value;
  final bool canCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy_rounded,
                  size: 16, color: AppColors.muted),
              tooltip: 'Kopyala',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
              },
            ),
        ],
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
              ),
            ),
          ),
          const Divider(height: 20, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Banner ────────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.success;
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
