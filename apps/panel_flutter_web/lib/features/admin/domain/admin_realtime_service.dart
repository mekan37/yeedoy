import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import 'admin_new_items_controller.dart';

final adminRealtimeServiceProvider = Provider<AdminRealtimeService>((ref) {
  return AdminRealtimeService(ref);
});

class AdminRealtimeService {
  AdminRealtimeService(this.ref);

  final Ref ref;
  RealtimeChannel? _reportsChannel;
  RealtimeChannel? _claimsChannel;
  RealtimeChannel? _suggestionsChannel;
  RealtimeChannel? _priceSuggestionsChannel;
  RealtimeChannel? _suspendedClaimsChannel;
  bool _started = false;

  void start() {
    if (_started || !kIsWeb) return;
    _started = true;
    final client = ref.read(supabaseProvider);

    _reportsChannel = client
        .channel('admin_reports_insert')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'reports',
          callback: (_) => ref.read(adminNewItemsProvider.notifier).incReports(),
        )
        .subscribe();

    _claimsChannel = client
        .channel('admin_owner_claims_insert')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'owner_claims',
          callback: (_) => ref.read(adminNewItemsProvider.notifier).incClaims(),
        )
        .subscribe();

    _suggestionsChannel = client
        .channel('admin_suggestions_insert')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'business_suggestions',
          callback: (_) => ref.read(adminNewItemsProvider.notifier).incSuggestions(),
        )
        .subscribe();

    _priceSuggestionsChannel = client
        .channel('admin_price_suggestions_insert')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'menu_item_price_suggestions',
          callback: (_) => ref.read(adminNewItemsProvider.notifier).incPriceSuggestions(),
        )
        .subscribe();

    _suspendedClaimsChannel = client
        .channel('admin_suspended_meal_claims_insert')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'suspended_meal_claims',
          callback: (_) => ref.read(adminNewItemsProvider.notifier).incSuspendedClaims(),
        )
        .subscribe();
  }

  void stop() {
    if (!_started) return;
    _started = false;
    final client = ref.read(supabaseProvider);
    if (_reportsChannel != null) {
      client.removeChannel(_reportsChannel!);
      _reportsChannel = null;
    }
    if (_claimsChannel != null) {
      client.removeChannel(_claimsChannel!);
      _claimsChannel = null;
    }
    if (_suggestionsChannel != null) {
      client.removeChannel(_suggestionsChannel!);
      _suggestionsChannel = null;
    }
    if (_priceSuggestionsChannel != null) {
      client.removeChannel(_priceSuggestionsChannel!);
      _priceSuggestionsChannel = null;
    }
    if (_suspendedClaimsChannel != null) {
      client.removeChannel(_suspendedClaimsChannel!);
      _suspendedClaimsChannel = null;
    }
  }
}
