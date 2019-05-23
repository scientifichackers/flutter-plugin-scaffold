import Flutter
import os.log

let logTag = "PluginScaffold"

typealias PluginFunc = ((FlutterMethodCall, @escaping FlutterResult) -> Void)
typealias PluginFuncThrows = ((FlutterMethodCall, @escaping FlutterResult) throws -> Void)

public class SwiftPluginScaffoldPlugin: NSObject, FlutterPlugin {
    public static func register(with _: FlutterPluginRegistrar) {}
}

public func serializeError(_ error: Any) -> FlutterError {
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

public func catchErrors(_ sendFn: @escaping (Any?) -> Void, _ fn: @escaping () throws -> Void) {
    PluginScaffoldHelper.tryCatch(
        {
            do {
                try fn()
            } catch {
                sendFn(serializeError(error))
            }
        },
        onCatch: {
            if let error = $0 {
                sendFn(serializeError(error))
            }
        },
        onElse: {}
    )
}

public func trySend(_ sendFn: @escaping (Any?) -> Void, _ fn: (() throws -> Any?)? = nil) {
    var value: Any?
    PluginScaffoldHelper.tryCatch(
        {
            do {
                value = try fn?()
            } catch {
                sendFn(serializeError(error))
            }
        },
        onCatch: {
            if let error = $0 {
                sendFn(serializeError(error))
            }
        },
        onElse: {
            sendFn(value)
        }
    )
}

public func trySendError(_ sendFn: @escaping (Any?) -> Void, _ error: Error) {
    trySend(sendFn) {
        throw error
    }
}

public func createPluginScaffold(
    messenger: FlutterBinaryMessenger,
    channelName: String,
    methodMap: [String: Any] = [:],
    eventMap: [String: FlutterStreamHandler & NSObjectProtocol] = [:]
) -> (FlutterMethodChannel, [String: FlutterEventChannel]) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        catchErrors(result) {
            let methodName = call.method
            let method = methodMap[methodName]
            switch method {
            case let method as PluginFunc:
                print("D/\(logTag): invoking { channel: \(channelName), method: \(methodName)(), args: \(String(describing: call.arguments)) }")
                method(call, result)
            case let method as PluginFuncThrows:
                print("D/\(logTag): invoking { channel: \(channelName), method: \(methodName)(), args: \(String(describing: call.arguments)) }")
                do {
                    try method(call, result)
                } catch {
                    trySend(result) {
                        serializeError(error)
                    }
                }
            default:
                if method == nil {
                    print("E/\(logTag): The method: \(String(describing: method)) must be of type \(PluginFunc.self) or \(PluginFuncThrows.self)")
                }
                result(FlutterMethodNotImplemented)
                return
            }
        }
    }

    var eventChannels = [String: FlutterEventChannel]()
    for (name, handler) in eventMap {
        let name = channelName + "/" + name
        let eventChannel = FlutterEventChannel(name: name, binaryMessenger: messenger)
        eventChannel.setStreamHandler(handler)
        eventChannels[name] = eventChannel
    }

    return (channel, eventChannels)
}
