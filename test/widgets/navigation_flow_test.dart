import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:partyforge/shared_ui/screens/game_selection_screen.dart';
import 'package:partyforge/shared_ui/screens/home_screen.dart';
import 'package:partyforge/shared_ui/widgets/party_scaffold.dart';

void main() {
  testWidgets('home enters a separate game selection screen', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/play',
          builder: (context, state) => const GameSelectionScreen(),
        ),
        GoRoute(
          path: '/play/:gameId/info',
          builder: (context, state) => const _PlaceholderScreen(title: 'اطلاعات'),
        ),
        GoRoute(
          path: '/games/chrono-lock',
          builder: (context, state) => const _PlaceholderScreen(title: 'قفل زمان'),
        ),
        GoRoute(
          path: '/multiplayer',
          builder: (context, state) => const _PlaceholderScreen(title: 'چندنفره'),
        ),
        GoRoute(
          path: '/profiles',
          builder: (context, state) => const _PlaceholderScreen(title: 'پروفایل‌ها'),
        ),
        GoRoute(
          path: '/diagnostics',
          builder: (context, state) => const _PlaceholderScreen(title: 'عیب‌یابی'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('قفل زمان'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'بازی'));
    await tester.pumpAndSettle();

    expect(find.text('انتخاب بازی'), findsOneWidget);
    expect(find.text('قفل زمان'), findsOneWidget);
    expect(find.byTooltip('بازگشت'), findsOneWidget);
  });

  testWidgets('back button uses fallback when there is no stack', (tester) async {
    final router = GoRouter(
      initialLocation: '/details',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Text('خانه')),
        GoRoute(
          path: '/details',
          builder: (context, state) => const PartyScaffold(
            title: 'جزئیات',
            fallbackLocation: '/',
            body: SizedBox(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byTooltip('بازگشت'));
    await tester.pumpAndSettle();
    expect(find.text('خانه'), findsOneWidget);
  });
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(title));
}
