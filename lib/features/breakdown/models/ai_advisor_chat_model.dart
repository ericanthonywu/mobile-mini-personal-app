class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final List<String> suggestions;
  final DateTime timestamp;
  final bool isPending;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.suggestions = const [],
    required this.timestamp,
    this.isPending = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    List<String>? suggestions,
    DateTime? timestamp,
    bool? isPending,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      suggestions: suggestions ?? this.suggestions,
      timestamp: timestamp ?? this.timestamp,
      isPending: isPending ?? this.isPending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isPending: json['isPending'] as bool? ?? false,
    );
  }
}

class AiAdvisorChatResponse {
  final String reply;
  final List<String> suggestions;
  final DateTime timestamp;

  const AiAdvisorChatResponse({
    required this.reply,
    required this.suggestions,
    required this.timestamp,
  });

  factory AiAdvisorChatResponse.fromJson(Map<String, dynamic> json) {
    return AiAdvisorChatResponse(
      reply: json['reply'] as String? ?? '',
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
