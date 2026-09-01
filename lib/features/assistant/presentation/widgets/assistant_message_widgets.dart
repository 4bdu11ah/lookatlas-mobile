import 'package:flutter/material.dart';
import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({required this.message, super.key});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AssistantRole.user;
    return Semantics(
      liveRegion: !isUser,
      label: isUser
          ? 'You: ${message.content}'
          : 'Assistant: ${message.content}',
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: .82,
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isUser ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF0A0A0A),
                  fontSize: 14,
                  height: 1.625,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AssistantTypingIndicator extends StatefulWidget {
  const AssistantTypingIndicator({super.key});

  @override
  State<AssistantTypingIndicator> createState() =>
      _AssistantTypingIndicatorState();
}

class _AssistantTypingIndicatorState extends State<AssistantTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      label: 'Assistant is typing',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: const Color(0xFFF5F5F5),
          child: disableAnimations
              ? const _TypingDots(progress: .3)
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (_, _) => _TypingDots(progress: _controller.value),
                ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final shifted = (progress - index * .15) % 1;
        final lift = shifted < .5 ? (1 - (shifted - .25).abs() * 4) : 0.0;
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
          child: Transform.translate(
            offset: Offset(0, -3 * lift.clamp(0, 1)),
            child: Opacity(
              opacity: .3 + .7 * lift.clamp(0, 1),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x800A0A0A),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: 6),
              ),
            ),
          ),
        );
      }),
    );
  }
}
