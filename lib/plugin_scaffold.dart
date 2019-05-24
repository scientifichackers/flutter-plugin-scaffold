import 'dart:async';

import 'package:flutter/services.dart';

typedef void MethodCallHandler(dynamic args);

class PluginScaffold {
  static const onListen = "OnListen";
  static const onCancel = "OnCancel";
  static const onSuccess = "onSuccess";
  static const onError = "onError";
  static const endOfStream = "endOfStream";

  static final callHandlers = <String, List<MethodCallHandler>>{};

  static void setMethodCallHandler(
    MethodChannel channel,
    String methodName,
    MethodCallHandler handler,
  ) {
    channel.setMethodCallHandler((call) {
      final key = channel.name + call.method;
      final handlers = callHandlers[key];
      for (var handler in handlers) {
        handler(call.arguments);
      }
    });
    final key = channel.name + methodName;
    callHandlers.putIfAbsent(key, () => []);
    callHandlers[key].add(handler);
  }

  static void removeMethodCallHandler(MethodCallHandler handler) {
    callHandlers.removeWhere((_, it) {
      return it == handler;
    });
  }

  static void removeMethodCallHandlerByName(
    MethodChannel channel,
    String methodName,
  ) {
    callHandlers.remove(channel.name + methodName);
  }

  static Stream<T> createStream<T>(
    MethodChannel channel,
    String streamName, [
    dynamic args,
  ]) {
    StreamController<T> controller;
    controller = StreamController<T>.broadcast(
      onListen: () async {
        final hashCode = controller.hashCode;
        final prefix = '$streamName/$hashCode';

        setMethodCallHandler(channel, "$prefix/$onSuccess", (event) {
          controller.add(event);
        });
        setMethodCallHandler(channel, "$prefix/$onError", (err) {
          controller.addError(
            PlatformException(code: err[0], message: err[1], details: err[2]),
          );
        });
        setMethodCallHandler(channel, "$prefix/$endOfStream", (_) {
          controller.close();
        });

        try {
          await channel.invokeMethod(streamName + onListen, [hashCode, args]);
        } catch (e, trace) {
          controller.addError(e, trace);
        }
      },
      onCancel: () async {
        final hashCode = controller.hashCode;
        final prefix = '$streamName/$hashCode';

        removeMethodCallHandlerByName(channel, "$prefix/$onSuccess");
        removeMethodCallHandlerByName(channel, "$prefix/$onError");
        removeMethodCallHandlerByName(channel, "$prefix/$endOfStream");

        try {
          await channel.invokeMethod(streamName + onCancel, [hashCode, args]);
        } catch (e, trace) {
          controller.addError(e, trace);
        }
      },
    );
    return controller.stream;
  }
}
