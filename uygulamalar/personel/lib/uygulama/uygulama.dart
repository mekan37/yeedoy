import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/riverpod_uzantilari.dart';
import '../core/tema_tercihleri.dart';
import 'tema/tema.dart';
import 'uygulama_rotalari.dart';

class PersonelApp extends ConsumerWidget {
  const PersonelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(temaModeProvider).valueOrNull ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'Yeedoy İşletme',
      debugShowCheckedModeBanner: false,
      theme: buildPersonelLightTheme(),
      darkTheme: buildPersonelTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
