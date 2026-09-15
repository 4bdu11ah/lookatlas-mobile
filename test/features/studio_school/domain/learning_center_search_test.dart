import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/guides/presentation/models/learning_guide_content.dart';
import 'package:look_atlas/features/studio_school/presentation/controllers/learning_center_search_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/models/studio_school_catalog.dart';

void main() {
  test('search_words_ignoresCaseAndExtraWhitespace', () {
    expect(matchesLearningSearch(['Credit fuel', 'Quick math'], '  CREDIT   math '), isTrue);
    expect(matchesLearningSearch(['Credit fuel'], 'credit math'), isFalse);
  });
  test('search_empty_matchesAllContent', () {
    expect(matchesLearningSearch(['Any lesson'], '  '), isTrue);
  });
  test('search_cardBody_matchesLesson', () {
    final lesson = studioSchoolLessons.first;
    expect(matchesLearningSearch([lesson.title, for (final card in lesson.cards) card.body], 'paced lane'), isTrue);
  });
  test('search_guideSteps_matchesDeepContent', () {
    expect(matchesLearningSearch([productPhotosContent.searchText], 'reference angles'), isTrue);
    expect(matchesLearningSearch([modelsContent.searchText], 'creative brief'), isTrue);
  });
}
