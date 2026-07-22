import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/budget/models/spending_summary_model.dart';
import 'package:expense_tracker/features/dashboard/providers/spending_summary_provider.dart';
import 'package:expense_tracker/features/dashboard/models/daily_chart_model.dart';
import 'package:expense_tracker/features/dashboard/providers/daily_chart_provider.dart';
import 'dart:math' as math;

/// Interactive spending summary chart featuring 3 view modes:
/// 1. Daily — Filter by Year, Month, & Week (Mon–Sun daily breakdown)
/// 2. Weekly — Filter by Year & Month (Week 1, 2, 3, 4 breakdown)
/// 3. Monthly — Filter by Year (Jan–Dec breakdown)
class SpendingSummaryChart extends ConsumerStatefulWidget {
  const SpendingSummaryChart({super.key});

  @override
  ConsumerState<SpendingSummaryChart> createState() =>
      _SpendingSummaryChartState();
}

class _SpendingSummaryChartState extends ConsumerState<SpendingSummaryChart>
    with SingleTickerProviderStateMixin {
  /// View mode: 'daily', 'weekly', 'monthly'
  String _mode = 'daily';

  late int _selectedYear;
  late int _selectedMonth;
  int? _selectedWeek; // null = defaults to first/current week

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  
  double _weekScrollOffset = 0.0;

  static const List<String> _monthShortNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  bool get _canGoNextMonth {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    if (_selectedYear < now.year) return true;
    if (_selectedYear == now.year && _selectedMonth < now.month) return true;
    return false;
  }

  bool get _canGoNextYear {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return _selectedYear < now.year;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    _selectedYear = now.year;
    _selectedMonth = now.month;
    // Auto-select today's week number (Mon–Sun, 1-based within the month)
    _selectedWeek = _currentWeekNumber(now);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  /// Computes the 1-based Mon–Sun week number within the month for [date],
  /// using the same logic as the backend / filter sheet.
  static int _currentWeekNumber(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstDow = firstDayOfMonth.weekday; // 1=Mon
    final daysToMonday = firstDow - 1;
    final firstMonday = firstDayOfMonth.subtract(Duration(days: daysToMonday));
    final today = DateTime(date.year, date.month, date.day);
    return ((today.difference(firstMonday).inDays) ~/ 7) + 1;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _switchMode(String mode) {
    if (_mode == mode) return;
    HapticFeedback.selectionClick();
    setState(() => _mode = mode);
    _fadeController
      ..reset()
      ..forward();
  }

  void _changeMonth(int delta) {
    HapticFeedback.selectionClick();
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    setState(() {
      int newMonth = _selectedMonth + delta;
      if (newMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else if (newMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth = newMonth;
      }
      // Auto-select today's week when returning to current month, else reset
      if (_selectedYear == now.year && _selectedMonth == now.month) {
        _selectedWeek = _currentWeekNumber(now);
      } else {
        _selectedWeek = null;
      }
      _weekScrollOffset = 0.0;
    });
    _fadeController
      ..reset()
      ..forward();
  }

  void _changeYear(int delta) {
    HapticFeedback.selectionClick();
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    setState(() {
      _selectedYear += delta;
      // Auto-select today's week when landing on current year+month
      if (_selectedYear == now.year && _selectedMonth == now.month) {
        _selectedWeek = _currentWeekNumber(now);
      } else {
        _selectedWeek = null;
      }
      _weekScrollOffset = 0.0;
    });
    _fadeController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              // Mode toggle (Daily | Weekly | Monthly)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ModeTab(
                      label: 'Daily',
                      selected: _mode == 'daily',
                      onTap: () => _switchMode('daily'),
                    ),
                    _ModeTab(
                      label: 'Weekly',
                      selected: _mode == 'weekly',
                      onTap: () => _switchMode('weekly'),
                    ),
                    _ModeTab(
                      label: 'Monthly',
                      selected: _mode == 'monthly',
                      onTap: () => _switchMode('monthly'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Filter Controls ──────────────────────────────────────────────
          if (_mode == 'daily' || _mode == 'weekly') ...[
            Row(
              children: [
                // Month & Year navigator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        '${_monthShortNames[_selectedMonth - 1]} $_selectedYear',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded, 
                          size: 18,
                          color: _canGoNextMonth ? AppColors.textPrimary : AppColors.textDisabled,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: _canGoNextMonth ? () => _changeMonth(1) : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ] else ...[
            // Year navigator for Monthly mode
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => _changeYear(-1),
                      ),
                      Text(
                        '$_selectedYear',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded, 
                          size: 18,
                          color: _canGoNextYear ? AppColors.textPrimary : AppColors.textDisabled,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: _canGoNextYear ? () => _changeYear(1) : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // ── Chart Content ────────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnimation,
            child: _mode == 'daily'
                ? _buildDailyChartContent()
                : _buildSummaryChartContent(),
          ),
        ],
      ),
    );
  }

  // ── Daily Mode (Filtered by Week) ─────────────────────────────────────────
  Widget _buildDailyChartContent() {
    final params = DailyChartParams(
      year: _selectedYear,
      month: _selectedMonth,
      week: _selectedWeek,
    );
    final async = ref.watch(dailyChartProvider(params));

    return async.when(
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Failed to load daily spending',
            style: TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ),
      ),
      data: (data) => _DailyChartWidget(
        data: data,
        selectedWeek: _selectedWeek,
        initialScrollOffset: _weekScrollOffset,
        onScrollOffsetChanged: (offset) {
          _weekScrollOffset = offset;
        },
        onWeekSelected: (week) {
          HapticFeedback.selectionClick();
          setState(() => _selectedWeek = week);
        },
      ),
    );
  }

  // ── Weekly / Monthly Modes ──────────────────────────────────────────────
  Widget _buildSummaryChartContent() {
    final params = SpendingSummaryParams(
      mode: _mode == 'weekly' ? 'week' : 'month',
      year: _selectedYear,
      month: _mode == 'weekly' ? _selectedMonth : null,
    );
    final async = ref.watch(spendingSummaryProvider(params));

    return async.when(
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Failed to load summary',
            style: TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ),
      ),
      data: (summary) => _SummaryBarChart(summary: summary),
    );
  }
}

