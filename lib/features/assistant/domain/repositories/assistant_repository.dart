import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';

abstract interface class AssistantRepository {
  Future<Result<List<AssistantConversation>>> getConversations();
  Future<Result<AssistantThread>> getMessages(String conversationId);
  Future<Result<AssistantSendResponse>> sendMessage({
    required String message,
    String? conversationId,
  });
  Future<Result<void>> deleteConversation(String conversationId);
  void cancelPendingLoads();
}
