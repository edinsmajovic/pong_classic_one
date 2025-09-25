// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:pong_classic_one/src/app.dart';

void main() {
  testWidgets('Menu renders and shows PLAY button', (WidgetTester tester) async {
    await tester.pumpWidget(const PongApp());
    // Allow async init (shared prefs) microtasks.
    await tester.pumpAndSettle();
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('PONG'), findsOneWidget);
  });
}
