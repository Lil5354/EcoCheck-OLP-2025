import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eco_check_worker/main.dart';
import 'package:eco_check_worker/data/repositories/auth_repository.dart';
import 'package:eco_check_worker/data/repositories/route_repository.dart';
import 'package:eco_check_worker/data/repositories/collection_repository.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize test dependencies
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final authRepository = AuthRepository(prefs);
    final routeRepository = RouteRepository();
    final collectionRepository = CollectionRepository();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(
        authRepository: authRepository,
        routeRepository: routeRepository,
        collectionRepository: collectionRepository,
      ),
    );

    // Verify that login screen loads
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
