import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../owner_dashboard/domain/owner_moat_provider.dart';
import '../data/owner_menu_repository.dart';
import '../domain/owner_menu_models.dart';
import 'menu_editor_pdf_flow.dart' deferred as pdf_flow;
import 'menu_editor_qr_flow.dart' deferred as qr_flow;
import 'owner_menu_error_mapper.dart';

class MenuEditorShareSheet extends ConsumerStatefulWidget {
  const MenuEditorShareSheet({
    super.key,
    required this.menu,
  });

  final OwnerMenu menu;

  @override
  ConsumerState<MenuEditorShareSheet> createState() =>
      _MenuEditorShareSheetState();
}

class _MenuEditorShareSheetState extends ConsumerState<MenuEditorShareSheet> {
  late final Future<void> _qrFlowFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _qrFlowFuture = qr_flow.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    final link = _buildShareLink(widget.menu.id);
    final qrLink = _withSrc(link, 'qr');
    final ownerDashboardLink = AppConfig.ownerDashboardWebUrl(
      businessId: widget.menu.businessId,
    );
    final repo = ref.read(ownerMenuRepositoryProvider);
    final moatAsync = ref.watch(
      ownerMoatSummaryProvider(widget.menu.businessId),
    );

    return FutureBuilder<Map<String, dynamic>>(
      future: repo.fetchPublicMenuShare(menuId: widget.menu.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const OwnerPanelFeedback.loading(cardCount: 2);
        }
        if (snap.hasError) {
          return OwnerPanelFeedback.error(
            title: context.l10n.ownerSharePanel,
            description: AppErrorMapper.message(snap.error),
          );
        }

        final data = snap.data ?? const {};
        final business = data['business'] as Map?;
        final menu = data['menu'] as Map?;
        final businessName = (business?['name'] ?? '').toString().trim();
        final safeName = businessName.isEmpty ? widget.menu.title : businessName;
        final openNow = _readBool(
          menu,
          business,
          keys: const ['open_now', 'is_open_now', 'isOpenNow'],
        );
        final nearbyViews = _readInt(
          menu,
          business,
          keys: const [
            'nearby_views',
            'nearby_view_count',
            'nearby_menu_views',
            'menu_views_48h',
            'view_count_48h',
          ],
        );

        return ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          children: [
            Text(
              context.l10n.ownerSharePanel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(safeName, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: link),
              decoration: InputDecoration(
                labelText: context.l10n.ownerMenuLink,
                suffixIcon: IconButton(
                  onPressed: () => _copyText(link),
                  icon: const Icon(Icons.copy),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<void>(
              future: _qrFlowFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 220,
                    child: OwnerPanelFeedback.loading(cardCount: 1),
                  );
                }
                if (snapshot.hasError) {
                  return OwnerPanelFeedback.error(
                    title: context.l10n.ownerSharePanel,
                    description: snapshot.error.toString(),
                  );
                }
                return Center(
                  child: qr_flow.MenuEditorQrPreview(data: qrLink),
                );
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _runDeferredTask(() async {
                          await _qrFlowFuture;
                          await qr_flow.exportMenuQrPng(
                            data: qrLink,
                            businessName: safeName,
                          );
                        }),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(context.l10n.ownerQrPng),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _runDeferredTask(() async {
                          await pdf_flow.loadLibrary();
                          await pdf_flow.exportMenuQrPdf(
                            qrData: qrLink,
                            businessName: safeName,
                            isA6: false,
                          );
                        }),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(context.l10n.ownerQrPdf),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _runDeferredTask(() async {
                          await pdf_flow.loadLibrary();
                          await pdf_flow.exportMenuQrPdf(
                            qrData: qrLink,
                            businessName: safeName,
                            isA6: true,
                          );
                        }),
                  icon: const Icon(Icons.qr_code_2_outlined),
                  label: Text(context.l10n.ownerA6Pdf),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.ownerFieldGainCardTitle,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.ownerFieldGainCardLine1,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.ownerFieldGainCardLine2,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  _CopyRow(
                    label: context.l10n.ownerCopyMiniDashboard,
                    text: ownerDashboardLink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: moatAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 6),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (moat) {
                    if (moat == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.ownerMoatTitle,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.ownerMoatSummary(
                            moat.businessTrustScore,
                            moat.menuFreshnessScore,
                            moat.priceAccuracyScore,
                          ),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.ownerMoatSignal(
                            moat.uniqueValidators,
                            (moat.evidenceRate * 100).round(),
                            moat.menuViewsToday,
                          ),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _CopyRow(
                          label: context.l10n.ownerCopyMoatText,
                          text: _moatPitchText(
                            link,
                            businessName: safeName,
                            moat: moat,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ShareSectionLabel(
              icon: FontAwesomeIcons.whatsapp,
              text: context.l10n.ownerWhatsappText,
            ),
            const SizedBox(height: 6),
            _CopyRow(
              label: context.l10n.ownerCopyWhatsapp,
              text: _whatsAppText(
                link,
                businessName: safeName,
                openNow: openNow,
                nearbyViews: nearbyViews,
              ),
            ),
            const SizedBox(height: 12),
            _ShareSectionLabel(
              icon: FontAwesomeIcons.xTwitter,
              text: context.l10n.ownerXText,
            ),
            const SizedBox(height: 6),
            _CopyRow(
              label: context.l10n.ownerCopyX,
              text: _twitterText(
                link,
                businessName: safeName,
                openNow: openNow,
                nearbyViews: nearbyViews,
              ),
            ),
            const SizedBox(height: 12),
            _ShareSectionLabel(
              icon: FontAwesomeIcons.instagram,
              text: context.l10n.ownerInstagramBio,
            ),
            const SizedBox(height: 6),
            _CopyRow(
              label: context.l10n.ownerCopyInstagram,
              text: _instagramText(
                link,
                businessName: safeName,
                openNow: openNow,
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Future<void> _runDeferredTask(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Dialog(
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: OwnerPanelFeedback.loading(cardCount: 1),
            ),
          ),
        );
      },
    );

    try {
      await task();
    } catch (error) {
      if (!mounted) return;
      final message = ownerMenuErrorMessage(
        context.l10n,
        error,
        fallback: AppErrorMapper.message(error),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.ownerCopied)));
  }

  String _whatsAppText(
    String link, {
    required String businessName,
    bool? openNow,
    int? nearbyViews,
  }) {
    final lines = <String>[
      businessName,
      if (openNow == true) context.l10n.openNow,
      if (nearbyViews != null && nearbyViews > 0)
        context.l10n.ownerNearbyViewed(nearbyViews),
      context.l10n.ownerCurrentMenuVerifiedPrices,
      link,
    ];
    return lines.join('\n');
  }

  String _twitterText(
    String link, {
    required String businessName,
    bool? openNow,
    int? nearbyViews,
  }) {
    final lines = <String>[
      businessName,
      if (openNow == true) context.l10n.openNow,
      if (nearbyViews != null && nearbyViews > 0)
        context.l10n.ownerViewed(nearbyViews),
      context.l10n.ownerCurrentMenuVerifiedPricesColon,
      link,
    ];
    return lines.join('\n');
  }

  String _instagramText(
    String link, {
    required String businessName,
    bool? openNow,
  }) {
    final lines = <String>[
      businessName,
      if (openNow == true) context.l10n.openNow,
      context.l10n.ownerCurrentMenuVerifiedPrices,
      link,
    ];
    return lines.join('\n');
  }

  String _moatPitchText(
    String link, {
    required String businessName,
    required OwnerMoatSummary moat,
  }) {
    final evidencePct = (moat.evidenceRate * 100).round();
    return context.l10n.ownerMoatPitchText(
      businessName,
      moat.businessTrustScore,
      moat.menuFreshnessScore,
      moat.priceAccuracyScore,
      moat.uniqueValidators,
      evidencePct,
      moat.menuViewsToday,
      link,
    );
  }
}

String _buildShareLink(String menuId) {
  if (kIsWeb) {
    final origin = Uri.base.origin;
    final base = origin.isEmpty ? AppConfig.webBaseUrl : origin;
    return '$base/menu/$menuId';
  }
  return AppConfig.menuWebUrl(menuId);
}

String _withSrc(String link, String src) {
  final uri = Uri.parse(link);
  final qp = Map<String, String>.from(uri.queryParameters);
  qp['src'] = src;
  return uri.replace(queryParameters: qp).toString();
}

bool _readBool(Map? menu, Map? business, {required List<String> keys}) {
  for (final key in keys) {
    final mv = menu?[key];
    if (mv is bool) return mv;
    final bv = business?[key];
    if (bv is bool) return bv;
  }
  return false;
}

int? _readInt(Map? menu, Map? business, {required List<String> keys}) {
  for (final key in keys) {
    final mv = menu?[key];
    if (mv is num) return mv.toInt();
    final bv = business?[key];
    if (bv is num) return bv.toInt();
  }
  return null;
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text)),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: text)),
          child: Text(label),
        ),
      ],
    );
  }
}

class _ShareSectionLabel extends StatelessWidget {
  const _ShareSectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
