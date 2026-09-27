import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/shared/widgets/main_shell.dart';
import 'package:go_router/go_router.dart';

class _FakeNavigationShell extends StatefulWidget implements StatefulNavigationShell {
  @override
  final int currentIndex;

  const _FakeNavigationShell({super.key, this.currentIndex = 0});

  @override
  void goBranch(int index, {bool initialLocation = false}) {}

  @override
  State<_FakeNavigationShell> createState() => _FakeNavigationShellState();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNavigationShellState extends State<_FakeNavigationShell> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('MainShell displays exactly 3 navigation tabs: Dashboard, Transaksi, Breakdown',
      (WidgetTester tester) async {
    const fakeShell = _FakeNavigationShell(currentIndex: 0);

    await tester.pumpWidget(
      const MaterialApp(
        home: MainShell(navigationShell: fakeShell),
      ),
    );

    final bottomNavFinder = find.byType(BottomNavigationBar);
    expect(bottomNavFinder, findsOneWidget);

    final bottomNav = tester.widget<BottomNavigationBar>(bottomNavFinder);
    expect(bottomNav.items.length, 3);
    expect(bottomNav.items[0].label, 'Dashboard');
    expect(bottomNav.items[1].label, 'Transaksi');
    expect(bottomNav.items[2].label, 'Breakdown');

    // Confirm that Kategori and Anggaran tabs are completely removed
    expect(find.text('Kategori'), findsNothing);
    expect(find.text('Anggaran'), findsNothing);
  });
}
