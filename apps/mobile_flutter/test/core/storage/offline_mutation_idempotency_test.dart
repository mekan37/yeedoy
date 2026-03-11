import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeedoy/core/storage/offline_mutation_idempotency.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'analytics_client_id': 'client-test',
    });
  });

  group('offline mutation idempotency', () {
    test('same logical payload produces same key', () async {
      final first = await createOfflineMutationIdempotencyToken(
        action: 'reportBusiness',
        payload: {
          'business_id': 'b1',
          'reason': 'wrong_info',
          'details': 'same',
        },
      );
      final second = await createOfflineMutationIdempotencyToken(
        action: 'reportBusiness',
        payload: {
          'reason': 'wrong_info',
          'details': 'same',
          'business_id': 'b1',
        },
      );

      expect(first.clientId, 'client-test');
      expect(second.clientId, 'client-test');
      expect(first.idempotencyKey, second.idempotencyKey);
      expect(first.payloadHash, second.payloadHash);
    });

    test('metadata fields do not affect generated key', () async {
      final token = await createOfflineMutationIdempotencyToken(
        action: 'reviewCreate',
        payload: {
          'business_id': 'b1',
          'rating': 5,
          'content': 'great',
        },
      );
      final second = await createOfflineMutationIdempotencyToken(
        action: 'reviewCreate',
        payload: {
          'business_id': 'b1',
          'rating': 5,
          'content': 'great',
          'client_id': 'ignored',
          'payload_hash': 'ignored',
          'idempotency_key': 'ignored',
        },
      );

      expect(token.idempotencyKey, second.idempotencyKey);
    });
  });
}
