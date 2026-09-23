import 'package:flutter_test/flutter_test.dart';
import 'package:craftconnect/main.dart';

void main() {
  testWidgets('CraftConnectApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CraftConnectApp(
        firebaseInitialized: false,
        initError: null,
      ),
    );
    await tester.pumpAndSettle();

    // Verify CraftConnect title or setup screen renders without throwing
    expect(find.text('CraftConnect Setup'), findsOneWidget);
  });
}
