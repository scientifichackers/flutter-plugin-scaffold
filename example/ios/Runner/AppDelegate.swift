import Flutter
import plugin_scaffold
import UIKit

enum MyError: Error {
    case fatalError
}

func myFancyMethod(call _: FlutterMethodCall, result: @escaping FlutterResult) {
    // trySend is not required, but serves as a precautionary measure against errors.
    trySend(result) {
        "Hello from Swift!"
    }
}

func myBrokenMethod(call _: FlutterMethodCall, result _: @escaping FlutterResult) throws {
    throw MyError.fatalError
}

func myBrokenCallbackMethod(call _: FlutterMethodCall, result _: @escaping FlutterResult) throws {
    throw NSError(domain: "hello", code: 123)
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    ) -> Bool {
        let messenger = window?.rootViewController as! FlutterBinaryMessenger

        // unfortunately, swift just isn't dynamic enough to make full-scale dynamic dispatch possible :(
        createPluginScaffold(
            messenger: messenger,
            channelName: "myFancyChannel",
            methodMap: [
                "myFancyMethod": myFancyMethod,
                "myBrokenMethod": myBrokenMethod,
                "myBrokenCallbackMethod": myBrokenCallbackMethod,
            ]
        )

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
