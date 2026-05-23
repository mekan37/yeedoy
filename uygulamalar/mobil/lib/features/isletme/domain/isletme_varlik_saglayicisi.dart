import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ag/supabase_saglayicisi.dart';

/// Returns the number of users currently viewing this business page (including
/// the local user). Uses Supabase Realtime Presence. Privacy-safe: only an
/// anonymous per-session timestamp is broadcast, no user IDs.
///
/// Returns null while the channel is connecting (avoids flash of "1 person").
final businessPresenceCountProvider =
    NotifierProvider.family<BusinessPresenceNotifier, int?, String>(
  BusinessPresenceNotifier.new,
);

class BusinessPresenceNotifier extends Notifier<int?> {
  BusinessPresenceNotifier(this.businessId);
  final String businessId;

  RealtimeChannel? _channel;

  @override
  int? build() {
    if (businessId.isEmpty) return null;
    ref.onDispose(_dispose);
    _subscribe();
    return null; // connecting
  }

  void _subscribe() {
    final client = ref.read(supabaseProvider);
    _channel = client
        .channel(
          'business_presence:$businessId',
          opts: const RealtimeChannelConfig(ack: false),
        )
        .onPresenceSync((_) {
          final count = _channel?.presenceState().length;
          if (count != null) state = count;
        })
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            _channel?.track({
              'joined_at': DateTime.now().millisecondsSinceEpoch,
            });
          }
        });
  }

  void _dispose() {
    if (_channel == null) return;
    try {
      ref.read(supabaseProvider).removeChannel(_channel!);
    } catch (_) {}
    _channel = null;
  }
}
