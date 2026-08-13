enum AssistantRole {
  user,
  assistant;

  static AssistantRole fromApi(Object? value) =>
      value == 'user' ? user : assistant;
}

class AssistantConversation {
  const AssistantConversation({
    required this.id,
    required this.title,
    required this.messageCount,
    this.createdAt,
    this.lastMessageAt,
  });

  final String id;
  final String title;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? lastMessageAt;
}

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
  });

  final String id;
  final AssistantRole role;
  final String content;
  final DateTime? createdAt;
}

class AssistantThread {
  const AssistantThread({
    required this.conversation,
    required this.messages,
  });

  final AssistantConversation conversation;
  final List<AssistantMessage> messages;
}

class AssistantSendResponse {
  const AssistantSendResponse({
    required this.conversation,
    required this.userMessage,
    required this.reply,
    this.nudge,
  });

  final AssistantConversation conversation;
  final AssistantMessage userMessage;
  final AssistantMessage reply;
  final String? nudge;
}
