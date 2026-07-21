import Flutter
import Security
import UIKit

enum NativeDeviceInfoChannel {
  private static let channelName = "com.lookatlas/device_info"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler(handle)
  }

  private static func handle(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard call.method == "getDeviceInfo" else {
      result(FlutterMethodNotImplemented)
      return
    }

    do {
      let device = UIDevice.current
      result([
        "deviceId": try KeychainDeviceIdentifier.getOrCreate(),
        "identifierType": "keychainUuid",
        "platform": "ios",
        "manufacturer": "Apple",
        "model": hardwareModel(),
        "systemName": device.systemName,
        "systemVersion": device.systemVersion,
      ])
    } catch {
      result(
        FlutterError(
          code: "DEVICE_ID_UNAVAILABLE",
          message: "Keychain device ID is unavailable.",
          details: String(describing: error)
        )
      )
    }
  }

  private static func hardwareModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    return withUnsafeBytes(of: &systemInfo.machine) { buffer in
      let bytes = buffer.prefix { $0 != 0 }
      return String(bytes: bytes, encoding: .utf8) ?? UIDevice.current.model
    }
  }
}

private enum KeychainDeviceIdentifier {
  private static let service = "com.lookatlas.device-identifier"
  private static let account = "native-device-id"

  static func getOrCreate() throws -> String {
    if let identifier = try read() {
      return identifier
    }

    let identifier = UUID().uuidString.lowercased()
    try save(identifier)
    return identifier
  }

  private static func read() throws -> String? {
    var item: CFTypeRef?
    let status = SecItemCopyMatching(readQuery as CFDictionary, &item)

    if status == errSecItemNotFound {
      return nil
    }
    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }
    guard
      let data = item as? Data,
      let identifier = String(data: data, encoding: .utf8)
    else {
      throw KeychainError.invalidData
    }
    return identifier
  }

  private static func save(_ identifier: String) throws {
    var query = baseQuery
    query[kSecValueData as String] = Data(identifier.utf8)
    query[kSecAttrAccessible as String] =
      kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }
  }

  private static var baseQuery: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }

  private static var readQuery: [String: Any] {
    var query = baseQuery
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    query[kSecReturnData as String] = true
    return query
  }
}

private enum KeychainError: Error {
  case invalidData
  case unexpectedStatus(OSStatus)
}
