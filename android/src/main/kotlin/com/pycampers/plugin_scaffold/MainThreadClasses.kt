package com.pycampers.plugin_scaffold

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

val handler = Handler(Looper.getMainLooper())

class MainThreadEventSink(val channel: MethodChannel, val prefix: String) :
    EventChannel.EventSink {
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

class MainThreadResult(val parent: MethodChannel.Result) : MethodChannel.Result {
    override fun notImplemented() {
        wrapMainThreadResult {
            parent.notImplemented();
        }
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        wrapMainThreadResult {
            parent.error(errorCode, errorMessage, errorDetails)
        }
    }

    override fun success(result: Any?) {
        wrapMainThreadResult {
            parent.success(result)
        }
    }
}

fun wrapMainThreadResult(fn: UnitFn) {
    handler.post {
        ignoreIllegalState(fn)
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
            "Ignoring exception: <$e>. See https://github.com/flutter/flutter/issues/29092 for details."
        )
    }
}
