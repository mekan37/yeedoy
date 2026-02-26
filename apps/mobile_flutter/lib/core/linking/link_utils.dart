import 'link_provider.dart';

const Set<String> _trackingParamKeys = {
  'fbclid',
  'gclid',
  'igshid',
};

Uri? normalizeUrl(String input) {
  final raw = input.trim();
  if (raw.isEmpty) return null;

  final withScheme = raw.contains('://') ? raw : 'https://$raw';
  final parsed = Uri.tryParse(withScheme);
  if (parsed == null || parsed.host.trim().isEmpty) return null;

  final scheme = parsed.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;

  var host = parsed.host.toLowerCase();
  if (host.startsWith('www.')) {
    host = host.substring(4);
  }

  final filteredQuery = <String, String>{
    for (final entry in parsed.queryParameters.entries)
      if (!_isTrackingParam(entry.key)) entry.key: entry.value,
  };

  return parsed.replace(
    scheme: 'https',
    host: host,
    queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    fragment: '',
  );
}

LinkProvider detectProvider(Uri uri) {
  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments.map((s) => s.toLowerCase()).toList();

  if (host == 'youtube.com' ||
      host == 'm.youtube.com' ||
      host == 'youtu.be') {
    return LinkProvider.youtube;
  }

  if (host == 'instagram.com' || host == 'm.instagram.com') {
    if (segments.any((s) => s == 'reel' || s == 'reels' || s == 'p' || s == 'tv')) {
      return LinkProvider.instagram;
    }
    return LinkProvider.instagram;
  }

  if (host == 'facebook.com' || host == 'm.facebook.com' || host == 'fb.watch') {
    return LinkProvider.facebook;
  }

  return LinkProvider.unknown;
}

EmbedDecision getEmbedDecision(Uri normalized) {
  final provider = detectProvider(normalized);

  switch (provider) {
    case LinkProvider.youtube:
      final videoId = _extractYoutubeVideoId(normalized);
      if (videoId != null && videoId.isNotEmpty) {
        return EmbedDecision(
          provider: provider,
          normalizedUri: normalized,
          embedUrl: Uri.parse('https://www.youtube.com/embed/$videoId'),
          fallbackUrl: normalized,
        );
      }
      return EmbedDecision(
        provider: LinkProvider.unknown,
        normalizedUri: normalized,
        fallbackUrl: normalized,
      );
    case LinkProvider.instagram:
      final embed = _instagramEmbedUrl(normalized);
      return EmbedDecision(
        provider: provider,
        normalizedUri: normalized,
        embedUrl: embed,
        fallbackUrl: normalized,
      );
    case LinkProvider.facebook:
      final embed = Uri.https('www.facebook.com', '/plugins/video.php', {
        'href': normalized.toString(),
      });
      return EmbedDecision(
        provider: provider,
        normalizedUri: normalized,
        embedUrl: embed,
        fallbackUrl: normalized,
      );
    case LinkProvider.unknown:
      return EmbedDecision(
        provider: provider,
        normalizedUri: normalized,
        fallbackUrl: normalized,
      );
  }
}

bool _isTrackingParam(String key) {
  final k = key.toLowerCase();
  return k.startsWith('utm_') || _trackingParamKeys.contains(k);
}

String? _extractYoutubeVideoId(Uri uri) {
  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments;

  if (host == 'youtu.be' && segments.isNotEmpty) {
    return segments.first;
  }

  final v = uri.queryParameters['v'];
  if (v != null && v.isNotEmpty) return v;

  if (segments.length >= 2 &&
      (segments.first == 'embed' || segments.first == 'shorts')) {
    return segments[1];
  }

  return null;
}

Uri _instagramEmbedUrl(Uri normalized) {
  final cleanedSegments = normalized.pathSegments
      .where((s) => s.isNotEmpty && s.toLowerCase() != 'embed')
      .toList();

  final path = '/${cleanedSegments.join('/')}/embed';
  return Uri.https('www.instagram.com', path);
}
