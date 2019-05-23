package com.pycampers.plugin_scaffold

import android.os.AsyncTask
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.PrintWriter
import java.io.StringWriter
import java.lang.reflect.Method

const val TAG = "PluginScaffold"

typealias OnError = (errorCode: String, errorMessage: String?, errorDetails: Any?) -> Unit
typealias OnSuccess = (result: Any?) -> Unit
typealias AnyFn = () -> Any?
typealias UnitFn = () -> Unit

class PluginScaffoldPlugin {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) = Unit
    }
}

class DoAsync(val fn: () -> Unit) : AsyncTask<Void, Void, Void>() {
    init {
        execute()
    }

    override fun doInBackground(vararg params: Void?): Void? {
        fn()
        return null
    }
}

/**
 * Runs [fn], ignoring [IllegalStateException], if encountered.
 *
 * Workaround for https://github.com/flutter/flutter/issues/29092.
 */
fun ignoreIllegalState(fn: UnitFn) {
    try {
        fn()
    } catch (e: IllegalStateException) {
        Log.d(TAG, "ignoring exception: $e. See https://github.com/flutter/flutter/issues/29092 for details.")
    }
}

/**
 * Serialize the stacktrace contained in [throwable] to a [String].
 */
fun serializeStackTrace(throwable: Throwable): String {
    val sw = StringWriter()
    val pw = PrintWriter(sw)
    throwable.printStackTrace(pw)
    return sw.toString()
}

/**
 * Try to send an error using [onError],
 * by encapsulating calls inside [ignoreIllegalState].
 */
fun trySendError(onError: OnError, name: String?, message: String?, stackTrace: String?) {
    ignoreIllegalState {
        Log.d(TAG, "piping exception to flutter ($name)")
        onError(name ?: "null", message, stackTrace)
    }
}

fun trySendError(result: Result, name: String?, message: String?, stackTrace: String?) {
    trySendError(result::error, name, message, stackTrace)
}

fun trySendError(events: EventSink, name: String?, message: String?, stackTrace: String?) {
    trySendError(events::error, name, message, stackTrace)
}

/**
 * Serialize the [throwable] and send it using [trySendError].
 */
fun trySendThrowable(onError: OnError, throwable: Throwable) {
    val e = throwable.cause ?: throwable
    trySendError(
        onError,
        e.javaClass.canonicalName,
        e.message,
        serializeStackTrace(e)
    )
}

fun trySendThrowable(result: Result, throwable: Throwable) = trySendThrowable(result::error, throwable)
fun trySendThrowable(events: EventSink, throwable: Throwable) = trySendThrowable(events::error, throwable)

/**
 * Try to send the value returned by [fn] using [onSuccess].
 * by encapsulating calls inside [ignoreIllegalState].
 *
 * It is advisable to wrap any native code inside [fn],
 * because this will automatically send exceptions using error using [trySendThrowable] and [onError] if required.
 */
fun trySend(onSuccess: OnSuccess, onError: OnError, fn: AnyFn? = null) {
    val value: Any?
    try {
        value = fn?.invoke()
    } catch (e: Throwable) {
        trySendThrowable(onError, e)
        return
    }

    ignoreIllegalState {
        onSuccess(if (value is Unit) null else value)
    }
}

fun trySend(result: Result, fn: AnyFn? = null) = trySend(result::success, result::error, fn)
fun trySend(events: EventSink, fn: AnyFn? = null) = trySend(events::success, events::error, fn)

/**
 * Run [fn].
 * Automatically send exceptions using error using [trySendThrowable] if required.
 *
 * This differs from [trySend],
 * in that it won't invoke [Result.success] using the return value of [fn].
 */
fun catchErrors(onError: OnError, fn: UnitFn) {
    try {
        fn()
    } catch (e: Throwable) {
        trySendThrowable(onError, e)
    }
}

fun catchErrors(result: Result, fn: UnitFn) = catchErrors(result::error, fn)
fun catchErrors(events: EventSink, fn: UnitFn) = catchErrors(events::error, fn)

fun buildMethodMap(pluginObj: Any): Map<String, Method> {
    val map = mutableMapOf<String, Method>()
    for (method in pluginObj::class.java.methods) {
        val params = method.parameterTypes
        if (
            params.size == 2 &&
            params[0] == MethodCall::class.java &&
            params[1] == Result::class.java
        ) {
            map[method.name] = method
        }
    }
    return map.toMap()
}

/**
 * Inherit this class to make any kotlin methods with the signature:-
 *
 *  methodName([MethodCall], [Result])
 *
 * be magically available to Flutter's platform channels,
 * by the power of dynamic dispatch!
 */
fun createPluginScaffold(
    channelName: String,
    messenger: BinaryMessenger,
    pluginObj: Any = Any(),
    eventMap: Map<String, StreamHandler> = mapOf()
): Pair<MethodChannel, Map<String, EventChannel>> {
    val methodMap = buildMethodMap(pluginObj)

    val channel = MethodChannel(messenger, channelName)
    channel.setMethodCallHandler { call, result ->
        val methodName = call.method
        val method = methodMap[methodName]
        if (method == null) {
            result.notImplemented()
            return@setMethodCallHandler
        }
        DoAsync {
            Log.d(TAG, "invoke { channel: $channelName, method: $methodName(), args: ${call.arguments} }")
            catchErrors(result) {
                ignoreIllegalState {
                    method.invoke(pluginObj, call, result)
                }
            }
        }
    }

    val eventChannels = mutableMapOf<String, EventChannel>()
    for (entry in eventMap) {
        val name = channelName + '/' + entry.key
        val handler = entry.value

        eventChannels[name] = EventChannel(messenger, name).apply {
            setStreamHandler(object : StreamHandler {
                override fun onListen(args: Any?, eventSink: EventSink) {
                    Log.d(TAG, "onListen { channel: $name, args: $args }")
                    catchErrors(eventSink) {
                        handler.onListen(args, eventSink)
                    }
                }

                override fun onCancel(args: Any?) {
                    Log.d(TAG, "onCancel { channel: $name, args: $args }")
                    handler.onCancel(args)
                }
            })
        }
    }

    return Pair(channel, eventChannels)
}