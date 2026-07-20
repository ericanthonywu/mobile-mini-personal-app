import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/budget/models/budget_model.dart';

/// Expense chart showing cumulative daily spending vs budget baseline.
/// - Main line: real spending (non-ignored), turns red when over budget.
/// - Gray dashed line: total spending (incl. ignored), hidden by default.
/// - Red dashed baseline: budget limit.
class ExpenseChart extends StatefulWidget {
  final BudgetChartModel chart;

  const ExpenseChart({super.key, required this.chart});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart>
    with TickerProviderStateMixin {
  bool _isWeekly = true;

  // Fade animation for chart period switch
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // Fade animation for total line toggle
  late final AnimationController _totalLineController;
  late final Animation<double> _totalLineAnimation;
  bool _showTotal = false; // hidden by default

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _totalLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _totalLineAnimation = CurvedAnimation(
      parent: _totalLineController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _totalLineController.dispose();
    super.dispose();
  }

  void _switchPeriod(bool weekly) {
    if (_isWeekly == weekly) return;
    HapticFeedback.selectionClick();
    setState(() => _isWeekly = weekly);
    _fadeController
      ..reset()
      ..forward();
  }

  void _toggleTotal() {
    setState(() => _showTotal = !_showTotal);
    if (_showTotal) {
      _totalLineController.forward();
    } else {
      _totalLineController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = _isWeekly ? widget.chart.weekly : widget.chart.monthly;
    final days = period.days;
    final budget = period.budget;

    // Build cumulative spending
    final realPoints = <FlSpot>[];
    final totalPoints = <FlSpot>[];
    int realCumulative = 0;
    int totalCumulative = 0;

    for (int i = 0; i < days.length; i++) {
      realCumulative += days[i].realSpent;
      totalCumulative += days[i].totalSpent;
      realPoints.add(FlSpot(i.toDouble(), realCumulative.toDouble()));
      totalPoints.add(FlSpot(i.toDouble(), totalCumulative.toDouble()));
    }

    if (realPoints.isEmpty) {
      realPoints.add(const FlSpot(0, 0));
      totalPoints.add(const FlSpot(0, 0));
    }

    final isOverBudget = realCumulative > budget;
    final lineColor = isOverBudget ? AppColors.error : AppColors.primary;
    final fillColor = isOverBudget ? AppColors.error : AppColors.primary;

    final effectiveMax = _showTotal
        ? totalCumulative.toDouble()
        : realCumulative.toDouble();

    // Smart maxY: when spending is very low relative to budget, avoid crushing
    // the line to the bottom. Use whichever is larger: budget*1.15 OR
    // actual*3 (gives room to rise), with a minimum of 1.0 to avoid
    // division-by-zero in the chart.
    final double maxY = [
      budget.toDouble() * 0.4,   // at least 40% of budget so line has room
      effectiveMax * 1.3,         // 30% headroom above actual spending
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    // Date range subtitle
    String periodSubtitle = '';
    if (days.isNotEmpty) {
      final first = DateTime.tryParse(days.first.date);
      final last = DateTime.tryParse(days.last.date);
      if (first != null && last != null) {
        periodSubtitle = '${DateFormatter.short(first)} – ${DateFormatter.short(last)}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverBudget
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Chart',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  if (periodSubtitle.isNotEmpty)
                    Text(
                      periodSubtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Status badge
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOverBudget
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOverBudget
                              ? Icons.trending_up_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 10,
                          color: isOverBudget ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOverBudget
                              // Bug fix: was showing budget amount, now shows overage
                              ? 'Over limit by ${CurrencyFormatter.compact(realCumulative - budget)}'
                              : '${CurrencyFormatter.compact(realCumulative)} / ${CurrencyFormatter.compact(budget)}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isOverBudget ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Period toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PeriodTab(
                      label: 'Week',
                      selected: _isWeekly,
                      onTap: () => _switchPeriod(true),
                    ),
                    _PeriodTab(
                      label: 'Month',
                      selected: !_isWeekly,
                      onTap: () => _switchPeriod(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Legend row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(
                color: lineColor,
                label: 'Actual Spent',
                dashed: false,
              ),
              // Tappable total line toggle
              GestureDetector(
                onTap: _toggleTotal,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showTotal
                        ? AppColors.textDisabled.withValues(alpha: 0.12)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showTotal
                          ? AppColors.textDisabled.withValues(alpha: 0.4)
                          : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _showTotal
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_outlined,
                          key: ValueKey(_showTotal),
                          size: 11,
                          color: _showTotal
                              ? AppColors.textDisabled
                              : AppColors.textDisabled.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _LegendItem(
                        color: AppColors.textDisabled.withValues(alpha: _showTotal ? 1 : 0.4),
                        label: 'Incl. ignored',
                        dashed: true,
                      ),
                    ],
                  ),
                ),
              ),
              _LegendItem(
                color: AppColors.error,
                label: 'Limit',
                dashed: true,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Chart
          FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedBuilder(
              animation: _totalLineAnimation,
              builder: (context, _) {
                final totalOpacity = _totalLineAnimation.value;

                // Guard interval against zero budget (prevents infinite grid lines)
                final gridInterval = budget > 0 ? (budget / 4).toDouble() : maxY / 4;
                final leftInterval = budget > 0 ? (budget / 2).toDouble() : maxY / 2;

                return SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (days.length - 1).toDouble().clamp(1, double.infinity),
                      minY: 0,
                      maxY: maxY,
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: gridInterval,
                        getDrawingHorizontalLine: (_) => FlLine(
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
                            interval: leftInterval,
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
                            interval: _isWeekly
                                ? 1
                                : (days.length / 6).ceilToDouble(),
                            getTitlesWidget: (val, _) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= days.length) {
                                return const SizedBox.shrink();
                              }
                              final dateStr = days[idx].date;
                              final parts = dateStr.split('-');
                              if (parts.length < 3) return const SizedBox.shrink();
                              final label = _isWeekly
                                  ? _dayAbbr(DateTime.parse(dateStr).weekday)
                                  : parts[2];
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
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: budget.toDouble(),
                            color: AppColors.error.withValues(alpha: 0.75),
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.only(right: 4, bottom: 2),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                              labelResolver: (_) =>
                                  CurrencyFormatter.compact(budget),
                            ),
                          ),
                        ],
                      ),
                      lineBarsData: [
                        // Gray dashed total line (animated opacity via color)
                        if (totalOpacity > 0)
                          LineChartBarData(
                            spots: totalPoints,
                            isCurved: true,
                            curveSmoothness: 0.3,
                            color: AppColors.textDisabled.withValues(alpha: totalOpacity * 0.8),
                            barWidth: 1.5,
                            dashArray: [5, 4],
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        // Primary real spending line (color-aware)
                        LineChartBarData(
                          spots: realPoints,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: lineColor,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              if (index != realPoints.length - 1) {
                                return FlDotCirclePainter(
                                  radius: 0,
                                  color: Colors.transparent,
                                );
                              }
                              return FlDotCirclePainter(
                                radius: 5,
                                color: lineColor,
                                strokeColor: AppColors.surface,
                                strokeWidth: 2,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                fillColor.withValues(alpha: 0.22),
                                fillColor.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceHighlight,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              // With conditional total line, barIndex 0 could be
                              // total (when shown) or real (when total hidden).
                              final isRealLine = totalOpacity == 0
                                  ? spot.barIndex == 0
                                  : spot.barIndex == 1;
                              return LineTooltipItem(
                                CurrencyFormatter.compact(spot.y.toInt()),
                                TextStyle(
                                  color: isRealLine
                                      ? lineColor
                                      : AppColors.textDisabled,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _dayAbbr(int weekday) {
    const abbrs = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekday < abbrs.length ? abbrs[weekday] : '';
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem(
      {required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 12,
          child: CustomPaint(
            painter: _LinePainter(color: color, dashed: dashed),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: color.withValues(alpha: color.a < 0.5 ? 0.5 : 1.0),
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool dashed;

  _LinePainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = dashed ? 1.5 : 2.5
      ..strokeCap = StrokeCap.round;

    if (!dashed) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    } else {
      const dashWidth = 3.5;
      const gap = 2.5;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, size.height / 2),
          Offset((x + dashWidth).clamp(0, size.width), size.height / 2),
          paint,
        );
        x += dashWidth + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.color != color || old.dashed != dashed;
}
