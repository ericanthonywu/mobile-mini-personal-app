import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';

/// Main scaffold with smooth animated swipe between the 4 nav tabs.
///
/// Uses [StatefulShellRoute.indexedStack] for routing (reliable state
/// preservation). Swipe and tap transitions are handled with a slide + fade
/// [AnimationController] that plays on top of the IndexedStack switch.
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Slide animation: incoming page translates from ±15% of width to 0.
  late Animation<Offset> _slideAnim;

  // Fade animation: incoming page fades from 0.75 → 1.0 opacity.
  late Animation<double> _fadeAnim;

  // Direction of the last switch (true = going to a higher index).
  bool _goingForward = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 270),
    );
    // No-op on startup — both begin and end at zero so the controller sitting
    // at 0.0 doesn't push the content off-screen.
    _slideAnim = const AlwaysStoppedAnimation(Offset.zero);
    _fadeAnim = const AlwaysStoppedAnimation(1.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _resetAnims({required bool forward}) {
    _slideAnim = Tween<Offset>(
      begin: Offset(forward ? 0.12 : -0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fadeAnim = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  /// Switch branch, then play slide-in animation from the correct direction.
  void _switchTo(int newIndex) {
    final current = widget.navigationShell.currentIndex;
    if (newIndex == current) return;

    _goingForward = newIndex > current;
    _resetAnims(forward: _goingForward);

    widget.navigationShell.goBranch(
      newIndex,
      initialLocation: newIndex == current,
    );

    _ctrl
      ..reset()
      ..forward();
  }

  void _onNavTap(int index) {
    HapticFeedback.selectionClick();
    _switchTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          // Swipe left → next tab
          if (v < -350 && currentIndex < 3) {
            HapticFeedback.selectionClick();
            _switchTo(currentIndex + 1);
          }
          // Swipe right → previous tab
          else if (v > 350 && currentIndex > 0) {
            HapticFeedback.selectionClick();
            _switchTo(currentIndex - 1);
          }
        },
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: child,
            ),
          ),
          child: widget.navigationShell,
        ),
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
              icon: Icon(currentIndex == 0
                  ? Icons.home_rounded
                  : Icons.home_outlined),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 1
                  ? Icons.receipt_long_rounded
                  : Icons.receipt_long_outlined),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 2
                  ? Icons.label_rounded
                  : Icons.label_outline_rounded),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentIndex == 3
                  ? Icons.pie_chart_rounded
                  : Icons.pie_chart_outline_rounded),
              label: 'Budget',
            ),
          ],
        ),
      ),
    );
  }
}
