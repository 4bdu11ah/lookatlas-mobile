import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_spacing.dart';
import 'package:look_atlas/features/ai/domain/chat_message.dart';
import 'package:look_atlas/features/ai/presentation/chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    unawaited(ref.read(chatControllerProvider.notifier).send(text));
  }

  @override
  Widget build(BuildContext context) {
    // Watch narrow slices so streamed tokens only rebuild the affected bubble,
    // not the whole screen.
    final messageCount = ref.watch(
      chatControllerProvider.select((s) => s.messages.length),
    );
    final isStreaming = ref.watch(
      chatControllerProvider.select((s) => s.isStreaming),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: messageCount == 0
                ? null
                : () => ref.read(chatControllerProvider.notifier).clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messageCount == 0
                ? const _EmptyChat()
                // Reversed list pins new content to the bottom without any
                // scroll-controller bookkeeping.
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: messageCount,
                    itemBuilder: (context, index) {
                      final messageIndex = messageCount - 1 - index;
                      return Consumer(
                        builder: (context, ref, _) {
                          final message = ref.watch(
                            chatControllerProvider.select(
                              (s) => messageIndex < s.messages.length
                                  ? s.messages[messageIndex]
                                  : null,
                            ),
                          );
                          if (message == null) return const SizedBox.shrink();
                          return _MessageBubble(message: message);
                        },
                      );
                    },
                  ),
          ),
          _Composer(
            controller: _controller,
            isStreaming: isStreaming,
            onSend: _send,
            onStop: () => ref.read(chatControllerProvider.notifier).stop(),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final color = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        child: Text(
          message.text.isEmpty && message.isStreaming ? '...' : message.text,
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              // Kept enabled while streaming so the keyboard/focus survive a
              // send; only the send action itself is gated.
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (!isStreaming) onSend();
                },
                decoration: const InputDecoration(hintText: 'Ask anything'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              tooltip: isStreaming ? 'Stop generating' : 'Send',
              onPressed: isStreaming ? onStop : onSend,
              icon: Icon(
                isStreaming
                    ? Icons.stop_circle_outlined
                    : Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Start a conversation', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
