import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:partyforge/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens Chrono Lock from home', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('قفل زمان').first);
    await tester.pumpAndSettle();
    expect(find.text('شروع'), findsOneWidget);
  });
}
