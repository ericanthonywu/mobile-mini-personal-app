import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/calendar/models/calendar_model.dart';
import 'package:expense_tracker/features/calendar/providers/calendar_provider.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/providers/transaction_provider.dart';
import 'package:expense_tracker/shared/widgets/app_skeleton.dart';
import 'package:expense_tracker/shared/widgets/app_error_widget.dart';
import 'package:expense_tracker/shared/widgets/transaction_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const List<String> _dayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  static const List<String> _weekDayLabels = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
  ];

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<String> _monthShortNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  String _formatDateKey(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  void _refreshCurrentView() {
    HapticFeedback.lightImpact();
    final mode = ref.read(selectedCalendarModeProvider);
    switch (mode) {
      case CalendarViewMode.daily:
        final date = ref.read(selectedCalendarDateProvider);
        ref.invalidate(calendarDailyProvider(_formatDateKey(date)));
        break;
      case CalendarViewMode.monthly:
        final y = ref.read(selectedCalendarYearProvider);
        final m = ref.read(selectedCalendarMonthProvider);
        ref.invalidate(calendarMonthlyProvider((year: y, month: m)));
        break;
      case CalendarViewMode.yearly:
        final y = ref.read(selectedCalendarYearProvider);
        ref.invalidate(calendarYearlyProvider(y));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(selectedCalendarModeProvider);
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Kembali',
              )
            : null,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kalender Pengeluaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Harian, Bulanan & Rata-rata Tahunan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshCurrentView,
            tooltip: 'Segarkan',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Segmented View Mode Switcher: Daily | Monthly | Yearly
          _buildModeSwitcher(mode),

          // Main View Content
          Expanded(
            child: switch (mode) {
              CalendarViewMode.daily => _buildDailyView(),
              CalendarViewMode.monthly => _buildMonthlyView(),
              CalendarViewMode.yearly => _buildYearlyView(),
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Segmented Mode Switcher (Daily, Monthly, Yearly)
  // ---------------------------------------------------------------------------
  Widget _buildModeSwitcher(CalendarViewMode activeMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: CalendarViewMode.values.map((mode) {
          final isSelected = mode == activeMode;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(selectedCalendarModeProvider.notifier).state = mode;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  mode.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // 1. DAILY VIEW ("daily see daily")
  // ===========================================================================
  Widget _buildDailyView() {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final dateKey = _formatDateKey(selectedDate);
    final dailyAsync = ref.watch(calendarDailyProvider(dateKey));

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(calendarDailyProvider(dateKey));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // Day navigation bar
          _buildDayNavBar(selectedDate, isToday),
          const SizedBox(height: 12),

          dailyAsync.when(
            loading: () => const Column(
              children: [
                AppSkeleton(height: 140, borderRadius: 18),
                SizedBox(height: 16),
                AppSkeleton(height: 70, borderRadius: 14),
                SizedBox(height: 10),
                AppSkeleton(height: 70, borderRadius: 14),
              ],
            ),
            error: (err, _) => AppErrorWidget(
              error: err,
              onRetry: () => ref.invalidate(calendarDailyProvider(dateKey)),
            ),
            data: (daily) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero card showing daily total expense
                _buildDailyHeroCard(daily, isToday),
                const SizedBox(height: 20),

                // Transactions on this day
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Hari Ini (${daily.transactionCount})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (daily.transactionCount > 0)
                      TextButton.icon(
                        onPressed: () {
                          // Jump to Transaksi screen with date filter
                          final from = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
                          final to = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59, 999);
                          final label = daily.formattedDate;
                          ref.read(transactionProvider.notifier).applyFilters(
                            ref.read(transactionProvider).filters.copyWith(
                              dateFrom: from,
                              dateTo: to,
                              isIgnored: false,
                            ),
                            dateLabel: label,
                          );
                          context.go('/transactions');
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 13),
                        label: const Text('Buka di Transaksi'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (daily.transactions.isEmpty)
                  _buildEmptyDayCard()
                else
                  ...daily.transactions.map((tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TransactionCard(
                          transaction: tx,
                          onIgnoreToggle: null, // Read-only in calendar
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayNavBar(DateTime selectedDate, bool isToday) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(selectedCalendarDateProvider.notifier).state =
                  selectedDate.subtract(const Duration(days: 1));
            },
            tooltip: 'Hari Sebelumnya',
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
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
                ref.read(selectedCalendarDateProvider.notifier).state = picked;
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    '${_dayNames[selectedDate.weekday - 1]}, ${selectedDate.day} ${_monthShortNames[selectedDate.month - 1]} ${selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              if (!isToday)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedCalendarDateProvider.notifier).state = DateTime.now();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryLight, width: 0.8),
                    ),
                    child: const Text(
                      'Hari Ini',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(selectedCalendarDateProvider.notifier).state =
                      selectedDate.add(const Duration(days: 1));
                },
                tooltip: 'Hari Berikutnya',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyHeroCard(CalendarDailyModel daily, bool isToday) {
    final diffFromAvg = daily.totalSpent - daily.monthDailyAverage;
    final isAboveAvg = diffFromAvg > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: daily.totalSpent > 0 ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
        ),
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            daily.totalSpent > 0
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceVariant.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.today_rounded, size: 16, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isToday ? 'Pengeluaran Hari Ini' : 'Pengeluaran Harian',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${daily.transactionCount} Transaksi',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            CurrencyFormatter.format(daily.totalSpent),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                daily.totalSpent == 0
                    ? Icons.celebration_rounded
                    : (isAboveAvg ? Icons.trending_up_rounded : Icons.trending_down_rounded),
                size: 16,
                color: daily.totalSpent == 0
                    ? AppColors.success
                    : (isAboveAvg ? AppColors.warning : AppColors.success),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  daily.totalSpent == 0
                      ? 'Hari bebas pengeluaran! Rata-rata harian bulan ini: ${CurrencyFormatter.compact(daily.monthDailyAverage)}'
                      : (isAboveAvg
                          ? '+${CurrencyFormatter.compact(diffFromAvg)} dari rata-rata harian (${CurrencyFormatter.compact(daily.monthDailyAverage)})'
                          : '${CurrencyFormatter.compact(diffFromAvg.abs())} lebih hemat dari rata-rata harian (${CurrencyFormatter.compact(daily.monthDailyAverage)})'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: daily.totalSpent == 0
                        ? AppColors.success
                        : (isAboveAvg ? AppColors.warning : AppColors.success),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available_rounded, size: 44, color: AppColors.textDisabled),
          SizedBox(height: 12),
          Text(
            'Tidak Ada Pengeluaran',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tidak ada transaksi yang tercatat pada tanggal ini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. MONTHLY VIEW ("monthly see monthly")
  // ===========================================================================
  Widget _buildMonthlyView() {
    final year = ref.watch(selectedCalendarYearProvider);
    final month = ref.watch(selectedCalendarMonthProvider);
    final selectedGridDay = ref.watch(selectedCalendarGridDayProvider);
    final monthlyAsync = ref.watch(calendarMonthlyProvider((year: year, month: month)));

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(calendarMonthlyProvider((year: year, month: month)));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // Month navigation bar
          _buildMonthNavBar(year, month),
          const SizedBox(height: 12),

          monthlyAsync.when(
            loading: () => const Column(
              children: [
                AppSkeleton(height: 120, borderRadius: 18),
                SizedBox(height: 16),
                AppSkeleton(height: 280, borderRadius: 20),
              ],
            ),
            error: (err, _) => AppErrorWidget(
              error: err,
              onRetry: () => ref.invalidate(calendarMonthlyProvider((year: year, month: month))),
            ),
            data: (monthly) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month summary hero card ("monthly see monthly")
                _buildMonthHeroCard(monthly),
                const SizedBox(height: 16),

                // Month Calendar Grid Card
                _buildMonthCalendarGrid(monthly, selectedGridDay),
                const SizedBox(height: 20),

                // Selected Day Transaction Details
                _buildSelectedDayDetail(monthly, selectedGridDay),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavBar(int year, int month) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
            onPressed: () {
              HapticFeedback.selectionClick();
              if (month == 1) {
                ref.read(selectedCalendarMonthProvider.notifier).state = 12;
                ref.read(selectedCalendarYearProvider.notifier).state = year - 1;
              } else {
                ref.read(selectedCalendarMonthProvider.notifier).state = month - 1;
              }
              ref.read(selectedCalendarGridDayProvider.notifier).state = null;
            },
            tooltip: 'Bulan Sebelumnya',
          ),
          Text(
            '${_monthNames[month - 1]} $year',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
            onPressed: () {
              HapticFeedback.selectionClick();
              if (month == 12) {
                ref.read(selectedCalendarMonthProvider.notifier).state = 1;
                ref.read(selectedCalendarYearProvider.notifier).state = year + 1;
              } else {
                ref.read(selectedCalendarMonthProvider.notifier).state = month + 1;
              }
              ref.read(selectedCalendarGridDayProvider.notifier).state = null;
            },
            tooltip: 'Bulan Berikutnya',
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeroCard(CalendarMonthlyModel monthly) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Bulan ${monthly.monthName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${monthly.transactionCount} Transaksi',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(monthly.totalSpent),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // 3 Metrics: Rata-rata harian, Hari aktif, Hari tertinggi
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  label: 'Rata-rata / Hari',
                  value: CurrencyFormatter.compact(monthly.averageDailySpent),
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  label: 'Hari Aktif',
                  value: '${monthly.activeDays} hari',
                  icon: Icons.event_repeat_rounded,
                  iconColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  label: 'Hari Tertinggi',
                  value: monthly.highestDay != null
                      ? 'Tgl ${monthly.highestDay!.day} (${CurrencyFormatter.compact(monthly.highestDay!.amount)})'
                      : '-',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendarGrid(CalendarMonthlyModel monthly, String? selectedGridDay) {
    if (monthly.days.isEmpty) return const SizedBox.shrink();

    // The first day's weekday (1 = Monday, ..., 7 = Sunday)
    final firstDayOfWeek = monthly.days.first.dayOfWeek;
    final leadingEmptyCells = firstDayOfWeek - 1; // 0 for Monday

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Weekday header row (Sen, Sel, Rab, Kam, Jum, Sab, Min)
          Row(
            children: _weekDayLabels.map((lbl) {
              final isWeekend = lbl == 'Sab' || lbl == 'Min';
              return Expanded(
                child: Center(
                  child: Text(
                    lbl,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isWeekend ? AppColors.secondary : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmptyCells + monthly.days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 6,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyCells) {
                return const SizedBox.shrink(); // empty padding cell
              }

              final dayItem = monthly.days[index - leadingEmptyCells];
              final isSelected = dayItem.date == selectedGridDay;
              final isCurrentToday = dayItem.date == todayStr;
              final hasExpense = dayItem.totalSpent > 0;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(selectedCalendarGridDayProvider.notifier).state =
                      isSelected ? null : dayItem.date;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : (hasExpense
                            ? AppColors.surfaceVariant
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryLight
                          : (isCurrentToday
                              ? AppColors.secondary
                              : (hasExpense ? AppColors.border : Colors.transparent)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Day Number & Today indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${dayItem.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrentToday || isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isCurrentToday
                                      ? AppColors.secondary
                                      : (hasExpense
                                          ? AppColors.textPrimary
                                          : AppColors.textDisabled)),
                            ),
                          ),
                          if (isCurrentToday) ...[
                            const SizedBox(width: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Spending badge / compact amount
                      if (hasExpense)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            CurrencyFormatter.compact(dayItem.totalSpent),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.primaryLight,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetail(CalendarMonthlyModel monthly, String? selectedGridDay) {
    if (selectedGridDay == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.touch_app_rounded, size: 20, color: AppColors.secondary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ketuk salah satu tanggal di kalender untuk melihat daftar transaksinya.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    // Filter transactions on that day
    final dayTxs = monthly.transactions.where((tx) {
      final txDateStr = DateFormat('yyyy-MM-dd').format(tx.transactionDate);
      return txDateStr == selectedGridDay;
    }).toList();

    final dayTotal = dayTxs.fold<int>(0, (sum, tx) => sum + tx.netAmount);
    final parsedDate = DateTime.tryParse(selectedGridDay) ?? DateTime.now();
    final formattedDay = '${parsedDate.day} ${_monthNames[parsedDate.month - 1]} ${parsedDate.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDay,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total: ${CurrencyFormatter.format(dayTotal)} • ${dayTxs.length} Transaksi',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  // Switch to Daily view for this date
                  ref.read(selectedCalendarDateProvider.notifier).state = parsedDate;
                  ref.read(selectedCalendarModeProvider.notifier).state = CalendarViewMode.daily;
                },
                icon: const Icon(Icons.open_in_full_rounded, size: 12),
                label: const Text('Mode Harian', style: TextStyle(fontSize: 11)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),

          if (dayTxs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Tidak ada transaksi pada tanggal ini.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...dayTxs.map((tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransactionCard(
                    transaction: tx,
                    onIgnoreToggle: null,
                  ),
                )),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. YEARLY VIEW ("yearly see avg monthly")
  // ===========================================================================
  Widget _buildYearlyView() {
    final year = ref.watch(selectedCalendarYearProvider);
    final yearlyAsync = ref.watch(calendarYearlyProvider(year));

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(calendarYearlyProvider(year));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // Year navigation bar
          _buildYearNavBar(year),
          const SizedBox(height: 12),

          yearlyAsync.when(
            loading: () => const Column(
              children: [
                AppSkeleton(height: 150, borderRadius: 20),
                SizedBox(height: 16),
                AppSkeleton(height: 250, borderRadius: 18),
              ],
            ),
            error: (err, _) => AppErrorWidget(
              error: err,
              onRetry: () => ref.invalidate(calendarYearlyProvider(year)),
            ),
            data: (yearly) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prominent Hero Card for Avg Monthly ("yearly see avg monthly")
                _buildYearlyHeroCard(yearly),
                const SizedBox(height: 20),

                // 12-Month Expense Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rincian Pengeluaran 12 Bulan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Ketuk bulan untuk detail',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 12 months grid / list
                ...yearly.months.map((m) => _buildYearMonthTile(yearly, m)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearNavBar(int year) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(selectedCalendarYearProvider.notifier).state = year - 1;
            },
            tooltip: 'Tahun Sebelumnya',
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                'Tahun $year',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(selectedCalendarYearProvider.notifier).state = year + 1;
            },
            tooltip: 'Tahun Berikutnya',
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyHeroCard(CalendarYearlyModel yearly) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4), width: 1.2),
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.secondary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Badge & Title: "yearly see avg monthly"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.analytics_rounded, size: 16, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Rata-rata Pengeluaran Bulanan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary, width: 0.8),
                ),
                child: const Text(
                  'AVG MONTHLY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big prominent average monthly amount!
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.format(yearly.averageMonthlySpent),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/ bulan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dihitung dari total ${CurrencyFormatter.compact(yearly.totalSpent)} dibagi ${yearly.elapsedMonths} bulan.',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),

          // Secondary metrics: Total Tahunan, Bulan Tertinggi, Bulan Terhemat
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  label: 'Total Setahun',
                  value: CurrencyFormatter.compact(yearly.totalSpent),
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  label: 'Bulan Tertinggi',
                  value: yearly.highestMonth != null
                      ? '${yearly.highestMonth!.monthName.substring(0, 3)} (${CurrencyFormatter.compact(yearly.highestMonth!.amount)})'
                      : '-',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  label: 'Bulan Terhemat',
                  value: yearly.lowestMonth != null
                      ? '${yearly.lowestMonth!.monthName.substring(0, 3)} (${CurrencyFormatter.compact(yearly.lowestMonth!.amount)})'
                      : '-',
                  icon: Icons.trending_down_rounded,
                  iconColor: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearMonthTile(CalendarYearlyModel yearly, CalendarYearMonth m) {
    final avg = yearly.averageMonthlySpent;
    final ratio = avg > 0 ? (m.totalSpent / avg).clamp(0.0, 2.0) : 0.0;
    final isAboveAvg = m.diffFromAvg > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Jump directly to Monthly mode for this month!
            HapticFeedback.selectionClick();
            ref.read(selectedCalendarMonthProvider.notifier).state = m.month;
            ref.read(selectedCalendarModeProvider.notifier).state = CalendarViewMode.monthly;
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: m.totalSpent > 0 ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: m.totalSpent > 0
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            m.shortName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: m.totalSpent > 0
                                  ? AppColors.primaryLight
                                  : AppColors.textDisabled,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.monthName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${m.transactionCount} Transaksi',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(m.totalSpent),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: m.totalSpent > 0
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (m.totalSpent > 0 && avg > 0)
                          Row(
                            children: [
                              Icon(
                                isAboveAvg
                                    ? Icons.arrow_drop_up_rounded
                                    : Icons.arrow_drop_down_rounded,
                                size: 16,
                                color: isAboveAvg ? AppColors.warning : AppColors.success,
                              ),
                              Text(
                                isAboveAvg
                                    ? '+${CurrencyFormatter.compact(m.diffFromAvg)}'
                                    : '-${CurrencyFormatter.compact(m.diffFromAvg.abs())}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isAboveAvg ? AppColors.warning : AppColors.success,
                                ),
                              ),
                            ],
                          )
                        else
                          const Text(
                            '-',
                            style: TextStyle(fontSize: 10, color: AppColors.textDisabled),
                          ),
                      ],
                    ),
                  ],
                ),
                if (m.totalSpent > 0 && avg > 0) ...[
                  const SizedBox(height: 10),
                  // Progress bar showing month spend relative to avg
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (ratio / 1.5).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isAboveAvg ? AppColors.warning : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
