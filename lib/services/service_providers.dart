import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => createAnalyticsService(),
);
