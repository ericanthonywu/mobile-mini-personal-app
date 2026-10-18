import 'package:expense_tracker/features/transactions/models/transaction_model.dart';

/// Available view modes for the expense calendar.
enum CalendarViewMode {
  daily,
  monthly,
  yearly;

  String get label => switch (this) {
    CalendarViewMode.daily => 'Harian',
    CalendarViewMode.monthly => 'Bulanan',
    CalendarViewMode.yearly => 'Tahunan',
  };
}

/// Calendar data model for Daily view ("daily see daily").
class CalendarDailyModel {
  final String mode;
  final String date;
  final int dayOfWeek;
  final String dayName;
  final String formattedDate;
  final int totalSpent;
  final int realSpent;
  final int transactionCount;
  final int monthDailyAverage;
  final int monthTotal;
  final List<TransactionModel> transactions;

  const CalendarDailyModel({
    required this.mode,
    required this.date,
    required this.dayOfWeek,
    required this.dayName,
    required this.formattedDate,
    required this.totalSpent,
    required this.realSpent,
    required this.transactionCount,
    required this.monthDailyAverage,
    required this.monthTotal,
    required this.transactions,
  });

  factory CalendarDailyModel.fromJson(Map<String, dynamic> json) {
    return CalendarDailyModel(
      mode: json['mode'] as String? ?? 'daily',
      date: json['date'] as String? ?? '',
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
      dayName: json['dayName'] as String? ?? '',
      formattedDate: json['formattedDate'] as String? ?? '',
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      realSpent: (json['realSpent'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      monthDailyAverage: (json['monthDailyAverage'] as num?)?.toInt() ?? 0,
      monthTotal: (json['monthTotal'] as num?)?.toInt() ?? 0,
      transactions: (json['transactions'] as List?)
              ?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// A single day entry in the Monthly calendar grid.
class CalendarMonthDay {
  final String date;
  final int day;
  final int dayOfWeek;
  final int totalSpent;
  final int transactionCount;

  const CalendarMonthDay({
    required this.date,
    required this.day,
    required this.dayOfWeek,
    required this.totalSpent,
    required this.transactionCount,
  });

  factory CalendarMonthDay.fromJson(Map<String, dynamic> json) {
    return CalendarMonthDay(
      date: json['date'] as String? ?? '',
      day: (json['day'] as num?)?.toInt() ?? 1,
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Highest spending day info.
class CalendarHighestDay {
  final String date;
  final int day;
  final int amount;

  const CalendarHighestDay({
    required this.date,
    required this.day,
    required this.amount,
  });

  factory CalendarHighestDay.fromJson(Map<String, dynamic> json) {
    return CalendarHighestDay(
      date: json['date'] as String? ?? '',
      day: (json['day'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Calendar data model for Monthly view ("monthly see monthly").
class CalendarMonthlyModel {
  final String mode;
  final int year;
  final int month;
  final String monthName;
  final String formattedMonthYear;
  final int totalSpent;
  final int transactionCount;
  final int activeDays;
  final int elapsedDays;
  final int averageDailySpent;
  final CalendarHighestDay? highestDay;
  final List<CalendarMonthDay> days;
  final List<TransactionModel> transactions;

  const CalendarMonthlyModel({
    required this.mode,
    required this.year,
    required this.month,
    required this.monthName,
    required this.formattedMonthYear,
    required this.totalSpent,
    required this.transactionCount,
    required this.activeDays,
    required this.elapsedDays,
    required this.averageDailySpent,
    this.highestDay,
    required this.days,
    required this.transactions,
  });

  factory CalendarMonthlyModel.fromJson(Map<String, dynamic> json) {
    return CalendarMonthlyModel(
      mode: json['mode'] as String? ?? 'monthly',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      monthName: json['monthName'] as String? ?? '',
      formattedMonthYear: json['formattedMonthYear'] as String? ?? '',
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      activeDays: (json['activeDays'] as num?)?.toInt() ?? 0,
      elapsedDays: (json['elapsedDays'] as num?)?.toInt() ?? 1,
      averageDailySpent: (json['averageDailySpent'] as num?)?.toInt() ?? 0,
      highestDay: json['highestDay'] != null
          ? CalendarHighestDay.fromJson(json['highestDay'] as Map<String, dynamic>)
          : null,
      days: (json['days'] as List?)
              ?.map((e) => CalendarMonthDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      transactions: (json['transactions'] as List?)
              ?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// A single month item in the Yearly view.
class CalendarYearMonth {
  final int month;
  final String monthName;
  final String shortName;
  final int totalSpent;
  final int transactionCount;
  final int diffFromAvg;
  final double ratioToAvg;

  const CalendarYearMonth({
    required this.month,
    required this.monthName,
    required this.shortName,
    required this.totalSpent,
    required this.transactionCount,
    required this.diffFromAvg,
    required this.ratioToAvg,
  });

  factory CalendarYearMonth.fromJson(Map<String, dynamic> json) {
    return CalendarYearMonth(
      month: (json['month'] as num?)?.toInt() ?? 1,
      monthName: json['monthName'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      diffFromAvg: (json['diffFromAvg'] as num?)?.toInt() ?? 0,
      ratioToAvg: (json['ratioToAvg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Highest/lowest month descriptor in Yearly view.
class CalendarMonthExtreme {
  final int month;
  final String monthName;
  final int amount;

  const CalendarMonthExtreme({
    required this.month,
    required this.monthName,
    required this.amount,
  });

  factory CalendarMonthExtreme.fromJson(Map<String, dynamic> json) {
    return CalendarMonthExtreme(
      month: (json['month'] as num?)?.toInt() ?? 1,
      monthName: json['monthName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Calendar data model for Yearly view ("yearly see avg monthly").
class CalendarYearlyModel {
  final String mode;
  final int year;
  final int totalSpent;
  final int transactionCount;
  final int elapsedMonths;
  final int averageMonthlySpent;
  final CalendarMonthExtreme? highestMonth;
  final CalendarMonthExtreme? lowestMonth;
  final List<CalendarYearMonth> months;

  const CalendarYearlyModel({
    required this.mode,
    required this.year,
    required this.totalSpent,
    required this.transactionCount,
    required this.elapsedMonths,
    required this.averageMonthlySpent,
    this.highestMonth,
    this.lowestMonth,
    required this.months,
  });

  factory CalendarYearlyModel.fromJson(Map<String, dynamic> json) {
    return CalendarYearlyModel(
      mode: json['mode'] as String? ?? 'yearly',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      elapsedMonths: (json['elapsedMonths'] as num?)?.toInt() ?? 1,
      averageMonthlySpent: (json['averageMonthlySpent'] as num?)?.toInt() ?? 0,
      highestMonth: json['highestMonth'] != null
          ? CalendarMonthExtreme.fromJson(json['highestMonth'] as Map<String, dynamic>)
          : null,
      lowestMonth: json['lowestMonth'] != null
          ? CalendarMonthExtreme.fromJson(json['lowestMonth'] as Map<String, dynamic>)
          : null,
      months: (json['months'] as List?)
              ?.map((e) => CalendarYearMonth.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
