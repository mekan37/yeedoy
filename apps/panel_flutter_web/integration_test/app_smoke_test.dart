import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('panel integration smoke renders widget tree', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('panel_integration_smoke'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('panel_integration_smoke'), findsOneWidget);
  });
}
