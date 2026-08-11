import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/sadakat/domain/sadakat_saglayicisi.dart';

void main() {
  group('LoyaltyCard.fromMap', () {
    test('tüm alanlar doluyken doğru parse eder', () {
      final card = LoyaltyCard.fromMap({
        'program_id': 'p-1',
        'mode': 'points',
        'business_name': 'Test Kahve',
        'logo_url': 'https://example.com/logo.png',
        'progress': 80,
        'reward_threshold': 200,
        'reward_desc': '200 puana 1 tatlı hediye',
      });

      expect(card.programId, 'p-1');
      expect(card.mode, 'points');
      expect(card.businessName, 'Test Kahve');
      expect(card.logoUrl, 'https://example.com/logo.png');
      expect(card.progress, 80);
      expect(card.rewardThreshold, 200);
      expect(card.rewardDesc, '200 puana 1 tatlı hediye');
    });

    test('eksik alanlar için güvenli varsayılanlar kullanır', () {
      final card = LoyaltyCard.fromMap(<String, dynamic>{});

      expect(card.programId, '');
      expect(card.mode, 'stamp');
      expect(card.businessName, '');
      expect(card.logoUrl, isNull);
      expect(card.progress, 0);
      expect(card.rewardThreshold, 1);
      expect(card.rewardDesc, '');
    });
  });

  group('LoyaltyCard.progressRatio', () {
    test('normal ilerlemede doğru oranı döner', () {
      final card = LoyaltyCard(
        programId: 'p-1',
        mode: 'stamp',
        businessName: 'Test',
        progress: 1,
        rewardThreshold: 5,
        rewardDesc: 'ödül',
      );
      expect(card.progressRatio, closeTo(0.2, 0.0001));
    });

    test('eşiği aşan ilerlemeyi 1.0\'a sabitler', () {
      final card = LoyaltyCard(
        programId: 'p-1',
        mode: 'points',
        businessName: 'Test',
        progress: 999,
        rewardThreshold: 200,
        rewardDesc: 'ödül',
      );
      expect(card.progressRatio, 1.0);
    });

    test('reward_threshold sıfır veya negatifse 0.0 döner', () {
      final card = LoyaltyCard(
        programId: 'p-1',
        mode: 'stamp',
        businessName: 'Test',
        progress: 3,
        rewardThreshold: 0,
        rewardDesc: 'ödül',
      );
      expect(card.progressRatio, 0.0);
    });
  });
}
