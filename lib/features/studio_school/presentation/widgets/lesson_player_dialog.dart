import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/features/studio_school/domain/lesson_definition.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_state.dart';
import 'package:look_atlas/features/studio_school/presentation/widgets/lesson_player_content.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';

Future<String?> showStudioLessonPlayer(
  BuildContext context, {
  required LessonDefinition lesson,
  required WelcomeState? welcome,
  required bool online,
}) => showDialog<String>(
  context: context,
  barrierColor: AppDialogConfig.standard.barrierColor,
  builder: (_) => StudioLessonPlayer(
    lesson: lesson,
    welcome: welcome,
    online: online,
  ),
);

class StudioLessonPlayer extends ConsumerStatefulWidget {
  const StudioLessonPlayer({
    required this.lesson,
    required this.welcome,
    required this.online,
    super.key,
  });

  final LessonDefinition lesson;
  final WelcomeState? welcome;
  final bool online;

  @override
  ConsumerState<StudioLessonPlayer> createState() => _StudioLessonPlayerState();
}

class _StudioLessonPlayerState extends ConsumerState<StudioLessonPlayer>
    with WidgetsBindingObserver {
  static const _serverMinimum = Duration(seconds: 20);
  static const _safetyMargin = Duration(milliseconds: 1500);

  Timer? _timer;
  final ValueNotifier<Duration> _countdown = ValueNotifier(
    _serverMinimum + _safetyMargin,
  );
  DateTime? _readyAt;
  int _cardIndex = 0;
  bool _saving = false;
  bool _completed = false;
  String? _error;

  bool get _trackProgress => widget.welcome?.eligible ?? false;
  bool get _alreadyCompleted =>
      widget.welcome?.progressFor(widget.lesson.id).isCompleted ?? false;
  bool get _isFinal => _cardIndex == widget.lesson.cards.length - 1;
  Duration get _remaining {
    final readyAt = _readyAt;
    if (readyAt == null) return _serverMinimum + _safetyMargin;
    final remaining = readyAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setReadyAt(widget.welcome?.progressFor(widget.lesson.id).startedAt);
    if (_trackProgress && !_alreadyCompleted && !widget.online) {
      _error = 'Reconnect to save lesson progress.';
    } else if (_trackProgress && !_alreadyCompleted) {
      unawaited(_start());
      _timer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _tick(),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _countdown.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final startedAt = await ref
        .read(studioSchoolControllerProvider.notifier)
        .startLesson(widget.lesson.id);
    if (!mounted || startedAt == null) {
      if (mounted && _readyAt == null) {
        setState(
          () => _error = 'Progress could not start. Check your connection.',
        );
      }
      return;
    }
    setState(() {
      _setReadyAt(startedAt);
      _error = null;
    });
  }

  void _setReadyAt(DateTime? startedAt) {
    if (startedAt == null) return;
    _readyAt = startedAt.toLocal().add(_serverMinimum + _safetyMargin);
    _countdown.value = _remaining;
  }

  void _tick() {
    if (_readyAt == null) return;
    _countdown.value = _remaining;
  }

  Future<void> _done() async {
    if (!_trackProgress || _alreadyCompleted) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(studioSchoolControllerProvider.notifier)
        .completeLesson(widget.lesson.id);
    if (!mounted) return;
    switch (result.kind) {
      case LessonActionKind.completed:
      case LessonActionKind.alreadyCompleted:
        await _showSuccess();
      case LessonActionKind.tooFast:
        setState(() {
          _saving = false;
          _readyAt = DateTime.now().add(
            result.retryAfter ?? const Duration(seconds: 2),
          );
          _countdown.value = _remaining;
          _error = 'Almost. Give it ${_remaining.inSeconds + 1} more seconds.';
        });
      case LessonActionKind.notStarted:
        setState(() {
          _saving = false;
          _readyAt = null;
          _countdown.value = _serverMinimum + _safetyMargin;
          _error = 'Give it a moment, then hit Done again.';
        });
        await _start();
      case LessonActionKind.failed:
        setState(() {
          _saving = false;
          _error = result.message ?? 'Progress could not be saved. Try again.';
        });
    }
  }

  Future<void> _showSuccess() async {
    setState(() {
      _saving = false;
      _completed = true;
    });
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (!disableAnimations) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
    if (mounted) Navigator.pop(context);
  }

  void _previous() => setState(() => _cardIndex--);
  void _next() => setState(() => _cardIndex++);

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      config: AppDialogConfig.standard.copyWith(
        maxWidth: 560,
        title: widget.lesson.title,
        subtitle: widget.lesson.tagline,
        icon: widget.lesson.icon,
      ),
      footer: _completed
          ? null
          : LessonPlayerFooter(
              showPrevious: _cardIndex > 0,
              isFinal: _isFinal,
              countdown: _countdown,
              timerRequired: _trackProgress && !_alreadyCompleted,
              completionAllowed: !_trackProgress || widget.online,
              saving: _saving,
              error: _error,
              onPrevious: _previous,
              onNext: _next,
              onDone: _done,
              onRetryStart: _start,
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LessonProgress(
            count: widget.lesson.cards.length,
            active: _cardIndex,
          ),
          Flexible(
            child: _completed
                ? const LessonSuccess()
                : LessonPlayerCardBody(
                    card: widget.lesson.cards[_cardIndex],
                    tryLink: _isFinal ? widget.lesson.tryLink : null,
                    onTry: (location) => Navigator.pop(context, location),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LessonProgress extends StatelessWidget {
  const _LessonProgress({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${active + 1} / $count',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              count,
              (index) => Expanded(
                child: Container(
                  height: 2,
                  margin: EdgeInsets.only(right: index == count - 1 ? 0 : 4),
                  color: index <= active
                      ? AppColors.black
                      : AppColors.neutral200,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
