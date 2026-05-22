import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

Stream<bool> _baglantiStream() async* {
  while (true) {
    try {
      final res = await InternetAddress.lookup('supabase.co')
          .timeout(const Duration(seconds: 4));
      yield res.isNotEmpty && res.first.rawAddress.isNotEmpty;
    } catch (_) {
      yield false;
    }
    await Future.delayed(const Duration(seconds: 10));
  }
}

final baglantiDurumuProvider = StreamProvider.autoDispose<bool>((ref) {
  return _baglantiStream();
});
