import 'dart:async';

import 'package:look_atlas/services/analytics/analytics_service.dart';

class AssistantAnalytics {
  const AssistantAnalytics(this._service);

  final AnalyticsService _service;

  void opened() => _track('assistant.opened');

  void messageSent(String? conversationId, int chars) => _track(
    'assistant.message_sent',
    properties: {
      'conversationId': ?conversationId,
      'chars': chars,
      'isNewConversation': conversationId == null,
    },
  );

  void replyReceived(int latencyMs) => _track(
    'assistant.reply_received',
    properties: {'latencyMs': latencyMs},
  );

  void rateLimited(String reason) => _track(
    'assistant.rate_limited',
    properties: {'reason': reason},
  );

  void error(String code) =>
      _track('assistant.error', properties: {'code': code});

  void starterClicked(String label) => _track(
    'assistant.starter_chip_clicked',
    properties: {'chip': label},
  );

  void conversationDeleted() => _track('assistant.conversation_deleted');

  void _track(String event, {Map<String, Object>? properties}) {
    unawaited(_service.track(event, properties: properties));
  }
}
