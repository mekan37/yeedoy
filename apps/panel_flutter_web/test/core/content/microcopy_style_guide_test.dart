import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/content/microcopy_style_guide.dart';

void main() {
  test('microcopy verbs are canonical for critical intents', () {
    expect(
      MicrocopyStyleGuide.isCanonical(intent: 'retry', text: 'Tekrar dene'),
      isTrue,
    );
    expect(
      MicrocopyStyleGuide.isCanonical(intent: 'approve', text: 'Onayla'),
      isTrue,
    );
    expect(
      MicrocopyStyleGuide.isCanonical(intent: 'cancel', text: 'Vazgeç'),
      isTrue,
    );
  });

  test('non-canonical wording fails quality gate', () {
    expect(
      MicrocopyStyleGuide.isCanonical(intent: 'retry', text: 'Yeniden dene'),
      isFalse,
    );
  });
}

