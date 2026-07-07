import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/business_badges_repository.dart';
import '../../domain/business_badge.dart';

/// Shareable PNG certificate showing a business's achievement badges.
class BusinessBadgeCertificate extends ConsumerWidget {
  const BusinessBadgeCertificate({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(businessBadgesProvider(businessId));

    return badgesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (badges) {
        if (badges.isEmpty) return const SizedBox.shrink();
        return _CertificateView(
          businessId: businessId,
          businessName: businessName,
          badges: badges,
        );
      },
    );
  }
}

class _CertificateView extends StatefulWidget {
  const _CertificateView({
    required this.businessId,
    required this.businessName,
    required this.badges,
  });

  final String businessId;
  final String businessName;
  final List<BusinessBadge> badges;

  @override
  State<_CertificateView> createState() => _CertificateViewState();
}

class _CertificateViewState extends State<_CertificateView> {
  final _repaintKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/yeedoy_badge_certificate.png');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${widget.businessName} — Yeedoy Başarım Sertifikası 🏆',
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _repaintKey,
          child: _CertificateCard(
            businessName: widget.businessName,
            badges: widget.badges,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _sharing ? null : _share,
          icon: _sharing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share),
          label: Text(_sharing ? 'Paylaşılıyor...' : 'Sertifikayı Paylaş'),
        ),
      ],
    );
  }
}

/// The visual certificate card.
///
/// NOTE: TextStyle sizes here are intentionally hardcoded (not AppTypography).
/// This widget is captured as a PNG at 3× pixel ratio — it must render at fixed
/// physical sizes regardless of the device's accessibility font scale.
class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.businessName,
    required this.badges,
  });

  final String businessName;
  final List<BusinessBadge> badges;

  Color _tierColor(String tier) {
    switch (tier) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFE8E8E8);
      case 'special':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7F1D1D), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'YEEDOY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7F1D1D),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Başarım Sertifikası',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            businessName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: badges.map((b) {
              final color = _tierColor(b.tier);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 1),
                ),
                child: Text(
                  b.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color == const Color(0xFFE8E8E8)
                        ? const Color(0xFF6B7280)
                        : color,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            DateTime.now().year.toString(),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
