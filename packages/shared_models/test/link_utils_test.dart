import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy_shared_models/yeedoy_shared_models.dart';

void main() {
  group('normalizeUrl', () {
    test('adds https scheme when missing', () {
      final uri = normalizeUrl('youtube.com/watch?v=abc123');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
    });

    test('downgrades http to https', () {
      final uri = normalizeUrl('http://youtube.com/watch?v=abc123');
      expect(uri!.scheme, 'https');
    });

    test('strips leading www.', () {
      final uri = normalizeUrl('https://www.instagram.com/p/xyz');
      expect(uri!.host, 'instagram.com');
    });

    test('strips utm_ and known tracking query params', () {
      final uri = normalizeUrl(
        'https://youtube.com/watch?v=abc&utm_source=ig&fbclid=123&gclid=456',
      );
      expect(uri!.queryParameters, {'v': 'abc'});
    });

    test('strips url fragment', () {
      final uri = normalizeUrl('https://youtube.com/watch?v=abc#t=30s');
      expect(uri!.fragment, isEmpty);
    });

    test('returns null for empty input', () {
      expect(normalizeUrl(''), isNull);
      expect(normalizeUrl('   '), isNull);
    });

    test('returns null for non-http(s) schemes', () {
      expect(normalizeUrl('ftp://example.com/file'), isNull);
    });

    test('returns null when there is no host at all', () {
      expect(normalizeUrl('https:///no-host'), isNull);
    });
  });

  group('detectProvider', () {
    test('detects youtube.com and youtu.be', () {
      expect(
        detectProvider(Uri.parse('https://youtube.com/watch?v=abc')),
        LinkProvider.youtube,
      );
      expect(
        detectProvider(Uri.parse('https://youtu.be/abc')),
        LinkProvider.youtube,
      );
      expect(
        detectProvider(Uri.parse('https://m.youtube.com/watch?v=abc')),
        LinkProvider.youtube,
      );
    });

    test('detects instagram.com', () {
      expect(
        detectProvider(Uri.parse('https://instagram.com/p/xyz')),
        LinkProvider.instagram,
      );
      expect(
        detectProvider(Uri.parse('https://instagram.com/reel/xyz')),
        LinkProvider.instagram,
      );
    });

    test('detects facebook.com and fb.watch', () {
      expect(
        detectProvider(Uri.parse('https://facebook.com/video/123')),
        LinkProvider.facebook,
      );
      expect(
        detectProvider(Uri.parse('https://fb.watch/abc')),
        LinkProvider.facebook,
      );
    });

    test('returns unknown for unrecognized hosts', () {
      expect(
        detectProvider(Uri.parse('https://example.com/page')),
        LinkProvider.unknown,
      );
    });
  });

  group('getEmbedDecision', () {
    test('extracts youtube video id from v= query param', () {
      final decision = getEmbedDecision(
        Uri.parse('https://youtube.com/watch?v=dQw4w9WgXcQ'),
      );
      expect(decision.provider, LinkProvider.youtube);
      expect(
        decision.embedUrl,
        Uri.parse('https://www.youtube.com/embed/dQw4w9WgXcQ'),
      );
    });

    test('extracts youtube video id from youtu.be short link', () {
      final decision = getEmbedDecision(Uri.parse('https://youtu.be/abc123'));
      expect(
        decision.embedUrl,
        Uri.parse('https://www.youtube.com/embed/abc123'),
      );
    });

    test('extracts youtube video id from /shorts/ path', () {
      final decision = getEmbedDecision(
        Uri.parse('https://youtube.com/shorts/abc123'),
      );
      expect(
        decision.embedUrl,
        Uri.parse('https://www.youtube.com/embed/abc123'),
      );
    });

    test('falls back to unknown when youtube video id is missing', () {
      final decision = getEmbedDecision(Uri.parse('https://youtube.com/'));
      expect(decision.provider, LinkProvider.unknown);
      expect(decision.embedUrl, isNull);
    });

    test('builds instagram embed url by appending /embed', () {
      final decision = getEmbedDecision(
        Uri.parse('https://instagram.com/p/xyz'),
      );
      expect(decision.provider, LinkProvider.instagram);
      expect(decision.embedUrl.toString(), 'https://www.instagram.com/p/xyz/embed');
    });

    test('builds facebook embed url via plugins/video.php', () {
      final normalized = Uri.parse('https://facebook.com/video/123');
      final decision = getEmbedDecision(normalized);
      expect(decision.provider, LinkProvider.facebook);
      expect(decision.embedUrl!.host, 'www.facebook.com');
      expect(decision.embedUrl!.queryParameters['href'], normalized.toString());
    });

    test('unknown provider has no embed url, only fallback', () {
      final normalized = Uri.parse('https://example.com/page');
      final decision = getEmbedDecision(normalized);
      expect(decision.provider, LinkProvider.unknown);
      expect(decision.embedUrl, isNull);
      expect(decision.fallbackUrl, normalized);
    });
  });
}
