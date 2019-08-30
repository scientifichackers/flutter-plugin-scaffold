package com.pycampers.plugin_scaffold

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

val handler = Handler(Looper.getMainLooper())

class MainThreadStreamSink(val channel: MethodChannel, val prefix: String) :
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
        handler.post {
            parent.notImplemented();
        }
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        handler.post {
            parent.error(errorCode, errorMessage, errorDetails)
        }
    }

    override fun success(result: Any?) {
        handler.post {
            parent.success(result)
        }
    }
}
