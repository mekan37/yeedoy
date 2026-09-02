import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/content/content_moderation.dart';

void main() {
  group('blacklistMatches', () {
    test('detects a blacklisted term regardless of case and spacing', () {
      expect(blacklistMatches('Bu bir SIKTIR yorumu', ['siktir']), isTrue);
      expect(blacklistMatches('bu s i k t i r yorumu', ['siktir']), isTrue);
    });

    test('does not flag clean text', () {
      expect(
        blacklistMatches('gayet güzel bir mekan', ['siktir', 'amk']),
        isFalse,
      );
    });

    test('handles an empty blacklist safely', () {
      expect(blacklistMatches('herhangi bir metin', const []), isFalse);
    });

    test('matches obfuscated variants via normalization', () {
      expect(blacklistMatches('4mk yorumu', ['amk']), isTrue);
    });
  });

  group('ContentModeration.validateReview', () {
    test('rejects content shorter than minimum length', () async {
      final result = await ContentModeration.instance.validateReview(
        content: 'kisa',
      );
      expect(result, isNotNull);
      expect(result!.code, 'content_too_short');
    });
  });
}
