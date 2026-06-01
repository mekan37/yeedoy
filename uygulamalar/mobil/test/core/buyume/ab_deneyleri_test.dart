import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/growth/ab_experiments.dart';

void main() {
  test('home category layout falls back to horizontal when disabled', () {
    const experiments = GrowthExperiments(
      subjectId: 'user-a',
      remoteConfig: {
        'home_category_layout': {
          'enabled': false,
          'variants': {'horizontal': 50, 'grid2x4': 50},
        },
      },
    );
    expect(
      experiments.variantOf(GrowthExperiment.homeCategoryLayout),
      'horizontal',
    );
  });

  test('verify price cta assignment is deterministic', () {
    const config = {
      'verify_price_cta_placement': {
        'enabled': true,
        'variants': {'bottom': 50, 'top': 50},
      },
    };
    const a = GrowthExperiments(subjectId: 'same-user', remoteConfig: config);
    const b = GrowthExperiments(subjectId: 'same-user', remoteConfig: config);
    expect(
      a.variantOf(GrowthExperiment.verifyPriceCtaPlacement),
      b.variantOf(GrowthExperiment.verifyPriceCtaPlacement),
    );
  });
}

