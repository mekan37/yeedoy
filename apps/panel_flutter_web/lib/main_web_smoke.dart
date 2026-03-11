import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'smoke/panel_smoke_harness.dart';

SemanticsHandle? _smokeSemanticsHandle;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _smokeSemanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'http://127.0.0.1:54321',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'smoke-anon-key',
  );
  runApp(const PanelSmokeHarness());
}
