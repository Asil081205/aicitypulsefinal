import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_app.dart';  // Import test app instead of main

void main() {
  testWidgets('Test app loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const TestApp());
    await tester.pumpAndSettle();

    expect(find.text('AI CITY PULSE'), findsOneWidget);
    expect(find.text('CITY HEALTH INDEX'), findsOneWidget);
    expect(find.byIcon(Icons.map), findsOneWidget);
    expect(find.text('View Map'), findsOneWidget);
  });
}