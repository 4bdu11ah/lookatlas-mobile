import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/support/domain/entities/support_ticket.dart';
import 'package:look_atlas/features/support/domain/repositories/support_repository.dart';

class FakeSupportRepository implements SupportRepository {
  FakeSupportRepository({
    this.result = const Ok(
      SupportTicketReceipt(
        message: 'Support ticket sent',
        provider: 'linear',
        id: 'LA-1042',
      ),
    ),
  });
  final Result<SupportTicketReceipt> result;
  final requests = <SupportTicketRequest>[];
  Future<Result<SupportTicketReceipt>>? pending;

  @override
  Future<Result<SupportTicketReceipt>> submitTicket(
    SupportTicketRequest request,
  ) async {
    requests.add(request);
    return pending == null ? result : await pending!;
  }
}
