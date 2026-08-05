import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/services/analytics/analytics_service.dart';
import 'package:look_atlas/services/analytics/backend_analytics_service.dart';
import 'package:look_atlas/services/device/device_info_service.dart';
import 'package:look_atlas/services/device/device_token_service.dart';
import 'package:look_atlas/services/external_url_service.dart';
import 'package:look_atlas/services/image_save_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final backend = BackendAnalyticsService(
    ref.watch(apiServiceProvider),
    tokenProvider: ref.watch(authTokenCacheProvider).get,
  );
  ref.onDispose(() => unawaited(backend.dispose()));
  return CompositeAnalyticsService([createAnalyticsService(), backend]);
});

final deviceInfoServiceProvider = Provider<DeviceInfoService>(
  (ref) => const DeviceInfoService(),
);

final deviceTokenServiceProvider = Provider<DeviceTokenService>(
  (ref) => DeviceTokenService(
    publicApi: ref.watch(publicApiServiceProvider),
    store: ref.watch(keyValueStoreProvider),
    deviceInfo: ref.watch(deviceInfoServiceProvider),
  ),
);

final externalUrlServiceProvider = Provider<ExternalUrlService>(
  (ref) => const ExternalUrlService(),
);

final imageSaveServiceProvider = Provider<ImageSaveService>(
  (ref) => const ImageSaveService(),
);
