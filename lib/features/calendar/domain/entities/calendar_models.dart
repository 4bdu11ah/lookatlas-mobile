import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';

typedef CalendarJson = Map<String, dynamic>;
CalendarJson calendarObject(Object? value) => contentObject(value);
List<CalendarJson> calendarObjects(Object? value) =>
    (value! as List).map(calendarObject).toList();

const calendarPlatforms = {
  'instagram': 'Instagram',
  'tiktok': 'TikTok',
  'facebook': 'Facebook',
  'pinterest': 'Pinterest',
};
const calendarFormats = {
  'single': 'Single post',
  'slideshow': 'Slideshow',
  'video': 'Video',
};
const calendarObjectives = [
  'Sell more products',
  'Launch a product',
  'Grow followers',
  'Post consistently',
  'Choose for me',
];
const calendarCadences = {
  '3_per_week': '3 posts a week',
  '5_per_week': '5 posts a week',
  'daily': 'Post every day',
};

class CalendarProduct {
  const CalendarProduct({
    required this.id,
    required this.name,
    required this.sku,
    this.thumbnail,
  });
  final String id;
  final String name;
  final String sku;
  final String? thumbnail;
}

class CalendarQuote {
  const CalendarQuote({
    required this.postCount,
    required this.totalCredits,
    required this.creditsRemaining,
    this.fitTotal,
    this.downgradedPosts,
  });
  final int postCount;
  final int totalCredits;
  final int creditsRemaining;
  final int? fitTotal;
  final int? downgradedPosts;
  bool get hasFitPreview => fitTotal != null && downgradedPosts != null;
}

class CalendarMutationResult {
  const CalendarMutationResult({
    required this.hasPlan,
    required this.hasItem,
    required this.creditWarning,
  });
  final bool hasPlan;
  final bool hasItem;
  final bool creditWarning;
}

class CalendarPlan {
  CalendarPlan(CalendarJson json) : json = Map.unmodifiable(json) {
    if (id.isEmpty ||
        !{
          'planning',
          'plan_failed',
          'plan_ready',
          'active',
          'archived',
        }.contains(status)) {
      throw const FormatException('Invalid plan');
    }
    if (objective.isEmpty ||
        !calendarCadences.containsKey(cadence) ||
        DateTime.tryParse(startsOn) == null ||
        DateTime.tryParse(endsOn) == null ||
        json['platforms'] is! List ||
        json['settings'] is! Map ||
        json['productModes'] is! Map ||
        json['chapters'] is! List ||
        !{'drafts', 'review', 'auto'}.contains(automation)) {
      throw const FormatException('Invalid plan fields');
    }
  }
  final CalendarJson json;
  String get id => json['id'] as String;
  String get status => json['status'] as String;
  String get objective => json['objective'] as String;
  String get cadence => json['cadence'] as String;
  String get startsOn => json['startsOn'] as String;
  String get endsOn => json['endsOn'] as String;
  String? get title => json['title'] as String?;
  String? get strategy => json['strategy'] as String?;
  List<String> get platforms => (json['platforms'] as List).cast<String>();
  CalendarJson get settings => calendarObject(json['settings']);
  CalendarJson get productModes => calendarObject(json['productModes']);
  List<CalendarJson> get chapters => calendarObjects(json['chapters']);
  String get automation => json['automationMode'] as String;
  bool get paused => json['productionPaused'] == true;
  bool get batch => settings['mode'] == 'batch';
  String? get revision => (settings['revision'] as Map?)?['status'] as String?;
}

