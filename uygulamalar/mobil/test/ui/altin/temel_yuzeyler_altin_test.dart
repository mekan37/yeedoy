import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _runGoldenTests = bool.fromEnvironment('RUN_GOLDENS');

void main() {
  testWidgets('home shell surface golden', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _GoldenHomeSurface()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(_GoldenHomeSurface),
      matchesGoldenFile('goldens/home_shell_surface.png'),
    );
  }, skip: !_runGoldenTests);

  testWidgets('business header surface golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _GoldenBusinessHeaderSurface()),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(_GoldenBusinessHeaderSurface),
      matchesGoldenFile('goldens/isletme_header_surface.png'),
    );
  }, skip: !_runGoldenTests);
}

class _GoldenHomeSurface extends StatelessWidget {
  const _GoldenHomeSurface();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Card(title: 'Yakın ve Açık', subtitle: '8 sonuç'),
          SizedBox(height: 12),
          _Card(title: 'Trend', subtitle: 'Bugün yükselenler'),
        ],
      ),
    );
  }
}

class _GoldenBusinessHeaderSurface extends StatelessWidget {
  const _GoldenBusinessHeaderSurface();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            _Card(title: 'Açık • 23:30', subtitle: 'Ortalama: TRY 210'),
            SizedBox(height: 8),
            _Card(title: 'Popüler: Adana, Lahmacun', subtitle: 'Doğrulama: 2g'),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle),
        ],
      ),
    );
  }
}

