import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';

/// Bottom navigation shell — wraps tabbed screens.
///
/// Uses GoRouter location to determine the active tab index.
class BottomNavShell extends StatelessWidget {
  const BottomNavShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.history)) return 1;
    if (location.startsWith(AppRoutes.profile)) return 2;
    if (location.startsWith(AppRoutes.about)) return 3;
    return 0; // dashboard
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.history);
      case 2:
        context.go(AppRoutes.profile);
      case 3:
        context.go(AppRoutes.about);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => _onTap(context, i),
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceLight,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sync),
              activeIcon: Icon(Icons.sync, color: AppTheme.primary),
              label: 'TASKS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: Icon(Icons.history, color: AppTheme.primary),
              label: 'HISTORY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppTheme.primary),
              label: 'PROFILE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              activeIcon: Icon(Icons.info, color: AppTheme.primary),
              label: 'ABOUT',
            ),
          ],
        ),
      ),
    );
  }
}
