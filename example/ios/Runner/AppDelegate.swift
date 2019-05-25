import Flutter
import plugin_scaffold
import UIKit

enum MyError: Error {
    case fatalError1
    case fatalError3
    case fatalError4
}

class MyPlugin {
    var timers = [Int: Timer]()

    func myFancyMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result("Hello from Swift!")
    }

    func myBrokenMethod(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        throw MyError.fatalError1
    }

    func myBrokenCallbackMethod(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {_ in
                trySend(result) {
                    throw NSError(domain: "Error from swift 2", code: 999)
                }
            }
        }
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

    func brokenStream1OnListen(id: Int, args: Any?, sink: @escaping FlutterEventSink) throws {
        throw MyError.fatalError3
    }

    func brokenStream1OnCancel(id: Int, args: Any?) {}

    func brokenStream2OnListen(id: Int, args: Any?, sink: @escaping FlutterEventSink) {
        trySend(sink) { throw MyError.fatalError4 }
    }

    func brokenStream2OnCancel(id: Int, args: Any?) {}
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
                "brokenStream1OnListen": plugin.brokenStream1OnListen,
                "brokenStream1OnCancel": plugin.brokenStream1OnCancel,
                "brokenStream2OnListen": plugin.brokenStream2OnListen,
                "brokenStream2OnCancel": plugin.brokenStream2OnCancel,
            ]
        )

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
