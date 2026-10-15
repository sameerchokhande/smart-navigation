
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/main.dart';

void main() {
  setUp(() {
    // Mock local storage for widget tests.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'CareConnect opens the role selection screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(const CareConnectApp());

      // Allow the asynchronous session check to finish.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CareConnect'), findsOneWidget);
      expect(find.text('I need support'), findsOneWidget);
      expect(find.text('I provide services'), findsOneWidget);
    },
  );
}
