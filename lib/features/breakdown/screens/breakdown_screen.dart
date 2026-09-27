import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/breakdown/models/breakdown_model.dart';
import 'package:expense_tracker/features/breakdown/models/ai_summary_model.dart';
import 'package:expense_tracker/features/breakdown/providers/breakdown_provider.dart';
import 'package:expense_tracker/features/transactions/providers/transaction_provider.dart';
import 'package:expense_tracker/shared/widgets/app_skeleton.dart';

class BreakdownScreen extends ConsumerStatefulWidget {
  const BreakdownScreen({super.key});

  @override
  ConsumerState<BreakdownScreen> createState() => _BreakdownScreenState();
}

class _BreakdownScreenState extends ConsumerState<BreakdownScreen> {
  int _touchedIndex = -1;
  bool _isSummaryExpanded = false;

  final List<({String key, String label})> _periods = const [
    (key: 'week', label: 'Minggu Ini'),
    (key: 'month', label: 'Bulan Ini'),
    (key: 'last_month', label: 'Bulan Lalu'),
    (key: '3_months', label: '3 Bulan'),
    (key: 'all', label: 'Semua'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(selectedBreakdownPeriodProvider);
    final breakdownAsync = ref.watch(categoryBreakdownProvider(selectedPeriod));
    final aiSummaryAsync = ref.watch(aiSummaryProvider(selectedPeriod));
    final aiCatState = ref.watch(aiCategorizationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Breakdown Pengeluaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Analisis Kategori & AI Summary',
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
            tooltip: 'Kategorikan Transaksi dengan AI',
            icon: aiCatState.isCategorizing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.aiPurple,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, color: AppColors.aiPurple),
            onPressed: aiCatState.isCategorizing
                ? null
                : () => _handleAiCategorizeAll(context),
          ),
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(categoryBreakdownProvider(selectedPeriod));
              ref.invalidate(aiSummaryProvider(selectedPeriod));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(categoryBreakdownProvider(selectedPeriod));
          ref.invalidate(aiSummaryProvider(selectedPeriod));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Period Selector Pills
            SliverToBoxAdapter(
              child: _buildPeriodSelector(selectedPeriod),
            ),

            // AI Status Notification Bar (if active action)
            if (aiCatState.successMessage != null || aiCatState.errorMessage != null)
              SliverToBoxAdapter(
                child: _buildActionFeedbackBanner(aiCatState),
              ),

            // AI Summary Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildAiSummaryCard(aiSummaryAsync, selectedPeriod),
              ),
            ),

            // Breakdown Content (Chart & List)
            breakdownAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: AppSkeleton(height: 350, borderRadius: 20),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: _buildErrorCard(err.toString(), selectedPeriod),
              ),
              data: (data) => _buildBreakdownContent(data),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 48),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Period Selector Pill Bar
  // ---------------------------------------------------------------------------
  Widget _buildPeriodSelector(String currentPeriod) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = _periods[index];
          final isSelected = p.key == currentPeriod;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(selectedBreakdownPeriodProvider.notifier).state = p.key;
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.pillBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Feedback Banner
  // ---------------------------------------------------------------------------
  Widget _buildActionFeedbackBanner(AiCategorizationState state) {
    final isError = state.errorMessage != null;
    final message = isError ? state.errorMessage! : state.successMessage!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? AppColors.error : AppColors.success,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 18,
            color: isError ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isError ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI Summary Card
  // ---------------------------------------------------------------------------
  Widget _buildAiSummaryCard(
      AsyncValue<AiExpenseSummaryResponse> aiAsync, String selectedPeriod) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.aiPurple.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiPurple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: aiAsync.when(
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.aiPurple, size: 20),
                SizedBox(width: 8),
                Text(
                  'Menganalisis data pengeluaran dengan AI...',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            SizedBox(height: 12),
            AppSkeleton(height: 50, borderRadius: 8),
          ],
        ),
        error: (err, _) => Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'AI Summary belum tersedia untuk periode ini.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(aiSummaryProvider(selectedPeriod)),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
        data: (resp) {
          final ai = resp.ai;
          final (badgeColor, badgeText, badgeIcon) = switch (ai.healthScore) {
            'critical' => (
                AppColors.error,
                'Waspada Anggaran',
                Icons.warning_amber_rounded
              ),
            'caution' => (
                AppColors.warning,
                'Perlu Pengawasan',
                Icons.error_outline_rounded
              ),
            _ => (
                AppColors.success,
                'Keuangan Terkendali',
                Icons.check_circle_outline_rounded
              ),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.aiGradientStart,
                              AppColors.aiGradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AI Financial Intelligence',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  // Health badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: badgeColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 12, color: badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Summary narrative
              Text(
                ai.summary,
                maxLines: _isSummaryExpanded ? null : 3,
                overflow: _isSummaryExpanded ? null : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isSummaryExpanded = !_isSummaryExpanded;
                    });
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    _isSummaryExpanded ? 'Tutup Narasi' : 'Selengkapnya',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ),

              // Key Insights
              if (ai.keyInsights.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Text(
                  'Sorotan Penting:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ...ai.keyInsights.map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.trending_up_rounded,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Recommendations (if expanded)
              if (_isSummaryExpanded && ai.recommendations.isNotEmpty) ...[
                const Divider(color: AppColors.divider, height: 20),
                const Text(
                  '💡 Rekomendasi Penghematan:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ...ai.recommendations.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Breakdown Content: Chart + Categories List
  // ---------------------------------------------------------------------------
  Widget _buildBreakdownContent(CategoryBreakdownResponse data) {
    if (data.categories.isEmpty && data.totalSpent == 0) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  size: 48, color: AppColors.textDisabled),
              const SizedBox(height: 12),
              const Text(
                'Belum ada transaksi pada periode ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Transaksi BCA yang tercatat akan otomatis dikelompokkan ke dalam kategori.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // Uncategorized Alert Banner (if any)
        if (data.uncategorizedCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _buildUncategorizedAlert(data),
          ),

        // Interactive Donut Chart Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildChartCard(data),
        ),

        // Detailed Category Ranked Breakdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildRankedCategoryList(data),
        ),

        // Top 5 Merchants
        if (data.topMerchants.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildTopMerchantsCard(data.topMerchants),
          ),
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // Uncategorized Warning Callout
  // ---------------------------------------------------------------------------
  Widget _buildUncategorizedAlert(CategoryBreakdownResponse data) {
    final aiState = ref.watch(aiCategorizationProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline_rounded,
                color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.uncategorizedCount} Transaksi Tanpa Kategori',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total: ${CurrencyFormatter.format(data.uncategorizedSpent)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: aiState.isCategorizing
                ? null
                : () => _handleAiCategorizeAll(context),
            icon: aiState.isCategorizing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 14),
            label: const Text(
              'AI Auto',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interactive Donut Chart Card
  // ---------------------------------------------------------------------------
  Widget _buildChartCard(CategoryBreakdownResponse data) {
    final activeItem = (_touchedIndex >= 0 && _touchedIndex < data.categories.length)
        ? data.categories[_touchedIndex]
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distribusi Pengeluaran',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Donut Chart Container
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 65,
                    sections: List.generate(data.categories.length, (i) {
                      final cat = data.categories[i];
                      final isTouched = i == _touchedIndex;
                      final radius = isTouched ? 36.0 : 28.0;

                      return PieChartSectionData(
                        color: cat.color,
                        value: cat.totalAmount.toDouble(),
                        title: isTouched ? '${cat.percentage}%' : '',
                        radius: radius,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),

                // Center Donut Text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeItem != null
                          ? activeItem.categoryName
                          : 'Total Belanja',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: activeItem != null
                            ? activeItem.color
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.compact(
                        activeItem != null
                            ? activeItem.totalAmount
                            : data.totalSpent,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (activeItem != null)
                      Text(
                        '${activeItem.percentage}% • ${activeItem.transactionCount} tx',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Legend preview chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: data.categories.map((c) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${c.categoryName} (${c.percentage}%)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ranked Category List
  // ---------------------------------------------------------------------------
  Widget _buildRankedCategoryList(CategoryBreakdownResponse data) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rincian per Kategori',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${data.categories.length} Kategori',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.categories.length,
            separatorBuilder: (_, __) => const Divider(
              color: AppColors.divider,
              height: 24,
            ),
            itemBuilder: (context, index) {
              final cat = data.categories[index];
              final rank = index + 1;

              return InkWell(
                onTap: () => _showCategoryTransactionsSheet(context, cat),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Rank badge
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.pillBackground,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '$rank',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Color indicator
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Category Name & tx count
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.categoryName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${cat.transactionCount} transaksi • Rata-rata ${CurrencyFormatter.compact(cat.averageAmount)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Amount & Percentage
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(cat.totalAmount),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${cat.percentage}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cat.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Progress bar showing category share
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (cat.percentage / 100).clamp(0.0, 1.0),
                          backgroundColor: AppColors.pillBackground,
                          valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                          minHeight: 6,
                        ),
                      ),
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

  // ---------------------------------------------------------------------------
  // Top Merchants Card
  // ---------------------------------------------------------------------------
  Widget _buildTopMerchantsCard(List<TopMerchantItem> merchants) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded,
                  color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Top Merchant Pengeluaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...merchants.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(
                    '#${idx + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDisabled,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.merchant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${m.count} transaksi',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(m.totalSpent),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Sheet for Category Details
  // ---------------------------------------------------------------------------
  void _showCategoryTransactionsSheet(
      BuildContext context, CategoryBreakdownItem category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.categoryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Total Belanja',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(category.totalAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Frekuensi',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${category.transactionCount} kali',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Porsi Anggaran',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${category.percentage}%',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: category.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Apply category filter to transactions screen
                      ref.read(transactionProvider.notifier).applyFilters(
                            TransactionFilters(
                              categoryId: category.categoryId,
                            ),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Filter diterapkan: ${category.categoryName} di tab Transaksi'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text(
                      'Lihat Semua Transaksi di Tab Transaksi',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------
  Future<void> _handleAiCategorizeAll(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final count =
        await ref.read(aiCategorizationProvider.notifier).categorizeAll();

    if (!context.mounted) return;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Berhasil mengkategorikan $count transaksi dengan AI!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _buildErrorCard(String error, String selectedPeriod) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          Text(
            'Gagal memuat rincian kategori: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(categoryBreakdownProvider(selectedPeriod)),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
