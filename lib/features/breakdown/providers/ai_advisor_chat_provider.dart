import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/breakdown/models/ai_advisor_chat_model.dart';
import 'package:expense_tracker/features/breakdown/providers/breakdown_provider.dart';

class AiAdvisorChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final List<String> suggestions;

  const AiAdvisorChatState({
    required this.messages,
    this.isLoading = false,
    this.errorMessage,
    required this.suggestions,
  });

  AiAdvisorChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    List<String>? suggestions,
  }) {
    return AiAdvisorChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class AiAdvisorChatNotifier extends StateNotifier<AiAdvisorChatState> {
  final Ref _ref;

  static const List<String> defaultSuggestions = [
    'Bagaimana kondisi budget saya bulan ini?',
    'Kategori apa yang paling banyak pengeluarannya?',
    'Tips menghemat pengeluaran kategori Food',
    'Merchant apa yang paling sering saya kunjungi?',
  ];

  AiAdvisorChatNotifier(this._ref)
      : super(
          AiAdvisorChatState(
            messages: [
              ChatMessage(
                id: 'welcome',
                role: 'assistant',
                content:
                    'Halo Eric! Saya **AI Financial Advisor** pribadimu. Saya terhubung langsung dengan data transaksi kartu kredit BCA dan anggaranmu.\n\nKamu bisa bertanya apa saja seputar pengeluaran, evaluasi budget, atau strategi penghematan. Ada yang ingin kamu diskusikan?',
                suggestions: defaultSuggestions,
                timestamp: DateTime.now(),
              ),
            ],
            suggestions: defaultSuggestions,
          ),
        );

  /// Send user message to AI Advisor
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMessage = ChatMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now(),
    );

    final pendingAssistantMessage = ChatMessage(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      role: 'assistant',
      content: '',
      isPending: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, pendingAssistantMessage],
      isLoading: true,
      errorMessage: null,
    );

    try {
      // Build conversation history excluding welcome and pending
      final history = state.messages
          .where((m) => m.id != 'welcome' && !m.isPending && m != userMessage)
          .map((m) => m.toJson())
          .toList();

      final currentPeriod = _ref.read(selectedBreakdownPeriodProvider);

      final response = await ApiClient.instance.post(
        ApiEndpoints.aiAdvisorChat,
        data: {
          'message': trimmed,
          'history': history,
          'period': currentPeriod,
        },
      );

      final chatResponse = AiAdvisorChatResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      final finalAssistantMessage = ChatMessage(
        id: 'a_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: chatResponse.reply,
        suggestions: chatResponse.suggestions,
        timestamp: chatResponse.timestamp,
        isPending: false,
      );

      final updatedMessages = state.messages
          .where((m) => !m.isPending)
          .toList()
        ..add(finalAssistantMessage);

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        suggestions: chatResponse.suggestions.isNotEmpty
            ? chatResponse.suggestions
            : defaultSuggestions,
      );
    } catch (e) {
      final errorAssistantMessage = ChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content:
            'Maaf Eric, terjadi kendala saat menganalisis datamu. Pastikan koneksi internet aktif dan silakan coba lagi.',
        timestamp: DateTime.now(),
        isPending: false,
      );

      final updatedMessages = state.messages
          .where((m) => !m.isPending)
          .toList()
        ..add(errorAssistantMessage);

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        errorMessage: 'Gagal terhubung dengan AI Advisor',
      );
    }
  }

  /// Reset chat history to initial state
  void clearChat() {
    state = AiAdvisorChatState(
      messages: [
        ChatMessage(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          content:
              'Percakapan telah direset. Ada hal lain seputar keuangan atau budget yang ingin kamu tanyakan?',
          suggestions: defaultSuggestions,
          timestamp: DateTime.now(),
        ),
      ],
      suggestions: defaultSuggestions,
      isLoading: false,
      errorMessage: null,
    );
  }
}

final aiAdvisorChatProvider =
    StateNotifierProvider<AiAdvisorChatNotifier, AiAdvisorChatState>((ref) {
  return AiAdvisorChatNotifier(ref);
});
