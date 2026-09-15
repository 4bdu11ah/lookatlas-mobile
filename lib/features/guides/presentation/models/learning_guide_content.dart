import 'package:look_atlas/core/router/app_routes.dart';

part '../tabs/getting_started_guide.dart';
part '../tabs/product_photos_guide.dart';
part '../tabs/models_guide.dart';
part '../tabs/shoots_guide.dart';

typedef GuideTextRuns = List<(String, bool)>;

enum GuideBlockKind { heading, feature, step, tip, checklist, figure, actions }

class LearningGuideBlock {
  const LearningGuideBlock(
    this.kind, {
    this.title = '',
    this.number = '',
    this.paragraphs = const [],
    this.iconSvg = '',
    this.actions = const [],
  });
  final GuideBlockKind kind;
  final String title;
  final String number;
  final List<GuideTextRuns> paragraphs;
  final String iconSvg;
  final List<(String, String)> actions;
}

class LearningGuideContent {
  const LearningGuideContent({
    required this.kicker,
    required this.title,
    required this.intro,
    required this.blocks,
  });
  final String kicker;
  final String title;
  final String intro;
  final List<LearningGuideBlock> blocks;

  String get searchText => [
    kicker,
    title,
    intro,
    for (final block in blocks) ...[
      block.title,
      for (final paragraph in block.paragraphs)
        for (final run in paragraph) run.$1,
      for (final action in block.actions) action.$1,
    ],
  ].join(' ');
}

LearningGuideContent learningGuideForId(String id) => switch (id) {
  'product-photos' => productPhotosContent,
  'models' => modelsContent,
  'jobs' => shootsContent,
  _ => gettingStartedContent,
};
