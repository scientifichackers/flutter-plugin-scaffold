package com.pycampers.plugin_scaffold

import android.os.AsyncTask
import android.os.Handler
import android.util.Log
import io.flutter.app.FlutterActivity
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

private val methodSignature = listOf(MethodCall::class.java, Result::class.java)
private val onListenSignature =
    listOf(Int::class.java, Object::class.java, EventSink::class.java)

typealias OnError = (errorCode: String, errorMessage: String?, errorDetails: Any?) -> Unit
typealias OnSuccess = (result: Any?) -> Unit
typealias AnyFn = () -> Any?
typealias UnitFn = () -> Unit
typealias MethodMap = MutableMap<String, Method>

/**
 * Create a plugin with the provided [channelName].
 *
 * The methods of [pluginObj] having parameters - ([MethodCall], [Result]),
 * are automatically exposed through the returned [MethodChannel]:
 *
 * The [messenger] can be passed in various ways.
 *  - If you're inside a subclass of [FlutterActivity], pass [FlutterActivity.getFlutterView] (generally regular flutter apps)
 *  - If you have access to a [Registrar] object, pass [Registrar.messenger] (generally flutter plugin projects)
 *
 * If [runOnMainThread] is set to `true`,
 * the methods in [pluginObj] will be invoked from the main thread (using [Handler.post]).
 * Otherwise, they will be invoked from an [AsyncTask].
 */
fun createPluginScaffold(
    messenger: BinaryMessenger,
    channelName: String,
    pluginObj: Any = Any(),
    runOnMainThread: Boolean = false
): MethodChannel {
    val methods = buildMethodMap(pluginObj)
    val (onListenMethods, onCancelMethods) = buildStreamMethodMap(pluginObj)
    val channel = MethodChannel(messenger, channelName)
    val wrapper = createMethodWrapper(runOnMainThread)

    channel.setMethodCallHandler { call, result ->
        val name = call.method
        val args = call.arguments
        val mainResult = MainThreadResult(result)

        //
        // Try to find the method in [methods], [onListenMethods] and [onCancelMethods],
        // and invoke it using [wrapFunCall].
        //
        // If not found, invoke [Result.notImplemented]
        //

        methods[name]?.let {
            Log.d(TAG, "invoke { channel: $channelName, method: $name(), args: $args }")
            wrapper(mainResult) {
                it.invoke(pluginObj, call, mainResult)
            }

            return@setMethodCallHandler
        }

        onListenMethods[name]?.let {
            val streamName = getStreamName(name)!!
            val (hashCode: Any?, streamArgs: Any?) = args as List<*>
            val prefix = "$streamName/$hashCode"
            val sink = MainThreadEventSink(channel, prefix)

            Log.d(
                TAG,
                "activate stream { channel: $channelName, stream: $streamName, hashCode: $hashCode, args: $streamArgs }"
            )
            wrapper(mainResult) {
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
            wrapper(mainResult) {
                it.invoke(pluginObj, hashCode, streamArgs)
            }

            return@setMethodCallHandler
        }

        mainResult.notImplemented()
    }

    return channel
}

fun createMethodWrapper(runOnMainThread: Boolean): (Result, UnitFn) -> Unit {
    if (runOnMainThread) {
        return { result, fn ->
            handler.post {
                catchErrors(result, fn)
            }
        }
    } else {
        return { result, fn ->
            DoAsync {
                catchErrors(result, fn)
            }
        }
    }
}

/**
 * Try to send the value returned by [fn] using [onSuccess].
 *
 * It is advisable to wrap any native code inside [fn],
 * because this will automatically catch and send to dart exceptions using
 * using [sendThrowable] and [onError] if required.
 */
fun trySend(onSuccess: OnSuccess, onError: OnError, fn: AnyFn? = null) {
    val value: Any?
    try {
        value = fn?.invoke()
        onSuccess(if (value is Unit) null else value)
    } catch (e: Throwable) {
        sendThrowable(onError, e)
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
 * Automatically send exceptions using error using [sendThrowable] if required.
 *
 * This differs from [trySend],
 * in that it won't invoke [Result.success] using the return value of [fn].
 */
fun catchErrors(onError: OnError, fn: UnitFn) {
    try {
        fn()
    } catch (e: Throwable) {
        sendThrowable(onError, e)
    }
}

fun catchErrors(result: Result, fn: UnitFn) {
    catchErrors(result::error, fn)
}

fun catchErrors(events: EventSink, fn: UnitFn) {
    catchErrors(events::error, fn)
}

/**
 * Serialize the [throwable] and send it using [onError].
 */
fun sendThrowable(onError: OnError, throwable: Throwable) {
    val e = throwable.cause ?: throwable
    onError(
        e.javaClass.canonicalName ?: "null",
        e.message,
        serializeStackTrace(e)
    )
}

fun sendThrowable(result: Result, throwable: Throwable) {
    sendThrowable(result::error, throwable)
}

fun sendThrowable(events: EventSink, throwable: Throwable) {
    sendThrowable(events::error, throwable)
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

fun buildMethodMap(pluginObj: Any): MethodMap {
    val map: MethodMap = mutableMapOf()

    for (method in pluginObj::class.java.methods) {
        val paramList = method.parameterTypes.toList()
        if (paramList != methodSignature) continue

        map[method.name] = method
    }

    return map
}

fun buildStreamMethodMap(pluginObj: Any): Pair<MethodMap, MethodMap> {
    val onListenMethods: MethodMap = mutableMapOf()
    val onCancelMethods: MethodMap = mutableMapOf()
    val cls = pluginObj::class.java

    for (listenMethod in cls.methods) {
        val paramList = listenMethod.parameterTypes.toList()
        if (paramList != onListenSignature) continue

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

fun getStreamName(methodName: String): String? {
    val name =
        when {
            methodName.endsWith(ON_LISTEN) -> methodName.substring(
                0,
                methodName.length - ON_LISTEN.length
            )
            methodName.endsWith(ON_CANCEL) -> methodName.substring(
                0,
                methodName.length - ON_CANCEL.length
            )
            else -> null
        }

    if (name != null && name.isNotEmpty()) {
        return name
    }

    return null
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

class PluginScaffoldPlugin {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) = Unit
    }
}
