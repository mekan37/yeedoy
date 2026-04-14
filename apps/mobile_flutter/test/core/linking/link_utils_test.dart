import 'package:flutter_test/flutter_test.dart';

import 'package:yeedoy/core/linking/link_utils.dart';

void main() {
  group('link_utils', () {
    test('normalizeUrl removes tracking params and keeps https host', () {
      final uri = normalizeUrl(
        'https://www.youtube.com/watch?v=abc123&utm_source=x&fbclid=y',
      );
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'youtube.com');
      expect(uri.queryParameters.containsKey('utm_source'), isFalse);
      expect(uri.queryParameters.containsKey('fbclid'), isFalse);
      expect(uri.queryParameters['v'], 'abc123');
    });

    test('getEmbedDecision returns youtube embed url', () {
      final normalized = normalizeUrl('https://youtu.be/abc123');
      expect(normalized, isNotNull);
      final decision = getEmbedDecision(normalized!);

      expect(decision.provider, LinkProvider.youtube);
      expect(decision.embedUrl, isNotNull);
      expect(decision.embedUrl.toString(), contains('/embed/abc123'));
    });

    test('getEmbedDecision returns instagram embed url', () {
      final normalized = normalizeUrl(
        'instagram.com/reel/xyz987/?utm_source=x',
      );
      expect(normalized, isNotNull);
      final decision = getEmbedDecision(normalized!);

      expect(decision.provider, LinkProvider.instagram);
      expect(decision.embedUrl, isNotNull);
      expect(decision.embedUrl!.host, 'www.instagram.com');
      expect(decision.embedUrl!.path, '/reel/xyz987/embed');
    });

    test('getEmbedDecision returns facebook plugin embed url', () {
      final normalized = normalizeUrl('https://facebook.com/watch/?v=12345');
      expect(normalized, isNotNull);
      final decision = getEmbedDecision(normalized!);

      expect(decision.provider, LinkProvider.facebook);
      expect(decision.embedUrl, isNotNull);
      expect(decision.embedUrl!.host, 'www.facebook.com');
      expect(decision.embedUrl!.path, '/plugins/video.php');
      expect(
        decision.embedUrl!.queryParameters['href'],
        decision.normalizedUri.toString(),
      );
    });

    test('getEmbedDecision keeps unknown provider without embed url', () {
      final normalized = normalizeUrl('https://example.com/some/page');
      expect(normalized, isNotNull);
      final decision = getEmbedDecision(normalized!);

      expect(decision.provider, LinkProvider.unknown);
      expect(decision.embedUrl, isNull);
      expect(decision.fallbackUrl, decision.normalizedUri);
    });
  });
}
