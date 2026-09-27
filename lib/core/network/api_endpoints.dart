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

  // Budget & Analytics
  static const String budget = '/budget';
  static const String budgetChart = '/budget/chart';
  static const String budgetDailyChart = '/budget/daily-chart';
  static const String budgetSpendingSummary = '/budget/spending-summary';
  static const String budgetDailySummary = '/budget/daily-summary';
  static const String categoryBreakdown = '/budget/category-breakdown';
  static const String aiSummary = '/budget/ai-summary';
  static const String aiAdvisorChat = '/budget/ai-advisor/chat';

  // AI Categorization
  static String aiCategorize(String id) => '/transactions/$id/ai-categorize';
  static const String aiCategorizeAll = '/transactions/ai-categorize-all';

  // Notifications
  static const String notificationTest = '/notifications/test';
  static const String notificationConfig = '/notifications/config';

  // Alerts
  static const String alerts = '/alerts';
  static const String alertsCount = '/alerts/count';
  static String alertResolve(String id) => '/alerts/$id/resolve';
  static const String alertsResolveAll = '/alerts/resolve-all';
}
