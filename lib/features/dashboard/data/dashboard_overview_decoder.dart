import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_overview.dart';

DashboardOverview decodeDashboardOverview(dynamic data) {
  if (data is! Map<String, dynamic> ||
      data['credits'] is! Map<String, dynamic> ||
      data['activity'] is! Map<String, dynamic>) {
    throw const FormatException('Invalid dashboard overview response.');
  }
  final credits = _map(data['credits']);
  final activity = _map(data['activity']);
  final activation = _map(data['activation']);
  final products = _map(data['products']);
  final models = _map(data['modelPanel']);
  final panels = _map(data['panelStatus']);
  return DashboardOverview(
    credits: DashboardStats(
      credits: _integer(credits['remaining']),
      creditsTotal: _integer(credits['total']),
      creditsUsed: _integer(credits['used']),
      totalRenders: 0,
      activeJobs: _integer(activity['activeCount']),
      completedJobs: _integer(activity['readyCount']),
    ),
    activity: _activity(activity),
    activation: DashboardActivation(
      stage: DashboardActivationStage.values.firstWhere(
        (stage) => stage.name == activation['stage'],
        orElse: () => DashboardActivationStage.setup,
      ),
      firstShootId: _nullableString(activation['firstShootId']),
      currentStep: activation['currentStep'] is num
          ? (activation['currentStep'] as num).toInt()
          : null,
      completedStepCount: _integer(activation['completedStepCount']),
      activatedAt: _date(activation['activatedAt']),
    ),
    products: DashboardCollection(
      title: 'Your product library',
      total: _integer(products['total']),
      items: [
        for (final item in _items(products['newestTwo']).take(2))
          DashboardCollectionItem(
            id: _string(item['id']),
            name: _string(item['name']),
            thumbnail: _string(item['thumbnail']),
            description: _description([item['sku'], item['category']]),
          ),
      ],
    ),
    models: DashboardCollection(
      title: _nullableString(models['title']) ?? 'Your models',
      total: _integer(models['total']),
      items: [
        for (final item in _items(models['models']).take(2))
          DashboardCollectionItem(
            id: _string(item['id']),
            name: _string(item['name']),
            thumbnail: _string(item['thumbnail']),
            description: _description([item['height'], item['description']]),
            featured: item['source'] == 'lookatlas',
          ),
      ],
    ),
    panelStatus: DashboardPanelStatus(
      activityError: _map(panels['activity'])['state'] == 'error',
      productsError: _map(panels['products'])['state'] == 'error',
      modelsError: _map(panels['models'])['state'] == 'error',
    ),
    ownedShootId: _nullableString(_map(data['retention'])['ownedShootId']),
  );
}

DashboardActivity _activity(Map<String, dynamic> data) => DashboardActivity(
  activeCount: _integer(data['activeCount']),
  readyCount: _integer(data['readyCount']),
  active: _jobs(data['active']),
  ready: _jobs(data['ready']),
  recentCompleted: _jobs(data['recentCompleted']),
);

List<DashboardRecentJob> _jobs(Object? data) => [
  for (final job in _items(data))
    DashboardRecentJob(
      id: _string(job['id']),
      name: _nullableString(job['name']) ?? 'Untitled shoot',
      status: _nullableString(job['status']) ?? 'pending',
      renders: _integer(job['deliveredImageCount'] ?? job['renders']),
      productThumbnail: _string(job['productThumbnail']),
      modelThumbnail: _string(job['modelThumbnail']),
      heroImage: _string(job['heroImage']),
      progress: _integer(job['progress']).clamp(0, 100),
      currentStep: _nullableString(job['currentStep']),
      date: _date(job['createdAt']),
      updatedAt: _date(job['updatedAt']),
      completedAt: _date(job['completedAt']),
      reviewedAt: _date(job['reviewedAt']),
      estimatedCompletion: _date(job['estimatedCompletion']),
    ),
];

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};
Iterable<Map<String, dynamic>> _items(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>() : const [];
int _integer(Object? value) => value is num ? value.toInt() : 0;
String _string(Object? value) => value is String ? value : '';
String? _nullableString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
String _description(List<Object?> values) =>
    values.map(_string).where((value) => value.isNotEmpty).join(' • ');
