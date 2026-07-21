import 'package:flutter/services.dart';
import 'package:look_atlas/services/device/device_info.dart';

class DeviceInfoService {
  const DeviceInfoService({
    MethodChannel channel = const MethodChannel(
      'com.lookatlas/device_info',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  /// Returns the platform-native app/device identifier and basic OS metadata.
  ///
  /// Android uses `Settings.Secure.ANDROID_ID`. iOS uses an app-generated UUID
  /// stored in Keychain. Neither value is a permanent hardware identifier.
  Future<DeviceInfo> getDeviceInfo() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'getDeviceInfo',
    );
    if (result == null) {
      throw StateError('Native device info returned no data.');
    }
    return DeviceInfo.fromMap(result);
  }
}
