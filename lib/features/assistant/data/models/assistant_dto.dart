import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';

abstract final class AssistantDto {
  static List<AssistantConversation> conversations(Object? data) {
    final root = _map(data);
    final values = root['conversations'];
    if (values is! List) return const [];
    return [for (final value in values) conversation(value)];
  }

  static AssistantThread thread(Object? data) {
    final root = _map(data);
    final values = root['messages'];
    return AssistantThread(
      conversation: conversation(root['conversation']),
      messages: values is List
          ? [for (final value in values) message(value)]
          : const [],
    );
  }

  static AssistantSendResponse sendResponse(Object? data) {
    final root = _map(data);
    return AssistantSendResponse(
      conversation: conversation(root['conversation']),
      userMessage: message(root['userMessage']),
      reply: message(root['reply']),
      nudge: _nullableString(root['nudge']),
    );
  }

  static AssistantConversation conversation(Object? data) {
    final json = _map(data);
    return AssistantConversation(
      id: _string(json['id']),
      title: _string(json['title']),
      messageCount: _integer(json['messageCount']),
      createdAt: _date(json['createdAt']),
      lastMessageAt: _date(json['lastMessageAt']),
    );
  }

  static AssistantMessage message(Object? data) {
    final json = _map(data);
    return AssistantMessage(
      id: _string(json['id']),
      role: AssistantRole.fromApi(json['role']),
      content: _string(json['content']),
      createdAt: _date(json['createdAt']),
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static String _string(Object? value) => value?.toString() ?? '';

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static DateTime? _date(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '');
}
