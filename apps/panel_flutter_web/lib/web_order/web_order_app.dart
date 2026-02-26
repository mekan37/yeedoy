import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/i18n/app_localizations.dart';
import '../src/ui/theme/app_theme.dart';
import 'routes/web_order_routes.dart';

class WebOrderApp extends StatelessWidget {
  const WebOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).menu,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('tr');
        for (final s in supportedLocales) {
          if (s.languageCode == locale.languageCode) return s;
        }
        return const Locale('tr');
      },
      theme: buildAppTheme(),
      home: const _WebOrderHomePage(routeName: webOrderInitialRoute),
    );
  }
}

class _WebOrderHomePage extends StatelessWidget {
  const _WebOrderHomePage({required this.routeName});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.menu)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'TODO: Web Order sayfalari bu alana tasinacak.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