class CalendarItem {
  CalendarItem(CalendarJson json) : json = Map.unmodifiable(json) {
    if (id.isEmpty ||
        !{
          'idea',
          'approved',
          'producing',
          'ready',
          'scheduled',
          'publishing',
          'published',
          'failed',
          'blocked',
          'skipped',
        }.contains(status)) {
      throw const FormatException('Invalid item');
    }
    if (!calendarFormats.containsKey(format) ||
        json['hook'] is! String ||
        json['position'] is! num ||
        json['platforms'] is! List ||
        (publishAt != null && DateTime.tryParse(publishAt!) == null)) {
      throw const FormatException('Invalid item fields');
    }
  }
  final CalendarJson json;
  String get id => json['id'] as String;
  String get status => json['status'] as String;
  String get format => json['format'] as String;
  String get hook => json['hook'] as String;
  String? get productId => json['productId'] as String?;
  String? get generationId => json['generationId'] as String?;
  String? get publishAt => json['publishAt'] as String?;
  DateTime? get localTime =>
      publishAt == null ? null : DateTime.parse(publishAt!).toLocal();
  String? get previewUrl => json['previewUrl'] as String?;
  String? get purpose => json['purpose'] as String?;
  String? get angle => json['angle'] as String?;
  String? get chapterKey => json['chapterKey'] as String?;
  String? get errorCode => json['errorCode'] as String?;
  int get position => (json['position'] as num).toInt();
  bool get locked => json['locked'] == true;
  List<String> get platforms => (json['platforms'] as List).cast<String>();
  List<CalendarJson> get publishedResults =>
      calendarObjects(json['publishedResults'] ?? <dynamic>[]);
  bool get editable => status == 'ready' || status == 'scheduled';
  bool get downloadable =>
      generationId != null &&
      {'ready', 'scheduled', 'publishing', 'published'}.contains(status);
  List<String> get actions => switch (status) {
    'idea' || 'approved' => ['swap', 'skip', if (publishAt == null) 'build'],
    'ready' => ['looks-good', 'skip'],
    'scheduled' => ['back-to-review', 'skip'],
    'failed' || 'blocked' => ['retry', 'skip'],
    'skipped' => ['unskip'],
    _ => [],
  };
  String label({required bool drafts}) => switch (status) {
    'producing' => 'Creating',
    'ready' => 'Needs approval',
    'scheduled' || 'publishing' => drafts ? 'Approved' : 'Scheduled',
    'published' => 'Published',
    'failed' => 'Needs attention',
    'blocked' =>
      errorCode == 'NEEDS_CREDITS' ? 'Needs credits' : 'Needs attention',
    'skipped' => 'Skipped',
    _ => 'Planned',
  };
}

class CalendarOverview {
  CalendarOverview(this.json)
    : plan = json['plan'] == null
          ? null
          : CalendarPlan(calendarObject(json['plan'])),
      items = calendarObjects(json['items']).map(CalendarItem.new).toList(),
      rollup = calendarObject(json['rollup']),
      estimate = calendarObject(json['estimate']),
      connections = calendarObjects(json['connections']),
      credits = (json['creditsRemaining'] as num?)?.toInt(),
      productCount = (json['productCount'] as num).toInt(),
      unlimitedImages = json['unlimitedImages'] as bool,
      videoEligible = json['videoEligible'] as bool,
      unitCosts = json['unitCosts'] == null
          ? null
          : calendarObject(json['unitCosts']),
      publishingAvailable =
          json['publishingAvailable'] as bool? ??
          calendarObjects(json['connections'])
              .any((c) => c['available'] == true) {
    if (!json.containsKey('plan') ||
        estimate['total'] is! num ||
        estimate['remainingTotal'] is! num ||
        rollup['needsReview'] is! num) {
      throw const FormatException('Invalid overview');
    }
    for (final key in [
      'needsReview',
      'producing',
      'queuedForProduction',
      'scheduled',
      'published',
      'failed',
      'blocked',
    ]) {
      if (rollup[key] is! num) throw const FormatException('Invalid rollup');
    }
    for (final connection in connections) {
      if (connection['platform'] is! String ||
          connection['status'] is! String ||
          connection['available'] is! bool) {
        throw const FormatException('Invalid connection');
      }
    }
  }
  final CalendarJson json;
  final CalendarPlan? plan;
  final List<CalendarItem> items;
  final CalendarJson rollup;
  final CalendarJson estimate;
  final List<CalendarJson> connections;
  final CalendarJson? unitCosts;
  final int? credits;
  final int productCount;
  final bool unlimitedImages;
  final bool videoEligible;
  final bool publishingAvailable;
  bool get drafts => !publishingAvailable || plan?.automation == 'drafts';
  int count(String key) => (rollup[key] as num).toInt();
  int selectedCost(Set<String> selected) => items
      .where((i) => i.status != 'skipped' && selected.contains(i.id))
      .fold(0, (total, item) {
        if (unlimitedImages && item.format != 'video') return total;
        // Explicit legacy fallback documented by the API guide.
        return total +
            ((unitCosts?[item.format] ??
                        {
                          'single': 2,
                          'slideshow': 10,
                          'video': 10,
                        }[item.format])
                    as num)
                .toInt();
      });
  Duration? get pollDelay {
    if (plan?.status == 'planning' || plan?.revision == 'applying') {
      return const Duration(milliseconds: 1500);
    }
    if (plan?.status != 'active') return null;
    final moving =
        count('producing') > 0 ||
        items.any((i) => i.status == 'publishing') ||
        (plan?.paused != true &&
            (count('queuedForProduction') + count('blocked') > 0)) ||
        (!drafts && count('scheduled') > 0);
    return moving ? const Duration(seconds: 5) : null;
  }
}

