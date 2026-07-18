import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';

/// Main scaffold with bottom navigation bar.
/// Wraps all authenticated screens.
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/categories')) return 2;
    if (location.startsWith('/budget')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0: context.go('/'); break;
              case 1: context.go('/transactions'); break;
              case 2: context.go('/categories'); break;
              case 3: context.go('/budget'); break;
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 1 ? Icons.receipt_long_rounded : Icons.receipt_long_outlined),
              label: 'Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 2 ? Icons.label_rounded : Icons.label_outline_rounded),
              label: 'Kategori',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 3 ? Icons.pie_chart_rounded : Icons.pie_chart_outline_rounded),
              label: 'Anggaran',
            ),
          ],
        ),
      ),
    );
  }
}
