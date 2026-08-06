import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:partyforge/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens Chrono Lock through the game catalog', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'بازی'));
    await tester.pumpAndSettle();
    expect(find.text('انتخاب بازی'), findsOneWidget);

    final startButtons = find.widgetWithText(FilledButton, 'شروع');
    await tester.ensureVisible(startButtons.first);
    await tester.tap(startButtons.first);
    await tester.pumpAndSettle();
    expect(find.text('شروع'), findsOneWidget);
  });
}
