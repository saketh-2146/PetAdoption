import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect/widgets/loading_widget.dart';

void main() {
  testWidgets('LoadingWidget displays a CircularProgressIndicator', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LoadingWidget(),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
