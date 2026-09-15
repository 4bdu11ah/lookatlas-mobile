import 'package:dio/dio.dart';
import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/support/domain/entities/support_ticket.dart';
import 'package:look_atlas/features/support/domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this._api, {this.cancellation});
  final ApiService _api;
  final CancelToken? cancellation;

  @override
  Future<Result<SupportTicketReceipt>> submitTicket(
    SupportTicketRequest request,
  ) => _api.post<SupportTicketReceipt>(
    ApiEndpoints.supportTickets,
    cancelToken: cancellation,
    data: {
      'title': request.title,
      'name': request.name,
      'priority': request.priority,
      'message': request.message,
    },
    decoder: (data) {
      if (data is! Map<String, dynamic> ||
          data['message'] is! String ||
          data['provider'] is! String ||
          (data['id'] != null && data['id'] is! String)) {
        throw const FormatException('Invalid support ticket response');
      }
      return SupportTicketReceipt(
        message: data['message'] as String,
        provider: data['provider'] as String,
        id: data['id'] as String?,
      );
    },
  );
}
