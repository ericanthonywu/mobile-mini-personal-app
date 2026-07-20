import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/budget/models/spending_summary_model.dart';
import 'package:expense_tracker/features/dashboard/providers/spending_summary_provider.dart';

/// Bar chart showing per-week or per-month spending vs budget.
/// - Weekly mode: filterable by year + month
/// - Monthly mode: filterable by year only
class SpendingSummaryChart extends ConsumerStatefulWidget {
  const SpendingSummaryChart({super.key});

  @override
  ConsumerState<SpendingSummaryChart> createState() =>
      _SpendingSummaryChartState();
}

class _SpendingSummaryChartState extends ConsumerState<SpendingSummaryChart>
    with SingleTickerProviderStateMixin {
  bool _isWeekly = true;

  late int _selectedYear;
  late int _selectedMonth;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _switchMode(bool weekly) {
    if (_isWeekly == weekly) return;
    setState(() => _isWeekly = weekly);
    _fadeController
      ..reset()
      ..forward();
  }

  SpendingSummaryParams get _params => SpendingSummaryParams(
        mode: _isWeekly ? 'week' : 'month',
        year: _selectedYear,
        month: _isWeekly ? _selectedMonth : null,
      );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(spendingSummaryProvider(_params));

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
          // ── Header ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Pengeluaran',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              // Mode toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ModeTab(
                      label: 'Mingguan',
                      selected: _isWeekly,
                      onTap: () => _switchMode(true),
                    ),
                    _ModeTab(
                      label: 'Bulanan',
                      selected: !_isWeekly,
                      onTap: () => _switchMode(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Filter row ──────────────────────────────────────────────────
          Row(
            children: [
              if (_isWeekly) ...[
                _FilterChip(
                  label: _monthName(_selectedMonth),
                  onTap: () => _pickMonth(context),
                ),
                const SizedBox(width: 8),
              ],
              _FilterChip(
                label: _selectedYear.toString(),
                onTap: () => _pickYear(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Chart area ──────────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnimation,
            child: async.when(
              loading: () => _SkeletonBar(),
              error: (_, __) => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Gagal memuat data',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              data: (summary) => _BarChartContent(
                summary: summary,
                isWeekly: _isWeekly,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<void> _pickMonth(BuildContext context) async {
    final months = List.generate(12, (i) => i + 1);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickerSheet(
        title: 'Pilih Bulan',
        items: months.map((m) => _monthName(m)).toList(),
        selectedIndex: _selectedMonth - 1,
        onSelect: (i) {
          setState(() => _selectedMonth = i + 1);
          _fadeController
            ..reset()
            ..forward();
        },
      ),
    );
  }

  Future<void> _pickYear(BuildContext context) async {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickerSheet(
        title: 'Pilih Tahun',
        items: years.map((y) => y.toString()).toList(),
        selectedIndex: years.indexOf(_selectedYear),
        onSelect: (i) {
          setState(() => _selectedYear = years[i]);
          _fadeController
            ..reset()
            ..forward();
        },
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return m >= 1 && m <= 12 ? names[m] : '';
  }
}

// ── Bar chart content ─────────────────────────────────────────────────────────

class _BarChartContent extends StatelessWidget {
  final SpendingSummaryModel summary;
  final bool isWeekly;

  const _BarChartContent({required this.summary, required this.isWeekly});

  @override
  Widget build(BuildContext context) {
    final entries = summary.entries;
    final budget = summary.budget;

    if (entries.isEmpty || entries.every((e) => e.realSpent == 0)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 40, color: AppColors.textDisabled),
              const SizedBox(height: 8),
              Text(
                'Belum ada pengeluaran',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final maxY = entries.fold<double>(
      budget.toDouble() * 1.15,
      (prev, e) => e.realSpent.toDouble() > prev ? e.realSpent.toDouble() * 1.1 : prev,
    );

    final barGroups = entries.map((e) {
      final isOver = e.realSpent > budget;
      final color = isOver ? AppColors.error : AppColors.primary;
      final idx = e.index - 1; // 0-indexed for the chart

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          children: [
            _Dot(color: AppColors.primary),
            const SizedBox(width: 4),
            Text('Di bawah anggaran',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            _Dot(color: AppColors.error),
            const SizedBox(width: 4),
            Text('Melebihi anggaran',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceHighlight,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final e = entries[group.x];
                    String label;
                    if (isWeekly) {
                      // Show date range if available (cross-month weeks make this essential)
                      if (e.startDate != null && e.endDate != null) {
                        final start = DateTime.parse(e.startDate!);
                        final end = DateTime.parse(e.endDate!);
                        label = 'W${e.index}: ${_formatShortDate(start)} – ${_formatShortDate(end)}';
                      } else {
                        label = 'Minggu ${e.index}';
                      }
                    } else {
                      label = _shortMonth(e.index);
                    }
                    return BarTooltipItem(
                      '$label\n${CurrencyFormatter.compact(e.realSpent)}',
                      const TextStyle(
                        color: AppColors.textPrimary,
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
                    interval: budget / 2,
                    getTitlesWidget: (val, _) => Text(
                      CurrencyFormatter.compact(val.toInt()),
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textDisabled),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (val, _) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      final e = entries[idx];
                      final label = isWeekly
                          ? 'W${e.index}'
                          : _shortMonth(e.index);
                      return Text(
                        label,
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textDisabled),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: budget / 2,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.border,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
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
                      labelResolver: (_) => CurrencyFormatter.compact(budget),
                    ),
                  ),
                ],
              ),
              barGroups: barGroups,
              alignment: BarChartAlignment.spaceAround,
            ),
          ),
        ),
      ],
    );
  }

  String _shortMonth(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return m >= 1 && m <= 12 ? names[m] : '';
  }

  String _formatShortDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day} ${months[d.month]}';
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ── Picker bottom sheet ────────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final int selectedIndex;
  final void Function(int) onSelect;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            ...List.generate(items.length, (i) {
              final selected = i == selectedIndex;
              return ListTile(
                dense: true,
                title: Text(
                  items[i],
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 18)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(i);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
