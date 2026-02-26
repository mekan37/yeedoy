import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Golden paths', () {
    testWidgets('Home -> Business -> Menu -> Verify Price', (tester) async {
      await tester.pumpWidget(const _GoldenPathApp());

      expect(find.byKey(const Key('home-screen')), findsOneWidget);
      await tester.tap(find.byKey(const Key('open-business-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('business-screen')), findsOneWidget);
      await tester.tap(find.byKey(const Key('open-menu-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu-screen')), findsOneWidget);
      await tester.tap(find.byKey(const Key('verify-price-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verify-success-chip')), findsOneWidget);
    });

    testWidgets('Login -> Review submit', (tester) async {
      await tester.pumpWidget(const _GoldenPathApp());

      await tester.tap(find.byKey(const Key('go-login-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login-screen')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('login-email-input')),
        'qa@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-pass-input')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('login-submit-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review-screen')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('review-input')),
        'Fiyat ve servis gayet iyiydi.',
      );
      await tester.tap(find.byKey(const Key('review-submit-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review-success-banner')), findsOneWidget);
    });
  });
}

class _GoldenPathApp extends StatelessWidget {
  const _GoldenPathApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const _HomeScreen(),
      routes: <String, WidgetBuilder>{
        '/business': (_) => const _BusinessScreen(),
        '/menu': (_) => const _MenuScreen(),
        '/login': (_) => const _LoginScreen(),
        '/review': (_) => const _ReviewScreen(),
      },
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home-screen'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              key: const Key('open-business-btn'),
              onPressed: () => Navigator.of(context).pushNamed('/business'),
              child: const Text('Business'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const Key('go-login-btn'),
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessScreen extends StatelessWidget {
  const _BusinessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('business-screen'),
      body: Center(
        child: ElevatedButton(
          key: const Key('open-menu-btn'),
          onPressed: () => Navigator.of(context).pushNamed('/menu'),
          child: const Text('Menu'),
        ),
      ),
    );
  }
}

class _MenuScreen extends StatefulWidget {
  const _MenuScreen();

  @override
  State<_MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<_MenuScreen> {
  var _verified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('menu-screen'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              key: const Key('verify-price-btn'),
              onPressed: () => setState(() => _verified = true),
              child: const Text('Verify price'),
            ),
            if (_verified)
              const Chip(
                key: Key('verify-success-chip'),
                label: Text('Price verified'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoginScreen extends StatelessWidget {
  const _LoginScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('login-screen'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(key: Key('login-email-input')),
            const SizedBox(height: 8),
            const TextField(key: Key('login-pass-input')),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const Key('login-submit-btn'),
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/review'),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewScreen extends StatefulWidget {
  const _ReviewScreen();

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  var _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('review-screen'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(key: Key('review-input')),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const Key('review-submit-btn'),
              onPressed: () => setState(() => _submitted = true),
              child: const Text('Send'),
            ),
            if (_submitted)
              const MaterialBanner(
                key: Key('review-success-banner'),
                content: Text('Review submitted'),
                actions: [SizedBox.shrink()],
              ),
          ],
        ),
      ),
    );
  }
}
