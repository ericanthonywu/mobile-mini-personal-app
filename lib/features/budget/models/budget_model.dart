/// Budget summary model returned by GET /api/budget
class BudgetSummaryModel {
  final BudgetPeriod week;
  final BudgetPeriod month;

  const BudgetSummaryModel({required this.week, required this.month});

  factory BudgetSummaryModel.fromJson(Map<String, dynamic> json) {
    return BudgetSummaryModel(
      week: BudgetPeriod.fromJson(json['week'] as Map<String, dynamic>),
      month: BudgetPeriod.fromJson(json['month'] as Map<String, dynamic>),
    );
  }
}

class BudgetPeriod {
  final DateTime start;
  final DateTime end;
  final int budget;
  final int realSpent;
  final int totalSpent;
  final int remaining;
  final int percentUsed; // 0-100
  final bool isOverBudget;

  const BudgetPeriod({
    required this.start,
    required this.end,
    required this.budget,
    required this.realSpent,
    required this.totalSpent,
    required this.remaining,
    required this.percentUsed,
    required this.isOverBudget,
  });

  /// Amount "saved" = budget - real spent. May be negative if over budget.
  int get savedAmount => budget - realSpent;

  /// Amount tracked but excluded from budget (ignored transactions)
  int get ignoredAmount => totalSpent - realSpent;

  factory BudgetPeriod.fromJson(Map<String, dynamic> json) {
    return BudgetPeriod(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      budget: json['budget'] as int,
      realSpent: json['realSpent'] as int,
      totalSpent: json['totalSpent'] as int,
      remaining: json['remaining'] as int,
      percentUsed: json['percentUsed'] as int,
      isOverBudget: json['isOverBudget'] as bool,
    );
  }
}
