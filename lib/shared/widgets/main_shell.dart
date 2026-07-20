import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';

/// Main scaffold with bottom navigation bar and horizontal swipe gesture support.
/// Wraps all authenticated screens via StatefulShellRoute.indexedStack.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onNavTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity;
          if (velocity != null) {
            // Swipe Left (velocity < -250) -> Go to next tab
            if (velocity < -250 && currentIndex < 3) {
              _onNavTap(currentIndex + 1);
            }
            // Swipe Right (velocity > 250) -> Go to previous tab
            else if (velocity > 250 && currentIndex > 0) {
              _onNavTap(currentIndex - 1);
            }
          }
        },
        child: navigationShell,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 1 ? Icons.receipt_long_rounded : Icons.receipt_long_outlined),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 2 ? Icons.label_rounded : Icons.label_outline_rounded),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 3 ? Icons.pie_chart_rounded : Icons.pie_chart_outline_rounded),
              label: 'Budget',
            ),
          ],
        ),
      ),
    );
  }
}
