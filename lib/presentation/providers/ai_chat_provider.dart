import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';

import 'package:kingdomcome/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'ai_chat_provider.g.dart';

// ── Chat message model ────────────────────────────────────────────────────────

class ChatMessage {
  final String role; // "user" or "assistant"
  final String content;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

// ── AI gateway URL ────────────────────────────────────────────────────────────

const String _aiGatewayBase = String.fromEnvironment(
  'AI_GATEWAY_URL',
  defaultValue: 'https://kingdom-come-ai-gateway.workers.dev',
);

// ── Notifier ──────────────────────────────────────────────────────────────────

@riverpod
class AiChatNotifier extends _$AiChatNotifier {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  @override
  List<ChatMessage> build() {
    return [];
  }

  /// Sends [message] to the Magisterium AI via the Cloudflare Worker.
  ///
  /// Appends both the user message and the AI reply to state.
  /// On error, appends an error message bubble.
  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Append user message immediately
    state = [
      ...state,
      ChatMessage(
        role: 'user',
        content: trimmed,
        timestamp: DateTime.now(),
      ),
    ];

    try {
      // Get the Supabase JWT for auth with the Worker
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw StateError('No active session');

      final response = await _dio.post(
        '$_aiGatewayBase/chat',
        options: Options(headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        }),
        data: {
          'message': trimmed,
          'ageGroup': user.ageGroup,
          if (_saintSystemPrompt != null) 'systemPrompt': _saintSystemPrompt,
          'history': state
              .take(state.length - 1) // exclude the message we just appended
              .where((m) => !m.isError)
              .take(10) // last 10 turns for context
              .map((m) => m.toJson())
              .toList(),
        },
      );

      final reply = (response.data as Map<String, dynamic>)['reply'] as String;

      state = [
        ...state,
        ChatMessage(
          role: 'assistant',
          content: reply,
          timestamp: DateTime.now(),
        ),
      ];
    } on DioException catch (e) {
      final errorText = _extractErrorText(e);
      state = [
        ...state,
        ChatMessage(
          role: 'assistant',
          content: errorText,
          timestamp: DateTime.now(),
          isError: true,
        ),
      ];
    } catch (e) {
      state = [
        ...state,
        ChatMessage(
          role: 'assistant',
          content:
              'I\'m having trouble connecting right now. Please try again in a moment.',
          timestamp: DateTime.now(),
          isError: true,
        ),
      ];
    }
  }

  /// Clears all messages in the current conversation.
  void clearHistory() {
    state = [];
    _saintSystemPrompt = null;
  }

  // ── Saint persona ─────────────────────────────────────────────────────────

  String? _saintSystemPrompt;

  /// Pre-seeds the AI with a saint character persona for the next conversation.
  ///
  /// After calling this, the next [sendMessage] will use a system prompt that
  /// keeps the AI in character as [saintName].
  void setSaintPersona({
    required String saintName,
    required String saintBio,
    required String patronage,
    required String era,
  }) {
    _saintSystemPrompt =
        'You are $saintName, a Catholic saint from the $era period. '
        'Your patronage includes: $patronage. '
        'Brief context about you: $saintBio. '
        'Respond in first person as $saintName, sharing your wisdom about '
        'Catholic faith, prayer, and virtue. Stay in character but be '
        'age-appropriate and encouraging for children and teenagers ages 8-18. '
        'Draw on your real historical life and writings when possible.';

    // Inject a system-level greeting as first AI message
    final greeting = 'Greetings, young pilgrim! I am $saintName. '
        'How may I share the light of God\'s love with you today?';

    state = [
      ChatMessage(
        role: 'assistant',
        content: greeting,
        timestamp: DateTime.now(),
      ),
    ];
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  String _extractErrorText(DioException e) {
    if (e.response?.statusCode == 429) {
      return 'You\'ve sent a lot of messages today! Come back tomorrow to continue our conversation.';
    }
    if (e.response?.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    return 'I\'m having trouble answering right now. Please try again shortly.';
  }
}

// ── Starter prompts ───────────────────────────────────────────────────────────

/// Pre-built conversation starters shown on the empty state of the chat.
final starterPromptsProvider = Provider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  final ageGroup = user?.ageGroup ?? 2;

  switch (ageGroup) {
    case 1:
      return [
        'Tell me about prayer',
        'Who is Jesus?',
        'What is the Rosary?',
        'Tell me about St. Francis',
        'What is Heaven like?',
      ];
    case 2:
      return [
        'What is the Rosary?',
        'Who is St. Francis of Assisi?',
        'Tell me about the Eucharist',
        'What are the Beatitudes?',
        'Why do we go to Mass?',
      ];
    case 3:
    default:
      return [
        'Explain the theology of the Eucharist',
        'Who are the Church Fathers?',
        'What is Natural Law?',
        'How do we know God exists?',
        'What does the Church teach about social justice?',
      ];
  }
});
