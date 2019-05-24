import Flutter
import plugin_scaffold
import UIKit

enum MyError: Error {
    case fatalError1
    case fatalError2
}

class MyPlugin {
    var timers = [Int: Timer]()

    func myFancyMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // trySend is not required, but serves as a precautionary measure against errors.
        trySend(result) { "Hello from Swift!" }
    }

    func myBrokenMethod(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        throw MyError.fatalError1
    }

    func myBrokenCallbackMethod(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        throw NSError(domain: "hello", code: 123)
    }

    func counterOnListen(id: Int, args: Any?, sink: @escaping FlutterEventSink) {
        var count = 0
        if #available(iOS 10.0, *) {
            timers[id] = Timer.scheduledTimer(withTimeInterval: args as! Double / 1000, repeats: true) {
                sink(count)
                if count >= 100 {
                    sink(FlutterEndOfEventStream)
                    $0.invalidate()
                }
                count += 1
            }
        }
    }

    func counterOnCancel(id: Int, args: Any?) {
        timers[id]?.invalidate()
        timers.removeValue(forKey: id)
    }

    func brokenOnListen(id: Int, args: Any?, sink: @escaping FlutterEventSink) throws {
        throw MyError.fatalError2
    }

    func brokenOnCancel(id: Int, args: Any?) {}
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    ) -> Bool {
        let messenger = window?.rootViewController as! FlutterBinaryMessenger

        let plugin = MyPlugin()
        
        // unfortunately, swift just isn't dynamic enough to make full-scale dynamic dispatch possible :(
        _ = createPluginScaffold(
            messenger: messenger,
            channelName: "myFancyChannel",
            methodMap: [
                "myFancyMethod": plugin.myFancyMethod,
                "myBrokenMethod": plugin.myBrokenMethod,
                "myBrokenCallbackMethod": plugin.myBrokenCallbackMethod,
                "counterOnListen": plugin.counterOnListen,
                "counterOnCancel": plugin.counterOnCancel,
                "brokenOnListen": plugin.brokenOnListen,
                "brokenOnCancel": plugin.brokenOnCancel,
            ]
        )

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
