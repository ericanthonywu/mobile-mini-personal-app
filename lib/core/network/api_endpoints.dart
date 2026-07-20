/// All API endpoint paths used by the app.
/// Keeps URL strings centralized — no hardcoded paths in providers.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';

  // Poll
  static const String poll = '/poll';

  // Transactions
  static const String transactions = '/transactions';
  static const String transactionsRecent = '/transactions/recent';
  static String transactionById(String id) => '/transactions/$id';

  // Categories
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';

  // Merchant rules
  static const String merchantRules = '/merchant-rules';
  static String merchantRuleById(String id) => '/merchant-rules/$id';

  // Budget
  static const String budget = '/budget';
  static const String budgetChart = '/budget/chart';
  static const String budgetDailyChart = '/budget/daily-chart';
  static const String budgetSpendingSummary = '/budget/spending-summary';
  static const String budgetDailySummary = '/budget/daily-summary';

  // Alerts
  static const String alerts = '/alerts';
  static const String alertsCount = '/alerts/count';
  static String alertResolve(String id) => '/alerts/$id/resolve';
  static const String alertsResolveAll = '/alerts/resolve-all';
}
