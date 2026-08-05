import 'package:go_router/go_router.dart';

import '../games/chrono_lock/presentation/chrono_lock_screen.dart';
import '../multiplayer/presentation/lan_host_screen.dart';
import '../multiplayer/presentation/lan_join_screen.dart';
import '../shared_ui/screens/diagnostics_screen.dart';
import '../shared_ui/screens/home_screen.dart';
import '../shared_ui/screens/profiles_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/profiles', builder: (_, __) => const ProfilesScreen()),
    GoRoute(path: '/lan/host', builder: (_, __) => const LanHostScreen()),
    GoRoute(path: '/lan/join', builder: (_, __) => const LanJoinScreen()),
    GoRoute(
      path: '/games/chrono-lock',
      builder: (_, __) => const ChronoLockScreen(),
    ),
    GoRoute(
      path: '/diagnostics',
      builder: (_, __) => const DiagnosticsScreen(),
    ),
  ],
);
