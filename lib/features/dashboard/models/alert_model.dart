/// Model for a backend parse-failure alert.
class AlertModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> metadata;
  final bool isResolved;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.metadata,
    required this.isResolved,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
        id: json['id'] as String,
        type: (json['type'] as String?) ?? 'parse_failure',
        title: (json['title'] as String?) ?? '',
        message: (json['message'] as String?) ?? '',
        metadata: (json['metadata'] is Map<String, dynamic>)
            ? json['metadata'] as Map<String, dynamic>
            : const {},
        isResolved: (json['is_resolved'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
