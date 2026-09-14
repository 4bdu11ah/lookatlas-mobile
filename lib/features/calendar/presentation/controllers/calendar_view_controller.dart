import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarViewState {
  const CalendarViewState({
    this.productsOpen = false,
    this.revisionOpen = false,
    this.instruction = '',
    this.month = false,
  });
  final bool productsOpen;
  final bool revisionOpen;
  final String instruction;
  final bool month;
  CalendarViewState copyWith({
    bool? productsOpen,
    bool? revisionOpen,
    String? instruction,
    bool? month,
  }) => CalendarViewState(
    productsOpen: productsOpen ?? this.productsOpen,
    revisionOpen: revisionOpen ?? this.revisionOpen,
    instruction: instruction ?? this.instruction,
    month: month ?? this.month,
  );
}

final calendarInitialMonthProvider = Provider<bool>((ref) => false);
final NotifierProvider<CalendarViewController, CalendarViewState>
calendarViewProvider =
    NotifierProvider.autoDispose<CalendarViewController, CalendarViewState>(
      CalendarViewController.new,
      dependencies: [calendarInitialMonthProvider],
    );

class CalendarViewController extends Notifier<CalendarViewState> {
  @override
  CalendarViewState build() =>
      CalendarViewState(month: ref.watch(calendarInitialMonthProvider));
  void setProductsOpen({required bool value}) =>
      state = state.copyWith(productsOpen: value);
  void setRevisionOpen({required bool value}) =>
      state = state.copyWith(revisionOpen: value);
  void setInstruction(String value) =>
      state = state.copyWith(instruction: value);
  void setMonth({required bool value}) => state = state.copyWith(month: value);
}

final Provider<TextEditingController> calendarRevisionTextProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final controller = TextEditingController();
      ref.onDispose(controller.dispose);
      return controller;
    });
final Provider<GlobalKey<State<StatefulWidget>>> calendarReviewKeyProvider =
    Provider.autoDispose<GlobalKey>(
      (ref) => GlobalKey(),
    );

final Provider<ScrollController> calendarScrollControllerProvider =
    Provider.autoDispose<ScrollController>((ref) {
      final controller = ScrollController();
      ref.onDispose(controller.dispose);
      return controller;
    });
