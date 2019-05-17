import Flutter
import UIKit

public class SwiftPluginScaffoldPlugin: NSObject, FlutterPlugin {
    public static func register(with _: FlutterPluginRegistrar) {
    }
}

public func serializeError(error: Any) -> FlutterError {
    let code = String(reflecting: error)
    let stacktrace = Thread.callStackSymbols.joined(separator: "\n")
    if let error = error as? NSException {
        return FlutterError(
                code: code,
                message: error.reason,
                details: error.callStackSymbols.joined(separator: "\n")
        )
    } else if let error = error as? NSError {
        return FlutterError(code: code, message: error.localizedDescription, details: stacktrace)
    } else if let error = error as? Error {
        return FlutterError(code: code, message: error.localizedDescription, details: stacktrace)
    } else {
        return FlutterError(code: code, message: nil, details: stacktrace)
    }
}

public typealias AnyFunc = () -> Any?

public func trySend(_ result: @escaping FlutterResult, _ fn: AnyFunc? = nil) {
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


public func createMethodChannel(name: String, messenger: FlutterBinaryMessenger, funcMap: [String: Any]) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        PluginScaffoldHelper.tryCatch({
            if let fn = funcMap[call.method] {
                if let fn = fn as? ((FlutterMethodCall, @escaping FlutterResult) -> ()) {
                    fn(call, result)
                    return
                } else if let fn = fn as? ((FlutterMethodCall, @escaping FlutterResult) throws -> ()) {
                    do {
                        try fn(call, result)
                    } catch {
                        trySend(result) {
                            serializeError(error: error)
                        }
                    }
                    return
                }
            }
            result(FlutterMethodNotImplemented)
        }, onCatch: {
            result(serializeError(error: $0))
        }, onElse: {})
    }
}
