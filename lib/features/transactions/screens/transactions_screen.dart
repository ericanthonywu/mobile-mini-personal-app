import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/transactions/providers/transaction_provider.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';
import 'package:expense_tracker/features/categories/providers/category_provider.dart';
import 'package:expense_tracker/shared/widgets/app_skeleton.dart';
import 'package:expense_tracker/shared/widgets/transaction_card.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;
  bool? _isIgnoredFilter;
  String? _categoryFilter;

  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  String? _selectedDateLabel;

  // Track selections for persistent sheet state
  String _tempFilterType = 'month'; // 'month', 'week', 'custom'
  int _tempYear = DateTime.now().year;
  int _tempMonth = DateTime.now().month;
  DateTime? _tempCustomFrom;
  DateTime? _tempCustomTo;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _monthShortNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    // Retrieve persistent filter values from global state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = ref.read(transactionProvider);
        setState(() {
          _selectedDateFrom = state.filters.dateFrom;
          _selectedDateTo = state.filters.dateTo;
          _selectedDateLabel = state.dateLabel;
          _isIgnoredFilter = state.filters.isIgnored;
          _categoryFilter = state.filters.categoryId;
          if (state.filters.search != null) {
            _searchController.text = state.filters.search!;
          }
          // Set temp date selectors in sheet to match selected filter
          if (_selectedDateFrom != null) {
            _tempYear = _selectedDateFrom!.year;
            _tempMonth = _selectedDateFrom!.month;
            _tempCustomFrom = _selectedDateFrom;
            _tempCustomTo = _selectedDateTo;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Generates Mon–Sun calendar weeks that cover the given month.
  List<Map<String, dynamic>> _getWeeksOfMonth(int year, int month) {
    final weeks = <Map<String, dynamic>>[];
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0); // last day of month

    // Find the Monday on or before the 1st of the month
    final firstDow = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    final daysToMonday = firstDow - 1; // how many days back to reach Monday
    DateTime weekStart = firstDayOfMonth.subtract(Duration(days: daysToMonday));

    int weekIndex = 1;
    while (weekStart.isBefore(lastDayOfMonth) || weekStart.isAtSameMomentAs(lastDayOfMonth)) {
      final weekEnd = weekStart.add(const Duration(days: 6));

      weeks.add({
        'index': weekIndex,
        'start': DateTime(weekStart.year, weekStart.month, weekStart.day, 0, 0, 0),
        'end': DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59, 999),
      });

      weekIndex++;
      weekStart = weekStart.add(const Duration(days: 7));
    }
    return weeks;
  }

  /// Returns the Monday of the week that [date] belongs to.
  static DateTime _weekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1; // Monday=1, so offset = weekday - 1
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  /// Builds a human-readable label for the Mon–Sun week that contains [monday].
  /// Format: "Week N of Mon YYYY" — if the week spans months:
  /// "Week 5 29 Jun – Week 1 5 Jul 2026"
  String _weekLabel(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));

    final sameMonth = monday.month == sunday.month;
    final sameYear = monday.year == sunday.year;

    if (sameMonth && sameYear) {
      // Calculate week-of-month index (1-based)
      final firstDayOfMonth = DateTime(monday.year, monday.month, 1);
      final firstDow = firstDayOfMonth.weekday; // 1=Mon
      final daysToMonday = firstDow - 1;
      final firstMonday = firstDayOfMonth.subtract(Duration(days: daysToMonday));
      final weekIndex = ((monday.difference(firstMonday).inDays) ~/ 7) + 1;
      return 'Week $weekIndex of ${_monthNames[monday.month - 1]} ${monday.year}';
    } else {
      // Cross-month week: compute week index in Monday's month & Sunday's month
      final firstDayMonMonth = DateTime(monday.year, monday.month, 1);
      final firstDowMon = firstDayMonMonth.weekday; // 1=Mon
      final firstMondayMon = firstDayMonMonth.subtract(Duration(days: firstDowMon - 1));
      final mondayWeekIdx = ((monday.difference(firstMondayMon).inDays) ~/ 7) + 1;

      final firstDaySunMonth = DateTime(sunday.year, sunday.month, 1);
      final firstDowSun = firstDaySunMonth.weekday; // 1=Mon
      final firstMondaySun = firstDaySunMonth.subtract(Duration(days: firstDowSun - 1));
      final sundayWeekIdx = ((monday.difference(firstMondaySun).inDays) ~/ 7) + 1;

      final monStr = 'Week $mondayWeekIdx ${monday.day} ${_monthShortNames[monday.month - 1]}';
      final sunStr = 'Week $sundayWeekIdx ${sunday.day} ${_monthShortNames[sunday.month - 1]}';
      if (sameYear) {
        return '$monStr – $sunStr ${sunday.year}';
      } else {
        return '$monStr ${monday.year} – $sunStr ${sunday.year}';
      }
    }
  }

  String _formatWeekRange(DateTime start, DateTime end) {
    final startStr = "${start.day} ${_monthShortNames[start.month - 1]}";
    final endStr = "${end.day} ${_monthShortNames[end.month - 1]}";
    return "$startStr - $endStr";
  }

  String _formatCustomRangeLabel(DateTime from, DateTime to) {
    final fromStr = "${from.day} ${_monthShortNames[from.month - 1]}";
    final toStr = "${to.day} ${_monthShortNames[to.month - 1]}";
    if (from.year == to.year) {
      return "$fromStr - $toStr ${from.year}";
    } else {
      return "$fromStr ${from.year} - $toStr ${to.year}";
    }
  }

  void _applyDateFilter(DateTime? from, DateTime? to, String? label) {
    setState(() {
      _selectedDateFrom = from;
      _selectedDateTo = to;
      _selectedDateLabel = label;
    });

    final notifier = ref.read(transactionProvider.notifier);
    final state = ref.read(transactionProvider);
    if (from == null || to == null) {
      notifier.applyFilters(state.filters.copyWith(clearDate: true), clearDateLabel: true);
    } else {
      notifier.applyFilters(state.filters.copyWith(dateFrom: from, dateTo: to), dateLabel: label);
    }
  }

  void _showDateFilterPicker(BuildContext context) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Sync local picker state from the live provider state so the sheet
    // correctly reflects any filter applied externally (e.g. from dashboard).
    final providerState = ref.read(transactionProvider);
    if (providerState.filters.dateFrom != null) {
      _selectedDateFrom = providerState.filters.dateFrom;
      _selectedDateTo = providerState.filters.dateTo;
      _selectedDateLabel = providerState.dateLabel;
      _tempYear = providerState.filters.dateFrom!.year;
      _tempMonth = providerState.filters.dateFrom!.month;
      _tempCustomFrom = providerState.filters.dateFrom;
      _tempCustomTo = providerState.filters.dateTo;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final weeks = _getWeeksOfMonth(_tempYear, _tempMonth);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20, 20, 20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter Date', style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Segmented Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _tempFilterType = 'month'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _tempFilterType == 'month' ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Month',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _tempFilterType == 'month' ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _tempFilterType = 'week'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _tempFilterType == 'week' ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Week',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _tempFilterType == 'week' ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _tempFilterType = 'custom'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _tempFilterType == 'custom' ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Custom',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _tempFilterType == 'custom' ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TAB CONTENT
                  if (_tempFilterType == 'month') ...[
                    // Year selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                          onPressed: () => setModalState(() => _tempYear--),
                        ),
                        Text(
                          '$_tempYear',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: _tempYear >= currentYear
                                ? AppColors.textDisabled.withOpacity(0.3)
                                : AppColors.textPrimary,
                          ),
                          onPressed: _tempYear >= currentYear
                              ? null
                              : () => setModalState(() => _tempYear++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Month Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isFutureMonth = _tempYear > currentYear ||
                            (_tempYear == currentYear && monthNum > currentMonth);

                        final isSelected = _selectedDateFrom != null &&
                            _selectedDateFrom!.year == _tempYear &&
                            _selectedDateFrom!.month == monthNum &&
                            _selectedDateTo!.year == _tempYear &&
                            _selectedDateTo!.month == monthNum &&
                            _selectedDateFrom!.day == 1 &&
                            _selectedDateTo!.day == DateTime(_tempYear, monthNum + 1, 0).day;

                        return GestureDetector(
                          onTap: isFutureMonth
                              ? null
                              : () {
                                  final start = DateTime(_tempYear, monthNum, 1, 0, 0, 0);
                                  final end = DateTime(_tempYear, monthNum + 1, 0, 23, 59, 59, 999);
                                  _tempMonth = monthNum;
                                  _applyDateFilter(start, end, "${_monthNames[index]} $_tempYear");
                                  Navigator.pop(context);
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : isFutureMonth
                                      ? AppColors.surfaceVariant.withOpacity(0.3)
                                      : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _monthShortNames[index],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : isFutureMonth
                                        ? AppColors.textDisabled.withOpacity(0.35)
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ] else if (_tempFilterType == 'week') ...[
                    // Month & Year Selector for Weeks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                          onPressed: () {
                            setModalState(() {
                              if (_tempMonth == 1) {
                                _tempMonth = 12;
                                _tempYear--;
                              } else {
                                _tempMonth--;
                              }
                            });
                          },
                        ),
                        Text(
                          "${_monthNames[_tempMonth - 1]} $_tempYear",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: (_tempYear > currentYear ||
                                    (_tempYear == currentYear && _tempMonth >= currentMonth))
                                ? AppColors.textDisabled.withOpacity(0.3)
                                : AppColors.textPrimary,
                          ),
                          onPressed: (_tempYear > currentYear ||
                                  (_tempYear == currentYear && _tempMonth >= currentMonth))
                              ? null
                              : () {
                                  setModalState(() {
                                    if (_tempMonth == 12) {
                                      _tempMonth = 1;
                                      _tempYear++;
                                    } else {
                                      _tempMonth++;
                                    }
                                  });
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Weeks List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: weeks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final wk = weeks[index];
                        final wkStart = wk['start'] as DateTime;
                        final wkEnd = wk['end'] as DateTime;
                        final wkIdx = wk['index'] as int;

                        final isFutureWeek = wkStart.isAfter(now);

                        final isSelected = _selectedDateFrom != null &&
                            _selectedDateFrom!.isAtSameMomentAs(wkStart) &&
                            _selectedDateTo!.isAtSameMomentAs(wkEnd);

                        return GestureDetector(
                          onTap: isFutureWeek
                              ? null
                              : () {
                                  _applyDateFilter(
                                    wkStart,
                                    wkEnd,
                                    "Wk $wkIdx, ${_monthShortNames[_tempMonth - 1]} $_tempYear",
                                  );
                                  Navigator.pop(context);
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : isFutureWeek
                                      ? AppColors.surfaceVariant.withOpacity(0.3)
                                      : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Week $wkIdx",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : isFutureWeek
                                            ? AppColors.textDisabled.withOpacity(0.35)
                                            : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _formatWeekRange(wkStart, wkEnd),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? Colors.white70
                                        : isFutureWeek
                                            ? AppColors.textDisabled.withOpacity(0.35)
                                            : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ] else if (_tempFilterType == 'custom') ...[
                    // Custom date range picker trigger
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: _tempCustomFrom != null && _tempCustomTo != null
                              ? DateTimeRange(start: _tempCustomFrom!, end: _tempCustomTo!)
                              : null,
                          firstDate: DateTime(2020),
                          lastDate: now,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: AppColors.surface,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          setModalState(() {
                            _tempCustomFrom = picked.start;
                            _tempCustomTo = picked.end;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.date_range, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              _tempCustomFrom != null && _tempCustomTo != null
                                  ? _formatCustomRangeLabel(_tempCustomFrom!, _tempCustomTo!)
                                  : 'Select Date Range',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _tempCustomFrom != null ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_tempCustomFrom != null && _tempCustomTo != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            final start = DateTime(
                              _tempCustomFrom!.year,
                              _tempCustomFrom!.month,
                              _tempCustomFrom!.day,
                              0, 0, 0,
                            );
                            final end = DateTime(
                              _tempCustomTo!.year,
                              _tempCustomTo!.month,
                              _tempCustomTo!.day,
                              23, 59, 59, 999,
                            );
                            _applyDateFilter(
                              start,
                              end,
                              _formatCustomRangeLabel(start, end),
                            );
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],

                  if (_selectedDateFrom != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          _applyDateFilter(null, null, null);
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Clear Date Filter', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _applySearch(String value) {
    final notifier = ref.read(transactionProvider.notifier);
    notifier.applyFilters(
      ref.read(transactionProvider).filters.copyWith(search: value, clearSearch: value.isEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(transactionProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    final hasDateFilter = state.filters.dateFrom != null || state.filters.dateTo != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => ref.read(transactionProvider.notifier).fetch(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Text('Transactions', style: Theme.of(context).textTheme.headlineSmall),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(hasDateFilter ? 146 : 100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        controller: _searchController,
                        onChanged: _applySearch,
                        decoration: InputDecoration(
                          hintText: 'Search merchant...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applySearch('');
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Filter chips row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _isIgnoredFilter == null,
                              onTap: () {
                                setState(() => _isIgnoredFilter = null);
                                ref.read(transactionProvider.notifier).applyFilters(
                                  state.filters.copyWith(clearIgnored: true),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Active',
                              selected: _isIgnoredFilter == false,
                              onTap: () {
                                setState(() => _isIgnoredFilter = false);
                                ref.read(transactionProvider.notifier).applyFilters(
                                  state.filters.copyWith(isIgnored: false),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Ignored',
                              selected: _isIgnoredFilter == true,
                              onTap: () {
                                setState(() => _isIgnoredFilter = true);
                                ref.read(transactionProvider.notifier).applyFilters(
                                  state.filters.copyWith(isIgnored: true),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _DateFilterChip(
                              label: state.dateLabel ?? 'Date',
                              isSelected: state.filters.dateFrom != null,
                              onTap: () => _showDateFilterPicker(context),
                              onClear: state.filters.dateFrom != null
                                  ? () => _applyDateFilter(null, null, null)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            _SortFilterChip(
                              sortBy: state.filters.sortBy,
                              sortOrder: state.filters.sortOrder,
                              onSelected: (sortBy, sortOrder) {
                                ref.read(transactionProvider.notifier).applyFilters(
                                  state.filters.copyWith(sortBy: sortBy, sortOrder: sortOrder),
                                );
                              },
                            ),
                            if (categories.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _CategoryFilterChip(
                                categories: categories,
                                selectedId: _categoryFilter,
                                onSelected: (id) {
                                  setState(() => _categoryFilter = id);
                                  ref.read(transactionProvider.notifier).applyFilters(
                                    id == null
                                        ? state.filters.copyWith(clearCategory: true)
                                        : state.filters.copyWith(categoryId: id),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (hasDateFilter) ...[
                        const SizedBox(height: 10),
                        // Summary Widget
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${state.total} Transaction(s)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                CurrencyFormatter.format(state.totalAmount),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            ..._buildTransactionSlivers(state),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTransactionSlivers(TransactionListState state) {
    if (state.isLoading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SkeletonTransactionTile(),
              ),
              childCount: 8,
            ),
          ),
        ),
      ];
    }

    if (state.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.error!, style: const TextStyle(color: AppColors.error)),
                TextButton(
                  onPressed: () => ref.read(transactionProvider.notifier).fetch(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (state.transactions.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textDisabled),
                SizedBox(height: 12),
                Text('No transactions found', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ];
    }

    // ── Group transactions by Mon–Sun week ─────────────────────────────────
    final bool groupByWeek = state.filters.sortBy == 'date';
    final groups = <({String? label, List<TransactionModel> txs})>[];

    if (!groupByWeek) {
      groups.add((label: null, txs: state.transactions));
    } else {
      DateTime? currentMonday;
      var currentGroup = <TransactionModel>[];
      String? currentLabel;

      for (final tx in state.transactions) {
        final monday = _weekStart(tx.transactionDate);
        if (currentMonday == null || monday != currentMonday) {
          if (currentGroup.isNotEmpty) {
            groups.add((label: currentLabel, txs: List.unmodifiable(currentGroup)));
          }
          currentMonday = monday;
          currentLabel = _weekLabel(monday);
          currentGroup = [tx];
        } else {
          currentGroup.add(tx);
        }
      }
      if (currentGroup.isNotEmpty) {
        groups.add((label: currentLabel, txs: List.unmodifiable(currentGroup)));
      }
    }

    final hasMore = state.filters.page < state.totalPages;
    final slivers = <Widget>[
      const SliverPadding(padding: EdgeInsets.only(top: 4)),
    ];

    for (final group in groups) {
      final groupSlivers = <Widget>[];

      if (group.label != null) {
        groupSlivers.add(SliverPersistentHeader(
          pinned: true,
          delegate: _WeekStickyHeaderDelegate(label: group.label!),
        ));
      }

      groupSlivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final tx = group.txs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TransactionCard(
                  transaction: tx,
                  showIgnoreSlide: true,
                  showNotes: true,
                  onIgnoreToggle: (isIgnored) {
                    ref.read(transactionProvider.notifier).updateTransaction(
                      tx.id,
                      isIgnored: isIgnored,
                    );
                  },
                  onCategoryTap: () => _showCategoryPicker(context, tx),
                  onAmountTap: () => _showAmountEditor(context, tx),
                  onDelete: () => _confirmDelete(context, tx),
                ),
              );
            },
            childCount: group.txs.length,
          ),
        ),
      ));

      slivers.add(SliverMainAxisGroup(slivers: groupSlivers));
    }

    if (hasMore) {
      slivers.add(SliverToBoxAdapter(
        child: Builder(builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(transactionProvider.notifier).loadMore();
          });
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }),
      ));
    }

    slivers.add(const SliverPadding(padding: EdgeInsets.only(bottom: 32)));
    return slivers;
  }

  Future<void> _confirmDelete(BuildContext context, TransactionModel tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Transaction'),
        content: Text(
          'Permanently delete "${tx.merchant}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Transaction deleted'),
        backgroundColor: error != null ? AppColors.error : null,
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final merchantController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? selectedCategoryId;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dateLabel =
                "${selectedDate.day} ${_monthShortNames[selectedDate.month - 1]} ${selectedDate.year}";

            Future<void> submit() async {
              final merchant = merchantController.text.trim();
              final amount = int.tryParse(amountController.text);
              if (merchant.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a merchant and a valid amount'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              setModalState(() => submitting = true);
              final error = await ref.read(transactionProvider.notifier).createTransaction(
                    merchant: merchant,
                    amount: amount,
                    date: selectedDate,
                    categoryId: selectedCategoryId,
                    notes: notesController.text.trim(),
                  );
              if (!sheetCtx.mounted) return;
              if (error != null) {
                setModalState(() => submitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: AppColors.error),
                );
                return;
              }
              Navigator.pop(sheetCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction added')),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20, 20, 20,
                20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add Transaction', style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Merchant
                    TextField(
                      controller: merchantController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Merchant',
                        hintText: 'e.g. Starbucks',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amount
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date
                    Text('Date', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                surface: AppColors.surface,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            // Preserve time-of-day so ordering stays stable.
                            selectedDate = DateTime(
                              picked.year, picked.month, picked.day,
                              selectedDate.hour, selectedDate.minute,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(dateLabel, style: const TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                    if (categories.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Category', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CategorySelectChip(
                            label: 'None',
                            selected: selectedCategoryId == null,
                            onTap: () => setModalState(() => selectedCategoryId = null),
                          ),
                          ...categories.map((c) => _CategorySelectChip(
                                label: c.name,
                                color: c.colorValue,
                                selected: selectedCategoryId == c.id,
                                onTap: () => setModalState(() => selectedCategoryId = c.id),
                              )),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Notes (optional)
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting ? null : submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      merchantController.dispose();
      amountController.dispose();
      notesController.dispose();
    });
  }

  void _showCategoryPicker(BuildContext context, TransactionModel tx) {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Category', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(tx.merchant, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ...categories.map((cat) => ListTile(
              leading: CircleAvatar(
                radius: 10,
                backgroundColor: cat.colorValue,
              ),
              title: Text(cat.name),
              trailing: tx.categoryId == cat.id
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                ref.read(transactionProvider.notifier).updateTransaction(
                  tx.id,
                  categoryId: cat.id,
                  categoryName: cat.name,
                  categoryColor: cat.color,
                );
              },
            )),
            ListTile(
              leading: const CircleAvatar(radius: 10, backgroundColor: AppColors.textDisabled),
              title: const Text('Uncategorized'),
              onTap: () {
                Navigator.pop(context);
                ref.read(transactionProvider.notifier).updateTransaction(
                  tx.id,
                  clearCategory: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAmountEditor(BuildContext context, TransactionModel tx) {
    final controller = TextEditingController(text: tx.amount.toString());
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Amount', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(tx.merchant, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                hintText: '0',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final raw = int.tryParse(controller.text);
                  if (raw != null && raw > 0) {
                    Navigator.pop(sheetCtx);
                    ref.read(transactionProvider.notifier).updateTransaction(
                      tx.id,
                      amount: raw,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CategorySelectChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _CategorySelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              CircleAvatar(radius: 6, backgroundColor: color),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final List categories;
  final String? selectedId;
  final void Function(String?) onSelected;

  const _CategoryFilterChip({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Categories'),
                onTap: () { Navigator.pop(context); onSelected(null); },
              ),
              ...categories.map((c) => ListTile(
                leading: CircleAvatar(radius: 8, backgroundColor: c.colorValue),
                title: Text(c.name),
                onTap: () { Navigator.pop(context); onSelected(c.id); },
              )),
            ],
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selectedId != null ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedId != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selectedId != null ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 16,
                color: selectedId != null ? Colors.white : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (isSelected && onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  onClear!();
                },
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ] else ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SortFilterChip extends StatelessWidget {
  final String sortBy;
  final String sortOrder;
  final void Function(String sortBy, String sortOrder) onSelected;

  const _SortFilterChip({
    required this.sortBy,
    required this.sortOrder,
    required this.onSelected,
  });

  String get _label {
    if (sortBy == 'amount') {
      return sortOrder == 'desc' ? 'Highest' : 'Lowest';
    } else {
      return sortOrder == 'desc' ? 'Newest' : 'Oldest';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = !(sortBy == 'date' && sortOrder == 'desc');

    return PopupMenuButton<MapEntry<String, String>>(
      onSelected: (entry) => onSelected(entry.key, entry.value),
      offset: const Offset(0, 40),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: MapEntry('date', 'desc'),
          child: Text('Newest', style: TextStyle(color: AppColors.textPrimary)),
        ),
        const PopupMenuItem(
          value: MapEntry('date', 'asc'),
          child: Text('Oldest', style: TextStyle(color: AppColors.textPrimary)),
        ),
        const PopupMenuItem(
          value: MapEntry('amount', 'desc'),
          child: Text('Highest', style: TextStyle(color: AppColors.textPrimary)),
        ),
        const PopupMenuItem(
          value: MapEntry('amount', 'asc'),
          child: Text('Lowest', style: TextStyle(color: AppColors.textPrimary)),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isCustom ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCustom ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: 12,
              color: isCustom ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isCustom ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isCustom ? Colors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Delegate for the pinned sticky week header in the transactions sliver list.
class _WeekStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;

  const _WeekStickyHeaderDelegate({required this.label});

  static const double _height = 40.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.border.withValues(alpha: 0.8),
              thickness: 1.0,
              endIndent: 10,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
                width: 0.8,
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.border.withValues(alpha: 0.8),
              thickness: 1.0,
              indent: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_WeekStickyHeaderDelegate old) => old.label != label;
}

/// Marker object — kept for compatibility, no longer used in the sliver list.
class _WeekSeparatorItem {
  final String label;
  const _WeekSeparatorItem({required this.label});
}

