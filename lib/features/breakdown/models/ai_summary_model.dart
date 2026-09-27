class AiSummaryData {
  final String healthScore; // 'healthy', 'caution', 'critical'
  final String summary;
  final List<String> keyInsights;
  final List<String> recommendations;
  final String generatedAt;

  const AiSummaryData({
    required this.healthScore,
    required this.summary,
    required this.keyInsights,
    required this.recommendations,
    required this.generatedAt,
  });

  factory AiSummaryData.fromJson(Map<String, dynamic> json) {
    return AiSummaryData(
      healthScore: json['healthScore'] as String? ?? 'healthy',
      summary: json['summary'] as String? ?? '',
      keyInsights: (json['keyInsights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      generatedAt: json['generatedAt'] as String? ?? '',
    );
  }
}

class AiExpenseSummaryResponse {
  final String period;
  final String label;
  final int totalSpent;
  final int totalCount;
  final AiSummaryData ai;

  const AiExpenseSummaryResponse({
    required this.period,
    required this.label,
    required this.totalSpent,
    required this.totalCount,
    required this.ai,
  });

  factory AiExpenseSummaryResponse.fromJson(Map<String, dynamic> json) {
    return AiExpenseSummaryResponse(
      period: json['period'] as String? ?? 'month',
      label: json['label'] as String? ?? 'Bulan Ini',
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      ai: AiSummaryData.fromJson(json['ai'] as Map<String, dynamic>? ?? {}),
    );
  }
}
