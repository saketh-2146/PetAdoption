import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect/widgets/rating_widget.dart';

void main() {
  testWidgets('RatingWidget displays rating and reviews', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RatingWidget(
          rating: 4.8,
          reviews: 125,
        ),
      ),
    ));

    // Verify star icon is present
    expect(find.byIcon(Icons.star), findsOneWidget);

    // Verify rating text is formatted to one decimal place
    expect(find.text('4.8'), findsOneWidget);

    // Verify reviews text
    expect(find.text('(125 reviews)'), findsOneWidget);
  });
}
