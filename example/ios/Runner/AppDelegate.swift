import UIKit
import Flutter

class MyPlugin: NSObject {
  @objc func myFancyMethod(call: FlutterMethodCall, result: FlutterResult) {
    // trySend is not required, but serves as a precautionary measure against errors.
//        trySend(result) { "Hello from Kotlin!" }
  }
  @objc func myBrokenMethod(call: FlutterMethodCall, result: FlutterResult) {

  }
  @objc func myBrokenCallbackMethod(call: FlutterMethodCall, result: FlutterResult) {

  }
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
