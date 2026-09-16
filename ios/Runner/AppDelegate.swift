import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "NativeDeviceInfoChannel"
    ) {
      NativeDeviceInfoChannel.register(with: registrar.messenger())
    }
    let messenger = engineBridge.applicationRegistrar.messenger()
    registerCalendarChannel(with: messenger)
    registerExternalUrlChannel(with: messenger)
    registerImageSaveChannel(with: messenger)
  }

  private func registerCalendarChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.lookatlas/calendar",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "timeZone" {
        result(TimeZone.current.identifier)
        return
      }
      if call.method == "openPublished",
         let arguments = call.arguments as? [String: Any],
         let rawUrl = arguments["url"] as? String,
         let url = URL(string: rawUrl),
         url.scheme == "https" {
        UIApplication.shared.open(url) { opened in
          opened ? result(nil) : result(FlutterError(
            code: "OPEN_FAILED",
            message: "Could not open published post.",
            details: nil
          ))
        }
        return
      }
      result(FlutterMethodNotImplemented)
    }
  }

  private func registerExternalUrlChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.lookatlas/external_url",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "open" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let arguments = call.arguments as? [String: Any]
      guard
        let rawUrl = arguments?["url"] as? String,
        let url = URL(string: rawUrl),
        (url.scheme == "https" && url.host == "checkout.stripe.com") ||
          (url.scheme == "lookatlas" && [
            "/onboarding/success",
            "/onboarding/activate"
          ].contains(url.path))
      else {
        result(FlutterError(
          code: "UNTRUSTED_URL",
          message: "Checkout URL is not trusted.",
          details: nil
        ))
        return
      }
      UIApplication.shared.open(url) { opened in
        opened ? result(nil) : result(FlutterError(
          code: "OPEN_FAILED",
          message: "Could not open checkout.",
          details: nil
        ))
      }
    }
  }

  private func registerImageSaveChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.lookatlas/image_save",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "save" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.saveImage(call: call, result: result)
    }
  }

  private func saveImage(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    guard
      let typedData = arguments?["bytes"] as? FlutterStandardTypedData,
      !typedData.data.isEmpty,
      let fileName = arguments?["fileName"] as? String,
      !fileName.isEmpty
    else {
      result(FlutterError(
        code: "INVALID_IMAGE",
        message: "Image data is invalid.",
        details: nil
      ))
      return
    }

    requestPhotoAddAccess { granted in
      guard granted else {
        result(FlutterError(
          code: "PHOTO_ACCESS_DENIED",
          message: "Photo library access was denied.",
          details: nil
        ))
        return
      }
      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetCreationRequest.forAsset()
        let options = PHAssetResourceCreationOptions()
        options.originalFilename = fileName
        request.addResource(with: .photo, data: typedData.data, options: options)
      }) { saved, error in
        DispatchQueue.main.async {
          if saved {
            result(nil)
          } else {
            result(FlutterError(
              code: "SAVE_FAILED",
              message: "Could not save image.",
              details: error?.localizedDescription
            ))
          }
        }
      }
    }
  }

  private func requestPhotoAddAccess(completion: @escaping (Bool) -> Void) {
    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      if status == .notDetermined {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { next in
          DispatchQueue.main.async {
            completion(next == .authorized || next == .limited)
          }
        }
      } else {
        completion(status == .authorized || status == .limited)
      }
      return
    }
    let status = PHPhotoLibrary.authorizationStatus()
    if status == .notDetermined {
      PHPhotoLibrary.requestAuthorization { next in
        DispatchQueue.main.async {
          completion(next == .authorized)
        }
      }
    } else {
      completion(status == .authorized)
    }
  }
}
