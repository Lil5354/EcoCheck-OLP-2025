import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eco_check_worker/main.dart';
import 'package:eco_check_worker/core/di/injection_container.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize test dependencies
    SharedPreferences.setMockInitialValues({});

    // Initialize DI container
    await initializeDependencies();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that login screen loads
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
