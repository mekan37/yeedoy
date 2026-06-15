import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import 'app_image_cache_manager.dart';

enum AppImageVariant { thumb, medium, original }

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.variant = AppImageVariant.thumb,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
  });

  final String url;
  final AppImageVariant variant;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final (resolved, diskWidth) = switch (variant) {
      AppImageVariant.thumb => (_buildOptimizedUrl(url, width: 320, quality: 80), 320),
      AppImageVariant.medium => (_buildOptimizedUrl(url, width: 900, quality: 80), 900),
      AppImageVariant.original => (_buildOptimizedUrl(url), null),
    };

    Widget child = CachedNetworkImage(
      imageUrl: resolved,
      cacheManager: AppImageCacheManager.instance,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: diskWidth,
      maxWidthDiskCache: diskWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, _) => _ImageSkeleton(url: resolved),
      errorWidget: (context, url, error) =>
          _LowResFallback(url: _lowResCandidate(resolved), fit: fit),
    );

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

/// Returns an optimized Supabase render URL for a square avatar at [size]×[size] px.
String buildAvatarUrl(String url, {int size = 128}) =>
    _buildOptimizedUrl(url, width: size, height: size, quality: 80);

Future<void> precacheImageUrls(
  BuildContext context,
  List<String> urls, {
  AppImageVariant variant = AppImageVariant.thumb,
  int take = 5,
}) async {
  final futures = <Future<void>>[];
  for (final raw in urls.take(take)) {
    final url = raw.trim();
    if (url.isEmpty) continue;
    final optimized = switch (variant) {
      AppImageVariant.thumb => _buildOptimizedUrl(url, width: 320, quality: 80),
      AppImageVariant.medium => _buildOptimizedUrl(url, width: 900, quality: 80),
      AppImageVariant.original => _buildOptimizedUrl(url),
    };
    final provider = CachedNetworkImageProvider(
      optimized,
      cacheManager: AppImageCacheManager.instance,
    );
    futures.add(precacheImage(provider, context));
  }
  await Future.wait(futures);
}

/// Returns the original Supabase object URL unchanged (the project's
/// `/storage/v1/render/image/public/...` transform endpoint returns 403 —
/// image transformations are not enabled on this project's plan, so we
/// serve `/storage/v1/object/public/...` directly). [width]/[height]/[quality]
/// are still used by callers to drive `memCacheWidth`/`maxWidthDiskCache`
/// for client-side downsampling via `CachedNetworkImage`.
/// For other CDNs (cdn/imgix/cloudinary) adds format=webp only.
String _buildOptimizedUrl(String url, {int? width, int? height, int quality = 80}) {
  final value = url.trim();
  if (value.isEmpty) return value;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasAuthority) return value;

  final host = uri.host.toLowerCase();
  final path = uri.path;

  if (host.contains('supabase.co') &&
      path.contains('/storage/v1/object/public/')) {
    return value;
  }

  if (host.contains('cdn') ||
      host.contains('imgix') ||
      host.contains('cloudinary')) {
    final params = Map<String, String>.from(uri.queryParameters);
    params.putIfAbsent('format', () => 'webp');
    return uri.replace(queryParameters: params).toString();
  }

  return value;
}

String _lowResCandidate(String url) =>
    _buildOptimizedUrl(url, width: 240, quality: 50);

class _LowResFallback extends StatelessWidget {
  const _LowResFallback({required this.url, required this.fit});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return Container(
        color: AppColors.card,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppImageCacheManager.instance,
      fit: fit,
      memCacheWidth: 240,
      maxWidthDiskCache: 240,
      placeholder: (context, _) => _ImageSkeleton(url: url),
      errorWidget: (context, urlValue, error) => Container(
        color: AppColors.card,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
      ),
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final base = _dominantColor(url);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: 0.10), base),
            Color.alphaBlend(Colors.black.withValues(alpha: 0.08), base),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: const SizedBox.expand(),
            ),
          ),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }
}

Color _dominantColor(String seed) {
  final hash = seed.hashCode;
  final hue = (hash % 360).toDouble().abs();
  return HSVColor.fromAHSV(1, hue, 0.25, 0.35).toColor();
}
