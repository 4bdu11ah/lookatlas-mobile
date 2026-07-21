class DeviceInfo {
  const DeviceInfo({
    required this.deviceId,
    required this.identifierType,
    required this.platform,
    required this.manufacturer,
    required this.model,
    required this.systemName,
    required this.systemVersion,
    this.apiLevel,
  });

  factory DeviceInfo.fromMap(Map<String, Object?> map) {
    return DeviceInfo(
      deviceId: _requiredValue<String>(map, 'deviceId'),
      identifierType: _requiredValue<String>(map, 'identifierType'),
      platform: _requiredValue<String>(map, 'platform'),
      manufacturer: _requiredValue<String>(map, 'manufacturer'),
      model: _requiredValue<String>(map, 'model'),
      systemName: _requiredValue<String>(map, 'systemName'),
      systemVersion: _requiredValue<String>(map, 'systemVersion'),
      apiLevel: _optionalValue<int>(map, 'apiLevel'),
    );
  }

  final String deviceId;
  final String identifierType;
  final String platform;
  final String manufacturer;
  final String model;
  final String systemName;
  final String systemVersion;
  final int? apiLevel;
}

T _requiredValue<T>(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is T) {
    return value;
  }
  throw FormatException('Invalid or missing native device field: $key');
}

T? _optionalValue<T>(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null || value is T) {
    return value as T?;
  }
  throw FormatException('Invalid native device field: $key');
}
