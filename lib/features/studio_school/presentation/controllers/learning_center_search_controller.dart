import 'package:flutter_riverpod/flutter_riverpod.dart';

bool matchesLearningSearch(Iterable<String> fields, String query) {
  final words = query.toLowerCase().trim().split(RegExp(r'\s+'));
  final text = fields.join(' ').toLowerCase();
  return words.every(text.contains);
}

class LearningCenterSearchController extends Notifier<String> {
  @override
  String build() => '';

  String get query => state;
  set query(String query) => state = query;
  void clear() => state = '';
}

final NotifierProvider<LearningCenterSearchController, String>
learningCenterSearchProvider =
    NotifierProvider.autoDispose<LearningCenterSearchController, String>(
      LearningCenterSearchController.new,
    );

class LearningRewardController extends Notifier<bool> {
  @override
  bool build() => false;

  bool get claiming => state;
  set claiming(bool value) => state = value;
}

final NotifierProvider<LearningRewardController, bool>
learningRewardClaimingProvider =
    NotifierProvider.autoDispose<LearningRewardController, bool>(
      LearningRewardController.new,
    );
