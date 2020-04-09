import 'dart:async';

import 'package:flutter/services.dart';

typedef void MethodCallHandler(dynamic args);

class PluginScaffold {
  static const onListen = "OnListen";
  static const onCancel = "OnCancel";
  static const onSuccess = "onSuccess";
  static const onError = "onError";
  static const endOfStream = "endOfStream";

  static final callHandlers = <String, Set<MethodCallHandler>>{};

  static String getCallHandlerKey(MethodChannel channel, String methodName) {
    return "${channel.name}/$methodName";
  }

  static void _setChannelCallHandler(MethodChannel channel) {
    channel.setMethodCallHandler((call) async {
      final key = getCallHandlerKey(channel, call.method);
      final handlers = callHandlers[key];
      for (var handler in handlers) {
        handler(call.arguments);
      }
    });
  }

  static void addCallHandler(
    MethodChannel channel,
    String methodName,
    MethodCallHandler handler,
  ) {
    final key = getCallHandlerKey(channel, methodName);
    callHandlers.putIfAbsent(key, () => {});
    callHandlers[key].add(handler);
    _setChannelCallHandler(channel);
  }

  static void setCallHandler(
    MethodChannel channel,
    String methodName,
    MethodCallHandler handler,
  ) {
    final key = getCallHandlerKey(channel, methodName);
    callHandlers[key] = {handler};
    _setChannelCallHandler(channel);
  }

  static void removeCallHandler(MethodCallHandler handler) {
    for (final it in callHandlers.values) {
      it.remove(handler);
    }
  }

  static void removeCallHandlersWithName(
    MethodChannel channel,
    String methodName,
  ) {
    callHandlers.remove(getCallHandlerKey(channel, methodName));
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

        setCallHandler(channel, "$prefix/$onSuccess", (event) {
          controller.add(event);
        });
        setCallHandler(channel, "$prefix/$onError", (err) {
          controller.addError(
            PlatformException(code: err[0], message: err[1], details: err[2]),
          );
        });
        setCallHandler(channel, "$prefix/$endOfStream", (_) {
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

        removeCallHandlersWithName(channel, "$prefix/$onSuccess");
        removeCallHandlersWithName(channel, "$prefix/$onError");
        removeCallHandlersWithName(channel, "$prefix/$endOfStream");

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
