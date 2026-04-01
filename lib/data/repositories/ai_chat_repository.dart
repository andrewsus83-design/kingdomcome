import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failure.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _systemPrompt = '''
You are a helpful Catholic AI assistant for children aged 8–18.
Only discuss Catholic faith, prayer, saints, scripture, and moral guidance.
Use age-appropriate language. Be encouraging, warm, and faithful to the
Magisterium of the Catholic Church. Never discuss inappropriate topics,
violence, secular entertainment, or anything unrelated to the Catholic faith.
When uncertain about a theological question, recommend consulting a priest
or the Catechism of the Catholic Church.
''';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class AiChatRepository {
  /// Sends [message] from [userId] to the Magisterium AI via the Cloudflare
  /// Worker proxy. [conversationHistory] contains prior turns as
  /// `[{"role": "user"|"assistant", "content": "..."}]`.
  ///
  /// Returns the assistant's reply text.
  Future<Either<Failure, String>> sendMessage(
    String userId,
    String message,
    List<Map<String, String>> conversationHistory,
  );
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class AiChatRepositoryImpl implements AiChatRepository {
  AiChatRepositoryImpl({
    required Dio dio,
    required String cloudflareWorkerUrl,
  })  : _dio = dio,
        _workerUrl = cloudflareWorkerUrl;

  final Dio _dio;
  final String _workerUrl;

  @override
  Future<Either<Failure, String>> sendMessage(
    String userId,
    String message,
    List<Map<String, String>> conversationHistory,
  ) async {
    try {
      // Build full message list: system + history + new user message.
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        ...conversationHistory,
        {'role': 'user', 'content': message},
      ];

      final response = await _dio.post<Map<String, dynamic>>(
        '$_workerUrl/chat',
        data: {
          'user_id': userId,
          'messages': messages,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data;
      if (data == null) {
        return const Left(
          GameFailure(message: 'AI chat: empty response from proxy.'),
        );
      }

      // The Cloudflare Worker returns { "reply": "..." }
      final reply = data['reply'] as String?;
      if (reply == null || reply.isEmpty) {
        return const Left(
          GameFailure(message: 'AI chat: no reply in response.'),
        );
      }

      return Right(reply);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return const Left(
          TimeoutFailure(),
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        return const Left(NoConnectionFailure());
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 429) {
        return const Left(
          GameFailure(
            message:
                'You have sent too many messages. Please wait a moment.',
            code: 'rate_limited',
          ),
        );
      }
      if (statusCode == 403) {
        return const Left(
          GameFailure(
            message: 'AI chat access denied.',
            code: 'forbidden',
          ),
        );
      }
      final errMsg = e.response?.data?.toString() ?? e.message ?? e.toString();
      return Left(GameFailure(message: 'AI chat error: $errMsg'));
    } catch (e) {
      return Left(GameFailure(message: e.toString()));
    }
  }
}
