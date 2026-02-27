import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/sync_tasks/presentation/screens/dashboard_screen.dart';
import '../features/sync_tasks/presentation/screens/add_task_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/about/presentation/screens/about_screen.dart';
import '../shared/providers/app_providers.dart';
import '../shared/widgets/bottom_nav_shell.dart';

/// Route paths used throughout the app.
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/welcome';
  static const String dashboard = '/dashboard';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String about = '/about';
  static const String addTask = '/add-task';
}

/// Navigation key for the shell route (bottom nav).
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter provider — auth-aware with redirect guard (FR-0b).
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.welcome,
    refreshListenable: _RouterRefreshNotifier(ref),
    routes: [
      // Welcome screen — outside the bottom nav shell
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Add Task — full screen, outside bottom nav shell
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.addTask,
        builder: (context, state) => const AddTaskScreen(),
      ),

      // Bottom navigation shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.history,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
          GoRoute(
            path: AppRoutes.about,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AboutScreen()),
          ),
        ],
      ),
    ],

    // Auth redirect guard (FR-0b)
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isOnWelcome = state.matchedLocation == AppRoutes.welcome;

      // While loading auth state, don't redirect
      if (isLoading) return null;

      // If not logged in and not on welcome, redirect to welcome
      if (!isLoggedIn && !isOnWelcome) return AppRoutes.welcome;

      // If logged in and on welcome, redirect to dashboard
      if (isLoggedIn && isOnWelcome) return AppRoutes.dashboard;

      return null;
    },
  );
});

/// Notifier that triggers GoRouter refresh when auth state changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
