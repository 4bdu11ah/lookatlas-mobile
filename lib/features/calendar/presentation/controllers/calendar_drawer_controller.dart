import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_caption.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';
import 'package:look_atlas/features/calendar/presentation/models/calendar_drawer_state.dart';
import 'package:look_atlas/features/create_content/di/content_providers.dart';

final NotifierProviderFamily<
  CalendarDrawerController,
  CalendarDrawerState,
  CalendarDrawerArgs
>
calendarDrawerProvider = NotifierProvider.autoDispose
    .family<CalendarDrawerController, CalendarDrawerState, CalendarDrawerArgs>(
      CalendarDrawerController.new,
    );

class CalendarDrawerController extends Notifier<CalendarDrawerState> {
  CalendarDrawerController(this.args);
  final CalendarDrawerArgs args;
  final hook = TextEditingController();
  final purpose = TextEditingController();
  final time = TextEditingController();
  final caption = TextEditingController();
  CalendarCaption? _caption;
  bool _captionInitialized = false;
  CalendarSession get session => args.view.session;

  @override
  CalendarDrawerState build() {
    final item = args.item;
    final plan = session.overview!.plan!;
    hook.text = item?.hook ?? '';
    purpose.text = item?.purpose ?? '';
    time.text = _initialTime(item, plan);
    ref.onDispose(_dispose);
    ref.listen(calendarControllerProvider, (_, next) {
      state = state.copyWith(
        item: next.overview?.items
            .where((i) => i.id == args.item?.id)
            .firstOrNull,
      );
    });
    if (args.type == 'post' &&
        item?.editable == true &&
        item?.generationId != null) {
      _caption = CalendarCaption(
        ref.read(contentRepositoryProvider),
        item!.generationId!,
        refresh: session.refresh,
      )..addListener(_captionChanged);
      unawaited(
        Future<void>.microtask(() async {
          if (ref.mounted) await loadCaption();
        }),
      );
    }
    return CalendarDrawerState(
      productId: item?.productId ?? session.products.firstOrNull?.id,
      format: item?.format ?? 'single',
      automation: session.overview!.drafts ? 'drafts' : plan.automation,
      platforms: item?.platforms ?? plan.platforms,
      savedTime: time.text,
      item: item,
      caption: CalendarCaptionState.fromController(_caption),
    );
  }

  String _initialTime(CalendarItem? item, CalendarPlan plan) {
    if (item?.localTime != null) return calendarLocalInput(item!.localTime!);
    if (args.type != 'add') return '';
    final start = DateTime.parse(plan.startsOn);
    final now = session.now();
    return calendarLocalInput(
      calendarDefaultTime(args.day ?? (start.isAfter(now) ? start : now), now),
    );
  }

  void _dispose() {
    _caption?.dispose();
    hook.dispose();
    purpose.dispose();
    time.dispose();
    caption.dispose();
  }

  void _captionChanged() {
    if (!ref.mounted) return;
    if (_caption!.loaded && !_captionInitialized) {
      caption.text = _caption!.value;
      _captionInitialized = true;
    }
    state = state.copyWith(
      caption: CalendarCaptionState.fromController(_caption),
    );
  }

  void setProduct(String value) => state = state.copyWith(productId: value);
  void setFormat(String value) => state = state.copyWith(format: value);
  void setAutomation(String value) => state = state.copyWith(automation: value);
  void togglePlatform(String platform) {
    final platforms = [...state.platforms];
    platforms.contains(platform)
        ? platforms.remove(platform)
        : platforms.add(platform);
    state = state.copyWith(platforms: platforms);
  }

  void showError(String value) {
    if (ref.mounted) state = state.copyWith(error: value);
  }

  void editCaption(String value) => _caption?.edit(value);
  Future<void> loadCaption() async => _caption?.load();
  Future<bool> saveCaption() async {
    if (_caption == null) return true;
    _caption!.edit(caption.text);
    return _caption!.save();
  }

  Future<bool> commitTime() async {
    if (time.text == state.savedTime) return true;
    if (state.saving || state.item == null) return false;
    final validation = calendarTimeError(
      time.text,
      session.overview!.plan!,
      session.now(),
    );
    if (validation != null) {
      showError(validation);
      return false;
    }
    final value = time.text;
    final id = state.item!.id;
    state = state.copyWith(saving: true);
    final ok = await session.updateItem(id, {
      'publishAt': calendarParseInput(value)!.toUtc().toIso8601String(),
    });
    if (!ref.mounted) return false;
    state = state.copyWith(
      saving: false,
      clearError: ok,
      error: ok ? null : session.mutationErrors[id],
      savedTime: ok ? value : null,
    );
    return ok;
  }

  Future<bool> canClose() async {
    if (state.saving || state.caption.saving) return false;
    return args.type != 'post' || (await commitTime() && await saveCaption());
  }

  String? _validation() {
    if (state.productId == null) return 'Choose a product.';
    if (state.platforms.isEmpty) return 'Choose at least one channel.';
    if (state.format == 'video' &&
        !session.overview!.videoEligible &&
        args.item?.format != 'video') {
      return 'Video posts need an eligible plan.';
    }
    if (args.type == 'idea' && hook.text.trim().isEmpty) {
      return 'Enter a post idea.';
    }
    if (args.type == 'add' || time.text != state.savedTime) {
      return calendarTimeError(
        time.text,
        session.overview!.plan!,
        session.now(),
      );
    }
    return null;
  }

  CalendarJson _patch() => {
    'productId': state.productId,
    'format': state.format,
    'platforms': state.platforms,
    if (args.type != 'add' || hook.text.trim().isNotEmpty)
      'hook': hook.text.trim(),
    if (args.type == 'idea') ...{
      'purpose': purpose.text.trim(),
      'locked': true,
    },
    if (args.type == 'add' || time.text != state.savedTime)
      'publishAt': calendarParseInput(time.text)!.toUtc().toIso8601String(),
  };
  Future<bool> save() async {
    if (state.saving) return false;
    state = state.copyWith(clearError: true);
    if (args.type == 'automation') return _saveAutomation();
    final validation = _validation();
    if (validation != null) {
      showError(validation);
      return false;
    }
    state = state.copyWith(saving: true);
    final key = args.type == 'add' ? 'add' : state.item!.id;
    final ok = args.type == 'add'
        ? await session.addItem(_patch())
        : await session.updateItem(key, _patch());
    if (!ref.mounted) return false;
    state = state.copyWith(
      saving: false,
      error: ok ? null : session.mutationErrors[key],
    );
    return ok;
  }

  Future<bool> _saveAutomation() async {
    state = state.copyWith(saving: true);
    final ok = await session.updatePlan({
      'automationMode': session.overview!.publishingAvailable
          ? state.automation
          : 'drafts',
    });
    if (!ref.mounted) return false;
    state = state.copyWith(
      saving: false,
      error: ok ? null : session.mutationErrors['plan'],
    );
    return ok;
  }

  Future<void> action(String action) async {
    if (state.saving || state.item == null) return;
    if (!await commitTime() || !await saveCaption() || !ref.mounted) return;
    final id = state.item!.id;
    state = state.copyWith(saving: true);
    final ok = await session.itemAction(state.item!, action);
    if (ref.mounted) {
      state = state.copyWith(
        saving: false,
        error: ok ? null : session.mutationErrors[id],
      );
    }
  }

  Future<void> openPublished(String url) async {
    try {
      await const MethodChannel('com.lookatlas/calendar')
          .invokeMethod<void>('openPublished', {'url': url});
    } on Object {
      showError('Could not open the published post.');
    }
  }
}
