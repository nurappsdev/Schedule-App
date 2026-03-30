import 'package:flutter_test/flutter_test.dart';
import 'package:multi_parallel_test/main.dart';

void main() {
  testWidgets('App Cloner smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app shows the title "App Cloner".
    expect(find.text('App Cloner'), findsOneWidget);

    // Verify that we have the two tabs
    expect(find.text('All Apps'), findsOneWidget);
    expect(find.text('Cloned Apps'), findsOneWidget);
  });
}
