import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/assistant/domain/entities/assistant_models.dart';
import 'package:look_atlas/features/assistant/presentation/controllers/assistant_controller.dart';
import 'package:look_atlas/features/assistant/presentation/controllers/assistant_state.dart';
import 'package:look_atlas/features/assistant/presentation/widgets/assistant_composer.dart';
import 'package:look_atlas/features/assistant/presentation/widgets/assistant_history.dart';
import 'package:look_atlas/features/assistant/presentation/widgets/assistant_message_widgets.dart';
import 'package:look_atlas/shared/widgets/app_feature_scaffold.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _composer = TextEditingController();
  final _scrollController = ScrollController();
  late final AssistantController _assistantController;

  @override
  void initState() {
    super.initState();
    _assistantController = ref.read(assistantControllerProvider.notifier);
    _composer.addListener(_updateDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_assistantController.open());
      _syncDraft(ref.read(assistantControllerProvider).draft);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _assistantController.disposeView();
    _composer
      ..removeListener(_updateDraft)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantControllerProvider);
    final controller = ref.read(assistantControllerProvider.notifier);
    ref.listen(assistantControllerProvider, (previous, next) {
      if (previous?.draftKey != next.draftKey ||
          previous?.draft != next.draft) {
        _syncDraft(next.draft);
      }
      if (_threadChanged(previous, next)) _scrollToBottom();
    });
    return PopScope(
      canPop: state.view == AssistantView.chat,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          controller.disposeView();
        } else {
          controller.showChat();
        }
      },
      child: AppFeatureScaffold(
        title: state.view == AssistantView.history ? 'Chats' : 'Assistant',
        useResponsiveContent: false,
        onBack: state.view == AssistantView.history
            ? controller.showChat
            : null,
        actions: state.view == AssistantView.history
            ? const []
            : [
                _AppBarAction(
                  icon: Icons.history,
                  label: 'Past chats',
                  onTap: controller.showHistory,
                ),
                _AppBarAction(
                  icon: Icons.edit_outlined,
                  label: 'New chat',
                  onTap: controller.newChat,
                ),
              ],
        child: Column(
          children: [
            Expanded(
              child: state.view == AssistantView.history
                  ? AssistantHistory(
                      conversations: state.conversations,
                      activeConversationId: state.activeConversationId,
                      loading: state.conversationsLoading,
                      onNewChat: controller.newChat,
                      onSelect: controller.selectConversation,
                      onDelete: _requestDelete,
                    )
                  : _ChatView(
                      state: state,
                      scrollController: _scrollController,
                      onStarter: _sendStarter,
                    ),
            ),
            _AssistantBanners(
              state: state,
              onSupport: () => context.push<void>(AppRoutes.dashboardSupport),
            ),
            if (state.view == AssistantView.chat)
              AssistantComposer(
                controller: _composer,
                enabled: !state.composerDisabled,
                canSend:
                    !state.composerDisabled && _composer.text.trim().isNotEmpty,
                onSend: () => unawaited(controller.send()),
              ),
          ],
        ),
      ),
    );
  }

  void _updateDraft() {
    ref.read(assistantControllerProvider.notifier).setDraft(_composer.text);
  }

  void _syncDraft(String draft) {
    if (_composer.text == draft) return;
    _composer.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  void _sendStarter(({String label, String message}) starter) {
    final controller = ref.read(assistantControllerProvider.notifier);
    unawaited(
      (controller..trackStarter(starter.label)).send(starter.message),
    );
  }

  Future<void> _requestDelete(String conversationId) async {
    final controller = ref.read(assistantControllerProvider.notifier)
      ..requestDelete(conversationId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: const Text('Delete this chat?'),
        content: const Text(
          'This removes the conversation from your history. '
          'This cannot be undone.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed ?? false) {
      await controller.confirmDelete();
    } else {
      controller.cancelDelete();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      final duration = MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200);
      if (duration == Duration.zero) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        unawaited(
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: duration,
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  static bool _threadChanged(AssistantState? previous, AssistantState next) =>
      previous?.messages.length != next.messages.length ||
      previous?.pendingUserMessage != next.pendingUserMessage ||
      previous?.messagesLoading != next.messagesLoading ||
      previous?.view != next.view ||
      previous?.activeConversationId != next.activeConversationId;
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: const Color(0xFF0A0A0A),
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView({
    required this.state,
    required this.scrollController,
    required this.onStarter,
  });

  final AssistantState state;
  final ScrollController scrollController;
  final ValueChanged<({String label, String message})> onStarter;

  @override
  Widget build(BuildContext context) {
    final hasThread =
        state.messages.isNotEmpty ||
        state.pendingUserMessage != null ||
        state.messagesLoading;
    if (!hasThread) return _AssistantEmptyState(onStarter: onStarter);
    final count =
        state.messages.length +
        (state.pendingUserMessage == null ? 0 : 1) +
        (state.sending || state.messagesLoading ? 1 : 0);
    return ListView.builder(
      key: const Key('assistant-thread'),
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (context, index) {
        Widget child;
        if (index < state.messages.length) {
          child = AssistantMessageBubble(message: state.messages[index]);
        } else if (state.pendingUserMessage != null &&
            index == state.messages.length) {
          child = AssistantMessageBubble(
            message: AssistantMessage(
              id: 'pending',
              role: AssistantRole.user,
              content: state.pendingUserMessage!,
            ),
          );
        } else {
          child = const AssistantTypingIndicator();
        }
        return Padding(
          padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 10),
          child: child,
        );
      },
    );
  }
}

class _AssistantEmptyState extends StatelessWidget {
  const _AssistantEmptyState({required this.onStarter});

  static const List<({String label, String message})> starters = [
    (label: 'How do credits work?', message: 'How do credits work?'),
    (
      label: 'Shots vs variations, what is the difference?',
      message: 'What is the difference between shots and variations?',
    ),
    (
      label: 'How do I get better product detail?',
      message: 'How do I get better product detail in my shoots?',
    ),
    (label: 'How do refunds work?', message: 'How do refunds work?'),
  ];

  final ValueChanged<({String label, String message})> onStarter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                color: const Color(0xFF0A0A0A),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'How can I help?',
                style: TextStyle(
                  fontSize: 19,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.36,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ask anything about shoots, credits, or billing.',
                style: TextStyle(
                  color: Color(0x730A0A0A),
                  fontSize: 13.5,
                  height: 1.625,
                ),
              ),
              const SizedBox(height: 20),
              for (var index = 0; index < starters.length; index++) ...[
                _StarterRow(
                  starter: starters[index],
                  onTap: () => onStarter(starters[index]),
                ),
                if (index != starters.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StarterRow extends StatelessWidget {
  const _StarterRow({required this.starter, required this.onTap});

  final ({String label, String message}) starter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0x1A000000)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                starter.label,
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.north_east, size: 14, color: Color(0x400A0A0A)),
          ],
        ),
      ),
    );
  }
}

