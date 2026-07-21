import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "NativeDeviceInfoChannel") {
      NativeDeviceInfoChannel.register(with: registrar.messenger())
    }
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.lookatlas/external_url",
        binaryMessenger: controller.binaryMessenger
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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
