package com.pycampers.plugin_scaffold_example

import android.os.Bundle
import com.pycampers.plugin_scaffold.MainThreadEventSink
import com.pycampers.plugin_scaffold.createPluginScaffold
import com.pycampers.plugin_scaffold.trySend
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.Timer
import kotlin.concurrent.timer

class MyPlugin {
    fun myFancyMethod(call: MethodCall, result: Result) {
        /*
        Calling [result.success] / [result.error] multiple times is OK.
        In-built protection against https://github.com/flutter/flutter/issues/29092.
        */
        result.success("Hello from Kotlin!")
        result.success("Hello from Kotlin!")
    }

    fun myBrokenMethod(call: MethodCall, result: Result) {
        /*
        This won't crash the app!
        The exception will be serialized to flutter, and is catch-able in flutter.
        */
        throw IllegalArgumentException("Error from Kotlin 1!")
    }

    fun myBrokenCallbackMethod(call: MethodCall, result: Result) {
        /*
        Automatic exception handling can only work in non-callback, synchronous contexts.

        So, trySend guarantees that app won't crash,
        and errors will be serialized to flutter,
        even in a callback context.
        */
        java.util.Timer().schedule(
            object : java.util.TimerTask() {
                override fun run() {
                    trySend(result) {
                        throw IllegalArgumentException("Error from Kotlin 2!")
                    }
                }
            },
            1000
        )
    }

    val timers = mutableMapOf<Int, Timer>()

    /*
    Any method that is suffixed with `OnListen` is treated as a stream method.

    When a new stream is created from dart, this method is called.
    You can use `sink` to send events through the stream.

    `id` is the `hashCode` of the accompanying `StreamController` (on dart side).
    It is provided as a way to differentiate between streams.
    */
    fun counterOnListen(id: Int, args: Any?, sink: MainThreadEventSink) {
        var count = 0
        timers[id] = timer(
            period = (args as Int).toLong(),
            action = {
                sink.success(count)

                if (count >= 100) {
                    sink.endOfStream()
                    cancel()
                }

                count += 1
            }
        )
    }

    /*
    Stream methods are only accepted if they are accompanied with an `*OnCancel()` method.

    Use this to tear-down any resources that might have been allocated during `*onListen()`
    */
    fun counterOnCancel(id: Int, args: Any?) {
        timers[id]?.cancel()
        timers.remove(id)
    }

    /* Exceptions are piped in streams just as well */
    fun brokenStream1OnListen(id: Int, args: Any?, sink: MainThreadEventSink) {
        throw IllegalArgumentException("Error from Kotlin 3!")
    }

    /* Again, this is required for `brokenStream1` to be accepted as a stream */
    fun brokenStream1OnCancel(id: Int, args: Any?) {}

    fun brokenStream2OnListen(id: Int, args: Any?, sink: MainThreadEventSink) {
        trySend(sink) {
            throw IllegalArgumentException("Error from Kotlin 4!")
        }
    }

    fun brokenStream2OnCancel(id: Int, args: Any?) {}
}

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        createPluginScaffold(flutterView, "myFancyChannel", MyPlugin())
    }
}