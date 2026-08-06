import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../games/catalog/game_catalog.dart';
import '../games/chrono_lock/presentation/chrono_lock_screen.dart';
import '../games/color_clash/presentation/color_clash_screen.dart';
import '../games/ghost_trace/presentation/ghost_trace_screen.dart';
import '../games/hidden_fuse/presentation/hidden_fuse_screen.dart';
import '../games/memory_grid/presentation/memory_grid_screen.dart';
import '../games/number_rush/presentation/number_rush_screen.dart';
import '../games/tap_storm/presentation/tap_storm_screen.dart';
import '../games/word_forge/presentation/word_forge_screen.dart';
import '../multiplayer/presentation/lan_host_screen.dart';
import '../multiplayer/presentation/lan_join_screen.dart';
import '../shared_ui/screens/diagnostics_screen.dart';
import '../shared_ui/screens/game_info_screen.dart';
import '../shared_ui/screens/game_selection_screen.dart';
import '../shared_ui/screens/home_screen.dart';
import '../shared_ui/screens/multiplayer_screen.dart';
import '../shared_ui/screens/profiles_screen.dart';
import '../shared_ui/widgets/party_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/play',
      builder: (context, state) => const GameSelectionScreen(),
    ),
    GoRoute(
      path: '/play/:gameId/info',
      builder: (context, state) {
        final game = GameCatalog.find(state.pathParameters['gameId'] ?? '');
        if (game == null) {
          return const _UnknownGameScreen();
        }
        return GameInfoScreen(game: game);
      },
    ),
    GoRoute(
      path: '/multiplayer',
      builder: (context, state) => const MultiplayerScreen(),
    ),
    GoRoute(
      path: '/profiles',
      builder: (context, state) => const ProfilesScreen(),
    ),
    GoRoute(
      path: '/lan/host',
      builder: (context, state) => const LanHostScreen(),
    ),
    GoRoute(
      path: '/lan/join',
      builder: (context, state) => const LanJoinScreen(),
    ),
    GoRoute(
      path: '/games/chrono-lock',
      builder: (context, state) => const ChronoLockScreen(),
    ),
    GoRoute(
      path: '/games/hidden-fuse',
      builder: (context, state) => const HiddenFuseScreen(),
    ),
    GoRoute(
      path: '/games/ghost-trace',
      builder: (context, state) => const GhostTraceScreen(),
    ),
    GoRoute(
      path: '/games/word-forge',
      builder: (context, state) => const WordForgeScreen(),
    ),
    GoRoute(
      path: '/games/memory-grid',
      builder: (context, state) => const MemoryGridScreen(),
    ),
    GoRoute(
      path: '/games/color-clash',
      builder: (context, state) => const ColorClashScreen(),
    ),
    GoRoute(
      path: '/games/number-rush',
      builder: (context, state) => const NumberRushScreen(),
    ),
    GoRoute(
      path: '/games/tap-storm',
      builder: (context, state) => const TapStormScreen(),
    ),
    GoRoute(
      path: '/diagnostics',
      builder: (context, state) => const DiagnosticsScreen(),
    ),
  ],
  errorBuilder: (context, state) => const _UnknownGameScreen(),
);

class _UnknownGameScreen extends StatelessWidget {
  const _UnknownGameScreen();

  @override
  Widget build(BuildContext context) {
    return PartyScaffold(
      title: 'صفحه پیدا نشد',
      fallbackLocation: '/',
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('این مسیر یا بازی در دسترس نیست.'),
        ),
      ),
    );
  }
}
