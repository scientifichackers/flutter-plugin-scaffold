import Flutter
import Flutter.FlutterChannels
import os.log

let logTag = "PluginScaffold"
let onListen = "OnListen"
let onCancel = "OnCancel"
let onSuccess = "onSuccess"
let onError = "onError"
let endOfStream = "endOfStream"

typealias PluginFunc = (FlutterMethodCall, @escaping FlutterResult) -> Void
typealias PluginFuncThrows = (FlutterMethodCall, @escaping FlutterResult) throws -> Void
typealias OnListen = (Int, Any?, @escaping FlutterEventSink) -> Void
typealias OnListenThrows = (Int, Any?, @escaping FlutterEventSink) throws -> Void
typealias OnCancel = (Int, Any?) -> Void
typealias OnCancelThrows = (Int, Any?) throws -> Void

public class SwiftPluginScaffoldPlugin: NSObject, FlutterPlugin {
    public static func register(with _: FlutterPluginRegistrar) {}
}

public func serializeError(_ error: Any) -> FlutterError {
    let code = String(reflecting: error)
    let stacktrace = Thread.callStackSymbols.joined(separator: "\n")
    print("D/\(logTag): piping exception to flutter (\(code))")
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

public func createPluginScaffold(messenger: FlutterBinaryMessenger, channelName: String, methodMap: [String: Any]) -> FlutterMethodChannel {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        catchErrors(result) {
            let name = call.method
            let args = call.arguments

            guard let method = methodMap[name] else {
                result(FlutterMethodNotImplemented)
                return
            }

            if name.hasSuffix(onListen) {
                let streamName = name.prefix(name.count - onListen.count)
                let args = args as! [Any?]
                let hashCode = args[0] as! Int
                let streamArgs = args[1]
                let prefix = "\(streamName)/\(hashCode)"

                let msg = "D/\(logTag): activate stream { channel: \(channelName), stream: \(streamName), hashCode: \(hashCode), args: \(String(describing: streamArgs)) }"

                let sink: FlutterEventSink = { event in
                    switch event {
                    case let event as FlutterError:
                        channel.invokeMethod("\(prefix)/\(onError)", arguments: [event.code, event.message, event.details])
                        return
                    case let event as NSObject:
                        if event == FlutterEndOfEventStream {
                            channel.invokeMethod("\(prefix)/\(endOfStream)", arguments: nil)
                            return
                        }
                    default:
                        break
                    }
                    channel.invokeMethod("\(prefix)/\(onSuccess)", arguments: event)
                }

                switch method {
                case let method as OnListen:
                    print(msg)
                    method(hashCode, streamArgs, sink)
                    return
                case let method as OnListenThrows:
                    print(msg)
                    catchErrors(result) { try method(hashCode, streamArgs, sink) }
                    return
                default:
                    print("W/\(logTag): The method: \(method) must be of type \(OnListen.self) or \(OnListenThrows.self)")
                }
            }

            if name.hasSuffix(onCancel) {
                let streamName = name.prefix(name.count - onListen.count)
                let args = args as! [Any?]
                let hashCode = args[0] as! Int
                let streamArgs = args[1]

                let msg = "D/\(logTag): de-activate stream { channel: \(channelName), stream: \(streamName), hashCode: \(hashCode), args: \(String(describing: streamArgs)) }"

                switch method {
                case let method as OnCancel:
                    print(msg)
                    method(hashCode, streamArgs)
                    return
                case let method as OnCancelThrows:
                    print(msg)
                    catchErrors(result) { try method(hashCode, streamArgs) }
                    return
                default:
                    print("W/\(logTag): The method: \(method) must be of type \(OnCancel.self) or \(OnCancelThrows.self)")
                }
            }

            let msg = "D/\(logTag): invoking { channel: \(channelName), method: \(name)(), args: \(String(describing: call.arguments)) }"

            switch method {
            case let method as PluginFunc:
                print(msg)
                method(call, result)
                return
            case let method as PluginFuncThrows:
                print(msg)
                catchErrors(result) { try method(call, result) }
                return
            default:
                print("W/\(logTag): The method: \(method) must be of type \(PluginFunc.self) or \(PluginFuncThrows.self)")
            }

            result(FlutterMethodNotImplemented)
        }
    }

    return channel
}
