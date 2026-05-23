import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../uygulama/tema/renkler.dart';
import '../../../../core/ayarlar/uygulama_ayarlari.dart';
import '../../../../core/ceviri/uygulama_yerellesmeleri.dart';

// ─── Business Share ────────────────────────────────────────────────────────

Future<void> showBusinessShareCardSheet(
  BuildContext context, {
  required String businessId,
  required String businessName,
  required String category,
  String? district,
  String? city,
  double? avgRating,
  int? reviewCount,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ShareCardSheet(
      shareUrl: AppConfig.businessWebUrl(businessId),
      child: _BusinessShareCard(
        name: businessName,
        category: category,
        district: district,
        city: city,
        avgRating: avgRating,
        reviewCount: reviewCount,
      ),
    ),
  );
}

// ─── Menu Item Share ───────────────────────────────────────────────────────

Future<void> showMenuItemShareCardSheet(
  BuildContext context, {
  required String businessId,
  required String menuId,
  required String itemName,
  required String businessName,
  String? priceDisplay,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ShareCardSheet(
      shareUrl: AppConfig.businessWebUrl(businessId),
      child: _MenuItemShareCard(
        itemName: itemName,
        businessName: businessName,
        priceDisplay: priceDisplay,
      ),
    ),
  );
}

// ─── Bottom Sheet ──────────────────────────────────────────────────────────

class _ShareCardSheet extends StatefulWidget {
  const _ShareCardSheet({
    required this.child,
    required this.shareUrl,
  });

  final Widget child;
  final String shareUrl;

  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet> {
  final _cardKey = GlobalKey();
  bool _capturing = false;

  Future<void> _shareAsImage() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final tmp = Directory.systemTemp;
      final file = File('${tmp.path}/yeedoy_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: widget.shareUrl),
      );
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // fallback to link share on error
      await _shareAsLink();
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _shareAsLink() async {
    await SharePlus.instance.share(ShareParams(text: widget.shareUrl));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _cardKey,
              child: widget.child,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _capturing ? null : _shareAsImage,
                    icon: _capturing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.image_outlined, size: 18),
                    label: Text(t.shareAsImage),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareAsLink,
                    icon: const Icon(Icons.link, size: 18),
                    label: Text(t.shareLink),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Business Card Visual ──────────────────────────────────────────────────

class _BusinessShareCard extends StatelessWidget {
  const _BusinessShareCard({
    required this.name,
    required this.category,
    this.district,
    this.city,
    this.avgRating,
    this.reviewCount,
  });

  final String name;
  final String category;
  final String? district;
  final String? city;
  final double? avgRating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final location = [district, city].where((s) => s?.isNotEmpty == true).join(', ');
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              category,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: AppColors.textStrong,
            ),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ],
          if (avgRating != null && avgRating! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
                const SizedBox(width: 4),
                Text(
                  avgRating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textStrong,
                  ),
                ),
                if (reviewCount != null && reviewCount! > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '($reviewCount)',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
          _YeedoyBrandFooter(),
        ],
      ),
    );
  }
}

// ─── Menu Item Card Visual ─────────────────────────────────────────────────

class _MenuItemShareCard extends StatelessWidget {
  const _MenuItemShareCard({
    required this.itemName,
    required this.businessName,
    this.priceDisplay,
  });

  final String itemName;
  final String businessName;
  final String? priceDisplay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            itemName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            businessName,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          if (priceDisplay != null && priceDisplay!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                priceDisplay!,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _YeedoyBrandFooter(),
        ],
      ),
    );
  }
}

// ─── Brand Footer ──────────────────────────────────────────────────────────

class _YeedoyBrandFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Yeedoy',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: AppColors.primary,
          ),
        ),
        const Spacer(),
        Text(
          'yeedoy.com',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
