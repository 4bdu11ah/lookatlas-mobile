import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';

class AssistantHistory extends StatelessWidget {
  const AssistantHistory({
    required this.conversations,
    required this.activeConversationId,
    required this.loading,
    required this.onNewChat,
    required this.onSelect,
    required this.onDelete,
    super.key,
  });

  final List<AssistantConversation> conversations;
  final String? activeConversationId;
  final bool loading;
  final VoidCallback onNewChat;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          InkWell(
            key: const Key('assistant-start-new-chat'),
            onTap: onNewChat,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x1A000000)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 10),
                  Text(
                    'Start a new chat',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: loading && conversations.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final item = conversations[index];
                      return _ConversationRow(
                        conversation: item,
                        active: item.id == activeConversationId,
                        onSelect: () => onSelect(item.id),
                        onDelete: () => onDelete(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.active,
    required this.onSelect,
    required this.onDelete,
  });

  final AssistantConversation conversation;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: active ? const Color(0xFFF5F5F5) : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onSelect,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.375,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _RelativeTimeText(
                      time:
                          conversation.lastMessageAt ?? conversation.createdAt,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            label: 'Delete chat',
            button: true,
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 16),
              color: const Color(0x4D0A0A0A),
              constraints: const BoxConstraints.tightFor(width: 40, height: 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelativeTimeText extends StatefulWidget {
  const _RelativeTimeText({required this.time});

  final DateTime? time;

  @override
  State<_RelativeTimeText> createState() => _RelativeTimeTextState();
}

class _RelativeTimeTextState extends State<_RelativeTimeText> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(covariant _RelativeTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.time == widget.time) return;
    _scheduleRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    final time = widget.time;
    if (time == null) return;
    final delay = _nextRefreshDelay(time, DateTime.now());
    if (delay == null) return;
    _refreshTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {});
      _scheduleRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _relativeTime(widget.time, DateTime.now()),
      style: const TextStyle(color: Color(0x660A0A0A), fontSize: 11.5),
    );
  }
}

String _relativeTime(DateTime? time, DateTime now) {
  if (time == null) return '';
  final difference = now.toUtc().difference(time.toUtc());
  if (difference.inMinutes < 1) return 'now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return DateFormat.yMMMd().format(time.toLocal());
}

Duration? _nextRefreshDelay(DateTime time, DateTime now) {
  final difference = now.toUtc().difference(time.toUtc());
  if (difference.inDays >= 7) return null;
  final interval = difference.inHours >= 24
      ? const Duration(days: 1)
      : difference.inMinutes >= 60
      ? const Duration(hours: 1)
      : const Duration(minutes: 1);
  final elapsed = difference.isNegative ? Duration.zero : difference;
  final remainder = elapsed.inMilliseconds % interval.inMilliseconds;
  return Duration(milliseconds: interval.inMilliseconds - remainder + 50);
}
