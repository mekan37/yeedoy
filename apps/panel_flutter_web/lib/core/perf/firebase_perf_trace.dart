import 'package:firebase_performance/firebase_performance.dart';

Future<Trace?> startFirebaseTrace(String name) async {
  try {
    final trace = FirebasePerformance.instance.newTrace(name);
    await trace.start();
    return trace;
  } catch (_) {
    return null;
  }
}

Future<void> stopFirebaseTrace(Trace? trace) async {
  if (trace == null) return;
  try {
    await trace.stop();
  } catch (_) {}
}