// ── Daily Chart View (Filtered by Week) ─────────────────────────────────────
class _DailyChartWidget extends StatefulWidget {
  final DailyChartModel data;
  final int? selectedWeek;
  final double initialScrollOffset;
  final ValueChanged<double> onScrollOffsetChanged;
  final ValueChanged<int> onWeekSelected;

  const _DailyChartWidget({
    required this.data,
    required this.selectedWeek,
    required this.initialScrollOffset,
    required this.onScrollOffsetChanged,
    required this.onWeekSelected,
  });

  @override
  State<_DailyChartWidget> createState() => _DailyChartWidgetState();
}

class _DailyChartWidgetState extends State<_DailyChartWidget> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: widget.initialScrollOffset);
    _scrollController.addListener(() {
      widget.onScrollOffsetChanged(_scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatWeekLabel(DailyChartWeekInfo info) {
    if (info.startDate.isEmpty || info.endDate.isEmpty) return 'Week ${info.week}';
    final s = DateTime.tryParse(info.startDate);
    final e = DateTime.tryParse(info.endDate);
    if (s != null && e != null) {
      return 'W${info.week} (${DateFormatter.short(s)} - ${DateFormatter.short(e)})';
    }
    return 'Week ${info.week}';
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.data.days;
    final budget = widget.data.budget;

    // Check if all days zero
    final totalReal = days.fold<int>(0, (sum, d) => sum + d.realSpent);

    final maxY = days.fold<double>(
      budget.toDouble() > 0 ? budget.toDouble() * 1.15 : 100.0,
      (prev, e) => e.realSpent.toDouble() > prev ? e.realSpent.toDouble() * 1.15 : prev,
    );

    double calculateNiceInterval(double maxVal) {
      if (maxVal <= 0) return 1.0;
      final targetInterval = maxVal / 4;
      final magnitude = math.pow(10, (math.log(targetInterval) / math.ln10).floor()).toDouble();
      final fraction = targetInterval / magnitude;
      
      double niceFraction;
      if (fraction <= 1.0) niceFraction = 1.0;
      else if (fraction <= 2.5) niceFraction = 2.5;
      else if (fraction <= 5.0) niceFraction = 5.0;
      else niceFraction = 10.0;
      
      return niceFraction * magnitude;
    }

    final interval = calculateNiceInterval(maxY);

    final wibNow = DateTime.now().toUtc().add(const Duration(hours: 7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Week selector pills ──────────────────────────────────────────
        if (widget.data.availableWeeks.isNotEmpty) ...[
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: widget.data.availableWeeks.map((w) {
                bool isFuture = false;
                if (w.startDate.isNotEmpty) {
                  final start = DateTime.tryParse(w.startDate);
                  if (start != null) {
                    isFuture = start.isAfter(wibNow);
                  }
                }
                
                final isSelected = (widget.selectedWeek ?? widget.data.week) == w.week;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _formatWeekLabel(w),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isFuture 
                            ? AppColors.textDisabled 
                            : (isSelected ? Colors.white : AppColors.textSecondary),
                      ),
                    ),
                    selected: isSelected && !isFuture,
                    selectedColor: AppColors.primary,
                    backgroundColor: isFuture 
                        ? AppColors.surfaceVariant.withValues(alpha: 0.5) 
                        : AppColors.surfaceVariant,
                    side: BorderSide(
                      color: isFuture
                          ? AppColors.border.withValues(alpha: 0.2)
                          : (isSelected
                              ? AppColors.primary
                              : AppColors.border.withValues(alpha: 0.5)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onSelected: isFuture ? null : (_) => widget.onWeekSelected(w.week),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Week Date Subtitle & Spending Total ──────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Week ${widget.data.week} Spending',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              CurrencyFormatter.format(totalReal),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Daily Bar Chart (Mon - Sun) ──────────────────────────────────
        if (days.isEmpty)
          const SizedBox(
            height: 160,
            child: Center(child: Text('No daily data for this week')),
          )
        else
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: interval,
                      getTitlesWidget: (val, _) => Text(
                        CurrencyFormatter.compact(val.toInt()),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                        final d = DateTime.tryParse(days[idx].date);
                        final label = d != null ? DateFormatter.dayName(d) : 'Day';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: days.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final day = entry.value;
                  final color = AppColors.primary;

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: day.realSpent.toDouble(),
                        color: color,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.surfaceVariant,
                        ),
                      ),
                    ],
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceHighlight,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = days[groupIndex];
                      final dt = DateTime.tryParse(day.date);
                      final dayStr = dt != null ? DateFormatter.short(dt) : day.date;
                      return BarTooltipItem(
                        '$dayStr\n${CurrencyFormatter.format(day.realSpent)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Summary Bar Chart (Weekly / Monthly) ───────────────────────────────────
class _SummaryBarChart extends StatelessWidget {
  final SpendingSummaryModel summary;

  const _SummaryBarChart({required this.summary});

  @override
  Widget build(BuildContext context) {
    final entries = summary.entries;
    final isWeekly = summary.mode == 'week';
    final budget = summary.budget;

    final wibNow = DateTime.now().toUtc().add(const Duration(hours: 7));
    
    // Filter out future entries
    final validEntries = entries.where((e) {
      if (!isWeekly || e.startDate == null || e.startDate!.isEmpty) {
        // For monthly mode, we could filter future months, but usually year is blocked.
        if (!isWeekly) {
          if (summary.year > wibNow.year) return false;
          if (summary.year == wibNow.year && e.index > wibNow.month) return false;
        }
        return true;
      }
      final start = DateTime.tryParse(e.startDate!);
      if (start == null) return true;
      return !start.isAfter(wibNow);
    }).toList();

    final hasData = validEntries.any((e) => e.realSpent > 0);

    if (!hasData) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart_rounded, size: 36, color: AppColors.textDisabled),
              const SizedBox(height: 8),
              Text(
                'No spending recorded for this period',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final maxY = validEntries.fold<double>(
      budget.toDouble() > 0 ? budget.toDouble() * 1.15 : 100.0,
      (prev, e) => e.realSpent.toDouble() > prev ? e.realSpent.toDouble() * 1.15 : prev,
    );

    double calculateNiceInterval(double maxVal) {
      if (maxVal <= 0) return 1.0;
      final targetInterval = maxVal / 4;
      final magnitude = math.pow(10, (math.log(targetInterval) / math.ln10).floor()).toDouble();
      final fraction = targetInterval / magnitude;
      
      double niceFraction;
      if (fraction <= 1.0) niceFraction = 1.0;
      else if (fraction <= 2.5) niceFraction = 2.5;
      else if (fraction <= 5.0) niceFraction = 5.0;
      else niceFraction = 10.0;
      
      return niceFraction * magnitude;
    }

    final interval = calculateNiceInterval(maxY);

    final barGroups = validEntries.map((e) {
      final isOver = e.realSpent > budget;
      final color = isOver ? AppColors.error : AppColors.primary;
      final idx = validEntries.indexOf(e);

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: e.realSpent.toDouble(),
            color: color,
            width: isWeekly ? 32 : 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: AppColors.surfaceVariant,
            ),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceHighlight,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < 0 || groupIndex >= validEntries.length) return null;
                final entry = validEntries[groupIndex];
                final isOver = entry.realSpent > budget;
                final label = isWeekly
                    ? 'Week ${entry.index}'
                    : _monthName(entry.index);

                return BarTooltipItem(
                  '$label\n${CurrencyFormatter.compact(entry.realSpent)}',
                  TextStyle(
                    color: isOver ? AppColors.error : AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: interval,
                getTitlesWidget: (val, _) => Text(
                  CurrencyFormatter.compact(val.toInt()),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= validEntries.length) {
                    return const SizedBox.shrink();
                  }
                  final label = isWeekly
                      ? 'W${validEntries[idx].index}'
                      : _monthAbbr(validEntries[idx].index);
                  return Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textDisabled,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.border,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  static String _monthName(int m) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m >= 1 && m <= 12 ? names[m] : '';
  }

  static String _monthAbbr(int m) {
    const abbrs = ['', 'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return m >= 1 && m <= 12 ? abbrs[m] : '';
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
