import Flutter
import UIKit

public class SwiftPluginScaffoldPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
    }
}

public func serializeError(error: Any?) -> FlutterError {
    let code = String(reflecting: type(of: error))
    if let error = error as? NSException {
        return FlutterError(code: code, message: error.reason, details: error.callStackSymbols.joined(separator: "\n"))
    } else {
        return FlutterError(code: code, message: nil, details: nil)
    }
}

public func trySend(result: @escaping FlutterResult, fn: (() -> Any?)? = nil) {
    var value: Any?
    PluginScaffoldHelper.tryCatch({
        if let fn = fn {
            value = fn()
        } else {
            value = nil
        }
    }, onCatch: {
        result(serializeError(error: $0))
    }, onElse: {
        result(value)
    })
}

public func createMethodChannel(name: String, messenger: FlutterBinaryMessenger, plugin: NSObject) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) in
        PluginScaffoldHelper.invokeMethod(
                call.method,
                instance: plugin,
                call: call,
                result: result,
                onCatch: {
                    serializeError(error: $0)
                }
        )
    })
}