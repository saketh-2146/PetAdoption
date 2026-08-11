import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petconnect/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E App Test', () {
    testWidgets('App starts and renders initial screen', (WidgetTester tester) async {
      app.main();
      
      // Wait for the app to settle
      await tester.pumpAndSettle();

      // Ensure that we at least have a MaterialApp or a basic widget rendered
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
