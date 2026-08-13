import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/assistant/data/data_sources/assistant_remote_data_source.dart';
import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';
import 'package:look_atlas/features/assistant/domain/repositories/assistant_repository.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  const AssistantRepositoryImpl(this._remote);

  final AssistantRemoteDataSource _remote;

  @override
  Future<Result<List<AssistantConversation>>> getConversations() =>
      _remote.getConversations();

  @override
  Future<Result<AssistantThread>> getMessages(String conversationId) =>
      _remote.getMessages(conversationId);

  @override
  Future<Result<AssistantSendResponse>> sendMessage({
    required String message,
    String? conversationId,
  }) => _remote.sendMessage(message: message, conversationId: conversationId);

  @override
  Future<Result<void>> deleteConversation(String conversationId) =>
      _remote.deleteConversation(conversationId);

  @override
  void cancelPendingLoads() => _remote.cancelPendingLoads();
}
