import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schedule_app/main.dart';

void main() {
  testWidgets('App Cloner smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that our app shows the title "App Cloner & Scheduler".
    expect(find.text('App Cloner & Scheduler'), findsOneWidget);

    // Verify that we have the two tabs
    expect(find.text('All Apps'), findsOneWidget);
    expect(find.text('Schedule Creation'), findsOneWidget);
  });
}
