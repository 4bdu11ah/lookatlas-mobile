import 'package:dio/dio.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/assistant/data/models/assistant_dto.dart';
import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';

abstract interface class AssistantRemoteDataSource {
  Future<Result<List<AssistantConversation>>> getConversations();
  Future<Result<AssistantThread>> getMessages(String conversationId);
  Future<Result<AssistantSendResponse>> sendMessage({
    required String message,
    String? conversationId,
  });
  Future<Result<void>> deleteConversation(String conversationId);
  void cancelPendingLoads();
}

class AssistantRemoteDataSourceImpl implements AssistantRemoteDataSource {
  AssistantRemoteDataSourceImpl(this._api);

  final ApiService _api;
  CancelToken? _conversationLoad;
  CancelToken? _messageLoad;

  @override
  Future<Result<List<AssistantConversation>>> getConversations() {
    _conversationLoad?.cancel();
    final token = CancelToken();
    _conversationLoad = token;
    return _api.get<List<AssistantConversation>>(
      ApiEndpoints.assistantConversations,
      cancelToken: token,
      decoder: AssistantDto.conversations,
    );
  }

  @override
  Future<Result<AssistantThread>> getMessages(String conversationId) {
    _messageLoad?.cancel();
    final token = CancelToken();
    _messageLoad = token;
    return _api.get<AssistantThread>(
      ApiEndpoints.assistantMessages(conversationId),
      cancelToken: token,
      decoder: AssistantDto.thread,
    );
  }

  @override
  Future<Result<AssistantSendResponse>> sendMessage({
    required String message,
    String? conversationId,
  }) => _api.post<AssistantSendResponse>(
    ApiEndpoints.assistantSend,
    data: {
      'conversationId': ?conversationId,
      'message': message,
    },
    decoder: AssistantDto.sendResponse,
  );

  @override
  Future<Result<void>> deleteConversation(String conversationId) =>
      _api.delete<void>(
        ApiEndpoints.assistantConversation(conversationId),
        decoder: (_) {},
      );

  @override
  void cancelPendingLoads() {
    _conversationLoad?.cancel();
    _messageLoad?.cancel();
  }
}
