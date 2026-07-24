import 'dart:ui';

import 'package:look_atlas/core/network/api_endpoints.dart';
import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/storage/key_value_store.dart';
import 'package:look_atlas/services/device/device_info_service.dart';

class DeviceClientContext {
  const DeviceClientContext({
    required this.fingerprint,
    required this.uaFamily,
    required this.tzOffset,
    required this.screenHash,
    this.deviceToken,
  });

  final String fingerprint;
  final String uaFamily;
  final int tzOffset;
  final String screenHash;
  final String? deviceToken;

  Map<String, Object?> toRegistrationJson() => {
    'deviceFingerprint': fingerprint,
    'deviceToken': ?deviceToken,
    'uaFamily': uaFamily,
    'screenHash': screenHash,
    'tzOffset': tzOffset,
  };
}

class DeviceTokenService {
  const DeviceTokenService({
    required ApiService publicApi,
    required KeyValueStore store,
    required DeviceInfoService deviceInfo,
  }) : _publicApi = publicApi,
       _store = store,
       _deviceInfo = deviceInfo;

  static const _tokenKey = 'look_atlas_device_token';

  final ApiService _publicApi;
  final KeyValueStore _store;
  final DeviceInfoService _deviceInfo;

  Future<DeviceClientContext> context({bool bootstrapToken = true}) async {
    final info = await _deviceInfo.getDeviceInfo();
    final screenHash = _screenHash(info.deviceId);
    var token = _store.getString(_tokenKey);
    if (bootstrapToken && (token == null || token.isEmpty)) {
      final result = await _publicApi.post<String>(
        ApiEndpoints.deviceTokenBootstrap,
        data: {
          'fingerprint': info.deviceId,
          'tzOffset': DateTime.now().timeZoneOffset.inMinutes,
          'uaFamily': info.platform,
          'screenHash': screenHash,
        },
        decoder: (data) {
          final body = data is Map<String, dynamic>
              ? data
              : const <String, dynamic>{};
          final value = body['deviceToken'];
          if (value is! String || value.isEmpty) {
            throw const FormatException('Device token response is invalid.');
          }
          return value;
        },
      );
      token = result.valueOrNull;
      if (token != null) await _store.setString(_tokenKey, token);
    }
    return DeviceClientContext(
      fingerprint: info.deviceId,
      deviceToken: token,
      uaFamily: info.platform,
      screenHash: screenHash,
      tzOffset: DateTime.now().timeZoneOffset.inMinutes,
    );
  }

  static String _screenHash(String fallback) {
    final views = PlatformDispatcher.instance.views;
    final value = views.isEmpty
        ? fallback
        : '${views.first.physicalSize.width.round()}x'
              '${views.first.physicalSize.height.round()}@'
              '${views.first.devicePixelRatio}';
    final first = _hash32(value, 5381).toRadixString(16).padLeft(8, '0');
    final second = _hash32(value, 52711).toRadixString(16).padLeft(8, '0');
    return '$first$second';
  }

  static int _hash32(String value, int seed) {
    var hash = seed;
    for (final unit in value.codeUnits) {
      hash = (((hash << 5) + hash) ^ unit) & 0xffffffff;
    }
    return hash;
  }
}
