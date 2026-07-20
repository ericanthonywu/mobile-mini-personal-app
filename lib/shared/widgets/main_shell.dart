import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';

/// Main scaffold with bottom navigation bar and swipeable PageView.
/// Wraps all authenticated screens via StatefulShellRoute.
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final PageController _pageController;
  bool _isUserSwiping = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.navigationShell.currentIndex);
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When GoRouter changes the branch (e.g., via context.go),
    // animate the PageView to follow.
    final newIndex = widget.navigationShell.currentIndex;
    if (!_isUserSwiping && _pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage != newIndex) {
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _onPageChanged(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    setState(() {}); // rebuild nav bar to reflect new index
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NotificationListener<ScrollStartNotification>(
        onNotification: (n) {
          if (n.metrics.axis == Axis.horizontal) _isUserSwiping = true;
          return false;
        },
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.horizontal) _isUserSwiping = false;
            return false;
          },
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const ClampingScrollPhysics(),
            // Each page renders the shell — the shell internally manages the IndexedStack
            // We pass a placeholder for non-active branches; the shell's IndexedStack
            // keeps all branch widgets alive automatically.
            children: List.generate(4, (i) {
              return _IndexedPage(
                navigationShell: widget.navigationShell,
                branchIndex: i,
              );
            }),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: _onNavTap,
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

/// Renders the branch widget for a given index.
/// Non-active branches are kept offstage to preserve state.
class _IndexedPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final int branchIndex;

  const _IndexedPage({
    required this.navigationShell,
    required this.branchIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = navigationShell.currentIndex == branchIndex;
    // Use Offstage to keep widget trees alive but hidden when not active
    return Offstage(
      offstage: !isActive,
      child: isActive ? navigationShell : const SizedBox.expand(),
    );
  }
}
