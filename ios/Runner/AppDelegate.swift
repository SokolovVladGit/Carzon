import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let scannerRegistrar = registrar(forPlugin: "CarzonVinScanner") {
      VinScannerPlugin.register(with: scannerRegistrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
