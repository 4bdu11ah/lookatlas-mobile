import 'package:flutter/foundation.dart';

enum ChatRole { user, assistant }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.isStreaming = false,
  });

  final ChatRole role;
  final String text;

  /// True while the assistant reply is still being streamed in.
  final bool isStreaming;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({String? text, bool? isStreaming}) => ChatMessage(
    role: role,
    text: text ?? this.text,
    isStreaming: isStreaming ?? this.isStreaming,
  );

  Map<String, String> toApiJson() => {
    'role': role.name,
    'content': text,
  };
}
