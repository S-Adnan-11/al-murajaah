import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var supportChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AlMurajaahSupport") else { return }
    let channel = FlutterMethodChannel(name: "dev.almurajaah/support", binaryMessenger: registrar.messenger())
    supportChannel = channel
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "publicVersion":
        result(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
      case "feedbackDetails":
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        result(["appVersion": "\(version)+\(build)", "manufacturer": "Apple", "model": "\(UIDevice.current.model) · iOS \(UIDevice.current.systemVersion)"])
      case "openWebsite":
        guard let text = call.arguments as? String,
              text == "https://s-adnan.dev" || text == "https://github.com/S-Adnan-11",
              let url = URL(string: text) else {
          result(FlutterError(code: "invalid_website", message: "Website unavailable.", details: nil)); return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
          if opened { result(nil) }
          else { result(FlutterError(code: "website_unavailable", message: "Website could not be opened.", details: nil)) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