class _AssistantBanners extends StatelessWidget {
  const _AssistantBanners({required this.state, required this.onSupport});

  final AssistantState state;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final minuteMessage = state.limit == AssistantLimit.minute
        ? 'You are sending messages quickly. Please wait '
              '${state.limitSeconds}s.'
        : null;
    if (!state.longConversationNudge &&
        state.error == null &&
        minuteMessage == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (state.longConversationNudge)
            const _Banner(
              text:
                  'This chat is getting long. New chats keep replies fast '
                  'and focused.',
            ),
          if (minuteMessage != null) _Banner(text: minuteMessage, error: true),
          if (state.error != null)
            _Banner(
              text: state.error!,
              error: true,
              onSupport: state.error == assistantUnavailableMessage
                  ? onSupport
                  : null,
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.error = false, this.onSupport});

  final String text;
  final bool error;
  final VoidCallback? onSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: error ? const Color(0xFFFEF2F2) : const Color(0xFFFAFAFA),
        border: error ? Border.all(color: const Color(0xFFFEE2E2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onSupport == null)
            Text(text, style: _style)
          else
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text:
                        'The assistant is temporarily unavailable. Please '
                        'try again later. If you need help right now, visit the ',
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: onSupport,
                      child: Text(
                        'Support page.',
                        style: _style.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: _style.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              style: _style,
            ),
        ],
      ),
    );
  }

  TextStyle get _style => TextStyle(
    color: error ? const Color(0xFFB91C1C) : const Color(0x990A0A0A),
    fontSize: 12,
    height: 1.625,
  );
}
