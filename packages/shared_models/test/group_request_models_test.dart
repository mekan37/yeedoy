import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy_shared_models/yeedoy_shared_models.dart';

void main() {
  group('GroupRequest.fromMap', () {
    test('parses a fully populated map', () {
      final request = GroupRequest.fromMap({
        'id': 'req-1',
        'created_by': 'user-1',
        'city': 'İstanbul',
        'districts': ['Kadıköy', 'Beşiktaş'],
        'category': 'meyhane',
        'date_time': '2026-08-01T19:00:00.000Z',
        'party_size': 6,
        'budget_total_cents': 500000,
        'currency': 'TRY',
        'notes': 'Pencere kenarı olsun',
        'status': 'open',
        'created_at': '2026-07-01T10:00:00.000Z',
      });

      expect(request.id, 'req-1');
      expect(request.districts, ['Kadıköy', 'Beşiktaş']);
      expect(request.partySize, 6);
      expect(request.budgetTotalCents, 500000);
      expect(request.notes, 'Pencere kenarı olsun');
    });

    test('applies defaults for missing optional fields', () {
      final request = GroupRequest.fromMap({
        'id': 'req-2',
        'created_by': 'user-2',
        'city': 'Ankara',
      });

      expect(request.category, isNull);
      expect(request.notes, isNull);
      expect(request.currency, 'TRY');
      expect(request.status, 'open');
      expect(request.districts, isEmpty);
      expect(request.partySize, 0);
    });

    test('treats blank strings as null for nullable fields', () {
      final request = GroupRequest.fromMap({
        'id': 'req-3',
        'created_by': 'user-3',
        'city': 'İzmir',
        'notes': '   ',
      });

      expect(request.notes, isNull);
    });

    test('equality is based on field values', () {
      final map = {
        'id': 'req-4',
        'created_by': 'user-4',
        'city': 'Bursa',
        'districts': ['Nilüfer'],
        'date_time': '2026-08-01T19:00:00.000Z',
        'created_at': '2026-07-01T10:00:00.000Z',
      };
      expect(GroupRequest.fromMap(map), GroupRequest.fromMap(map));
    });
  });

  group('GroupOffer.fromMap', () {
    test('parses a fully populated map', () {
      final offer = GroupOffer.fromMap({
        'id': 'offer-1',
        'request_id': 'req-1',
        'business_id': 'biz-1',
        'offered_total_cents': 450000,
        'includes': {'icecek': true},
        'message': 'Elimizden geleni yaparız',
        'status': 'submitted',
        'created_by': 'owner-1',
        'created_at': '2026-07-02T10:00:00.000Z',
        'votes_count': 3,
        'my_vote': 1,
      });

      expect(offer.offeredTotalCents, 450000);
      expect(offer.includes, {'icecek': true});
      expect(offer.votesCount, 3);
      expect(offer.myVote, 1);
    });

    test('defaults votesCount from legacy votes key', () {
      final offer = GroupOffer.fromMap({
        'id': 'offer-2',
        'request_id': 'req-1',
        'business_id': 'biz-2',
        'offered_total_cents': 100000,
        'votes': 7,
      });

      expect(offer.votesCount, 7);
      expect(offer.myVote, isNull);
      expect(offer.includes, isEmpty);
    });

    test('defaults status to submitted', () {
      final offer = GroupOffer.fromMap({
        'id': 'offer-3',
        'request_id': 'req-1',
        'business_id': 'biz-3',
        'offered_total_cents': 0,
      });

      expect(offer.status, 'submitted');
    });
  });
}
