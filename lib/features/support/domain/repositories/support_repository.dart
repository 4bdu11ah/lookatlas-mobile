import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/support/domain/entities/support_ticket.dart';

// ignore: one_member_abstracts, repository boundary for the authenticated API and test fakes
abstract interface class SupportRepository {
  Future<Result<SupportTicketReceipt>> submitTicket(
    SupportTicketRequest request,
  );
}
