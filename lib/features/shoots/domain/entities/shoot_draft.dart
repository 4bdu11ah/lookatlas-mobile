class ShootDraftSummary {
  const ShootDraftSummary({
    required this.id,
    required this.title,
    required this.currentStep,
    required this.updatedAt,
    this.thumbnailUrl = '',
  });

  final String id;
  final String title;
  final String currentStep;
  final String thumbnailUrl;
  final DateTime updatedAt;

  int get stepNumber => switch (currentStep) {
    'model' => 2,
    'director' => 3,
    'planning' => 4,
    'confirm' => 5,
    _ => 1,
  };

  String get stepLabel => switch (currentStep) {
    'model' => 'Model',
    'director' => 'Creative Director',
    'planning' => 'Shot Planning',
    'confirm' => 'Review',
    _ => 'Product',
  };
}

class ShootDraft {
  const ShootDraft({required this.summary, required this.snapshot});

  final ShootDraftSummary summary;
  final ShootDraftSnapshot snapshot;
}

class ShootDraftSnapshot {
  const ShootDraftSnapshot({
    this.currentStep = 'product',
    this.productMode = 'pairing',
    this.selectedProductIds = const [],
    this.selectedModelIds = const [],
    this.productOnly = false,
    this.directorId,
    this.demoMode = false,
    this.demoDirectors = const [],
    this.useLibraryModels = false,
    this.settings = const {},
    this.plannedShots = const [],
    this.selectedShots = const [],
  });

  factory ShootDraftSnapshot.fromJson(Map<String, dynamic> json) =>
      ShootDraftSnapshot(
        currentStep: _string(json['currentStep'], fallback: 'product'),
        productMode: _string(json['productMode'], fallback: 'pairing'),
        selectedProductIds: _strings(json['selectedProductIds']),
        selectedModelIds: _strings(
          json['selectedModelIds'] ?? json['selectedModelKeys'],
        ),
        productOnly: json['productOnly'] as bool? ?? false,
        directorId: _nullableString(json['directorId']),
        demoMode: json['demoMode'] as bool? ?? false,
        demoDirectors: _maps(json['demoDirectors']),
        useLibraryModels: json['useLibraryModels'] as bool? ?? false,
        settings: _map(json['settings']),
        plannedShots: _maps(json['plannedShots']),
        selectedShots: _ints(json['selectedShots']),
      );

  final String currentStep;
  final String productMode;
  final List<String> selectedProductIds;
  final List<String> selectedModelIds;
  final bool productOnly;
  final String? directorId;
  final bool demoMode;
  final List<Map<String, dynamic>> demoDirectors;
  final bool useLibraryModels;
  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> plannedShots;
  final List<int> selectedShots;

  Map<String, dynamic> toJson() => {
    'currentStep': currentStep,
    'productMode': productMode,
    'selectedProductIds': selectedProductIds,
    'selectedModelIds': selectedModelIds,
    'productOnly': productOnly,
    'directorId': ?directorId,
    'demoMode': demoMode,
    'demoDirectors': demoDirectors,
    'useLibraryModels': useLibraryModels,
    'settings': settings,
    'plannedShots': plannedShots,
    'selectedShots': selectedShots,
  };
}

class ShootDraftMirror {
  const ShootDraftMirror({
    required this.snapshot,
    required this.updatedAt,
    this.draftId,
    this.title = 'Untitled shoot',
    this.thumbnailUrl = '',
  });

  factory ShootDraftMirror.fromJson(Map<String, dynamic> json) {
    final rawState = json['state'];
    return ShootDraftMirror(
      draftId: _nullableString(json['draftId']),
      title: _string(json['title'], fallback: 'Untitled shoot'),
      thumbnailUrl: _string(json['thumbnailUrl']),
      snapshot: ShootDraftSnapshot.fromJson(_map(rawState)),
      updatedAt:
          DateTime.tryParse(_string(json['updatedAt']))?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String? draftId;
  final String title;
  final String thumbnailUrl;
  final ShootDraftSnapshot snapshot;
  final DateTime updatedAt;

  static String storageKey(String userId) =>
      'lookatlas:create-shoot:mirror:$userId';

  Map<String, dynamic> toJson() => {
    'draftId': ?draftId,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'state': snapshot.toJson(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

Map<String, dynamic> _map(Object? raw) => raw is Map
    ? raw.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? raw) => raw is List
    ? [
        for (final item in raw)
          if (item is Map) _map(item),
      ]
    : const [];

List<String> _strings(Object? raw) => raw is List
    ? [
        for (final item in raw)
          if (item is String) item,
      ]
    : const [];

List<int> _ints(Object? raw) => raw is List
    ? [
        for (final item in raw)
          if (item is num) item.toInt(),
      ]
    : const [];

String _string(Object? raw, {String fallback = ''}) =>
    raw is String && raw.isNotEmpty ? raw : fallback;

String? _nullableString(Object? raw) =>
    raw is String && raw.isNotEmpty ? raw : null;
