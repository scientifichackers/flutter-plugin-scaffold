package com.pycampers.plugin_scaffold

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.PrintWriter
import java.io.StringWriter
import java.lang.reflect.Method

const val TAG = "PluginScaffold"

const val ON_LISTEN = "OnListen"
const val ON_CANCEL = "OnCancel"
const val ON_SUCCESS = "onSuccess"
const val ON_ERROR = "onError"
const val END_OF_STREAM = "endOfStream"

val methodSignature = listOf(MethodCall::class.java, Result::class.java)
val onListenSignature = listOf(Int::class.java, Object::class.java, StreamSink::class.java)
var handler = Handler(Looper.getMainLooper())

typealias OnError = (errorCode: String, errorMessage: String?, errorDetails: Any?) -> Unit
typealias OnSuccess = (result: Any?) -> Unit
typealias AnyFn = () -> Any?
typealias UnitFn = () -> Unit
typealias MethodMap = MutableMap<String, Method>

class PluginScaffoldPlugin {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) = Unit
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
        Log.d(
            TAG,
            "ignoring exception: $e. See https://github.com/flutter/flutter/issues/29092 for details."
        )
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

fun trySendThrowable(result: Result, throwable: Throwable) {
    trySendThrowable(result::error, throwable)
}

fun trySendThrowable(events: EventSink, throwable: Throwable) {
    trySendThrowable(events::error, throwable)
}

/**
 * Try to send the value returned by [fn] using [onSuccess].
 * by encapsulating calls inside [ignoreIllegalState].
 *
 * It is advisable to wrap any native code inside [fn],
 * because this will automatically send exceptions using
 * using [trySendThrowable] and [onError] if required.
 */
fun trySend(onSuccess: OnSuccess, onError: OnError, fn: AnyFn? = null) {
    handler.post {
        val value: Any?
        try {
            value = fn?.invoke()

            ignoreIllegalState {
                onSuccess(if (value is Unit) null else value)
            }
        } catch (e: Throwable) {
            trySendThrowable(onError, e)
        }
    }
}

fun trySend(result: Result, fn: AnyFn? = null) {
    trySend(result::success, result::error, fn)
}

fun trySend(events: EventSink, fn: AnyFn? = null) {
    trySend(events::success, events::error, fn)
}

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

fun catchErrors(result: Result, fn: UnitFn) {
    catchErrors(result::error, fn)
}

fun catchErrors(events: EventSink, fn: UnitFn) {
    catchErrors(events::error, fn)
}

fun buildMethodMap(pluginObj: Any): MethodMap {
    val map: MethodMap = mutableMapOf()
    for (method in pluginObj::class.java.methods) {
        if (method.parameterTypes.toList() == methodSignature) {
            map[method.name] = method
        }
    }
    return map
}

fun getStreamName(methodName: String): String? {
    if (methodName.endsWith(ON_LISTEN)) {
        val streamName = methodName.substring(0, methodName.length - ON_LISTEN.length)
        if (streamName.isNotEmpty()) {
            return streamName
        }
    } else if (methodName.endsWith(ON_CANCEL)) {
        val streamName = methodName.substring(0, methodName.length - ON_CANCEL.length)
        if (streamName.isNotEmpty()) {
            return streamName
        }
    }
    return null
}

fun buildStreamMethodMap(pluginObj: Any): Pair<MethodMap, MethodMap> {
    val onListenMethods: MethodMap = mutableMapOf()
    val onCancelMethods: MethodMap = mutableMapOf()

    val cls = pluginObj::class.java
    for (listenMethod in cls.methods) {
        if (listenMethod.parameterTypes.toList() != onListenSignature) continue

        val onListenName = listenMethod.name
        val streamName = getStreamName(onListenName) ?: continue
        val onCancelName = streamName + ON_CANCEL

        val cancelMethod: Method
        try {
            cancelMethod = cls.getMethod(onCancelName, Int::class.java, Object::class.java)
        } catch (e: NoSuchMethodException) {
            Log.w(
                TAG,
                "Found \"$onListenName()\" in \"$cls\", but accompanying method \"$onCancelName()\" was not found!"
            )
            continue
        }

        onListenMethods[onListenName] = listenMethod
        onCancelMethods[onCancelName] = cancelMethod
    }

    return Pair(onListenMethods, onCancelMethods)
}

class StreamSink(val channel: MethodChannel, val prefix: String) : EventSink {
    override fun success(event: Any?) {
        handler.post {
            channel.invokeMethod("$prefix/$ON_SUCCESS", event)
        }
    }

    override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
        handler.post {
            channel.invokeMethod(
                "$prefix/$ON_ERROR",
                listOf(errorCode, errorMessage, errorDetails)
            )
        }
    }

    override fun endOfStream() {
        handler.post {
            channel.invokeMethod("$prefix/$END_OF_STREAM", null)
        }
    }
}

fun createPluginScaffold(
    messenger: BinaryMessenger,
    channelName: String,
    pluginObj: Any = Any()
): MethodChannel {
    val methods = buildMethodMap(pluginObj)
    val (onListenMethods, onCancelMethods) = buildStreamMethodMap(pluginObj)
    val channel = MethodChannel(messenger, channelName)

    channel.setMethodCallHandler { call, result ->
        val name = call.method
        val args = call.arguments

        /**
         * Run any function inside the handler,
         * catch any errors if they occur,
         * and ignore IllegalStateError.
         */
        fun execSafe(fn: UnitFn) {
            handler.post { catchErrors(result) { ignoreIllegalState(fn) } }
        }

        //
        // Try to find the method in [methods], [onListenMethods] or [onCancelMethods],
        // and invoke it using [execSafe].
        //
        // If not found, return [result.notImplemented()]
        //

        methods[name]?.let {
            Log.d(TAG, "invoke { channel: $channelName, method: $name(), args: $args }")

            execSafe {
                it.invoke(pluginObj, call, result)
            }

            return@setMethodCallHandler
        }

        onListenMethods[name]?.let {
            val streamName = getStreamName(name)!!
            val (hashCode: Any?, streamArgs: Any?) = args as List<*>
            val prefix = "$streamName/$hashCode"
            val sink = StreamSink(channel, prefix)
            Log.d(
                TAG,
                "activate stream { channel: $channelName, stream: $streamName, hashCode: $hashCode, args: $streamArgs }"
            )

            execSafe {
                it.invoke(pluginObj, hashCode, streamArgs, sink)
            }

            return@setMethodCallHandler
        }

        onCancelMethods[name]?.let {
            val streamName = getStreamName(name)!!
            val (hashCode: Any?, streamArgs: Any?) = args as List<*>
            Log.d(
                TAG,
                "de-activate stream { channel: $channelName, stream: $streamName, hashCode: $hashCode, args: $streamArgs }"
            )

            execSafe {
                it.invoke(pluginObj, hashCode, streamArgs)
            }

            return@setMethodCallHandler
        }

        result.notImplemented()
    }

    return channel
}