class CalendarSetup {
  String objective = 'Post consistently';
  String cadence = '5_per_week';
  String mode = 'scheduled';
  int horizonDays = 30;
  int batchCount = 10;
  List<String> platforms = ['instagram', 'facebook'];
  CalendarJson productModes = {};
  bool fitToCredits = true;
  String? get validation => platforms.isEmpty
      ? 'Choose at least one channel.'
      : objective == 'Launch a product' &&
            !productModes.containsValue('spotlight')
      ? 'Pick the product you’re launching above first.'
      : null;
  CalendarJson get quoteQuery => {
    'cadence': cadence,
    'objective': objective,
    if (mode == 'batch')
      'batchCount': batchCount
    else
      'horizonDays': horizonDays,
  };
  CalendarJson payload(String timeZone, {required bool overBudget}) => {
    'objective': objective,
    'cadence': cadence,
    'platforms': List<String>.of(platforms),
    'productModes': Map<String, dynamic>.of(productModes),
    'mode': mode,
    if (mode == 'batch')
      'batchCount': batchCount
    else
      'horizonDays': horizonDays,
    'timeZone': timeZone,
    'fitToCredits': overBudget && fitToCredits,
  };
  void prefill(CalendarPlan plan, {bool rollover = false}) {
    objective = plan.objective;
    cadence = plan.cadence;
    platforms = List.of(plan.platforms);
    productModes = Map.of(plan.productModes);
    if (!rollover) {
      mode = plan.batch ? 'batch' : 'scheduled';
      horizonDays = (plan.settings['horizonDays'] as num?)?.toInt() ?? 30;
      batchCount = (plan.settings['batchCount'] as num?)?.toInt() ?? 10;
    } else {
      mode = 'scheduled';
      horizonDays = 30;
    }
  }
}

String calendarDateKey(DateTime date) {
  final d = date.toLocal();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String calendarLocalInput(DateTime date) {
  final d = date.toLocal();
  return '${calendarDateKey(d)}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

DateTime? calendarParseInput(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$').hasMatch(value)) return null;
  final d = DateTime.tryParse(value);
  return d != null && calendarLocalInput(d) == value ? d : null;
}

DateTime calendarDefaultTime(DateTime day, DateTime now) {
  final eleven = DateTime(day.year, day.month, day.day, 11);
  final earliest = now.add(const Duration(hours: 1));
  return eleven.isAfter(earliest)
      ? eleven
      : DateTime(
          earliest.year,
          earliest.month,
          earliest.day,
          earliest.hour,
          earliest.minute + 1,
        );
}

String? calendarTimeError(String value, CalendarPlan plan, DateTime now) {
  final d = calendarParseInput(value);
  if (d == null) return 'Enter a complete date and time.';
  if (!d.isAfter(now)) return 'Choose a future posting time.';
  final key = calendarDateKey(d);
  if (key.compareTo(plan.startsOn) < 0 || key.compareTo(plan.endsOn) > 0) {
    return 'Choose a date within this plan.';
  }
  return null;
}

class CalendarDay {
  CalendarDay(this.date, this.items, {required this.addable});
  final DateTime date;
  final List<CalendarItem> items;
  final bool addable;
}

List<CalendarDay> calendarDays(CalendarOverview overview, DateTime now) {
  final plan = overview.plan!;
  final start = DateTime.parse(plan.startsOn);
  final first = DateTime(
    start.year,
    start.month,
    start.day - (start.weekday - 1),
  );
  final items =
      overview.items
          .where((i) => i.publishAt != null && i.status != 'skipped')
          .toList()
        ..sort((a, b) => a.localTime!.compareTo(b.localTime!));
  return List.generate(42, (index) {
    final date = DateTime(first.year, first.month, first.day + index);
    final key = calendarDateKey(date);
    final posts = items
        .where((i) => calendarDateKey(i.localTime!) == key)
        .toList();
    return CalendarDay(
      date,
      posts,
      addable:
          posts.isEmpty &&
          key.compareTo(plan.startsOn) >= 0 &&
          key.compareTo(plan.endsOn) <= 0 &&
          DateTime(
            date.year,
            date.month,
            date.day + 1,
          ).isAfter(now.add(const Duration(hours: 1))),
    );
  });
}

String calendarError(String? code) => switch (code) {
  'NEEDS_CREDITS' => 'Not enough credits to create this post. It will resume when credits are available.',
  'NO_PRODUCTS' => 'We need at least one product with photos to plan a month.',
  'PLANNING_FAILED' => 'We couldn’t write your month just now. Try again.',
  'NO_CONNECTION' =>
    'No connected account. Download the post or choose drafts only.',
  'PUBLISH_FAILED' => 'Publishing failed. Try again or download the post.',
  'FEATURE_NOT_AVAILABLE' => 'Video posts need a Pro or Business plan.',
  _ => 'Something went wrong. Please try again.',
};
