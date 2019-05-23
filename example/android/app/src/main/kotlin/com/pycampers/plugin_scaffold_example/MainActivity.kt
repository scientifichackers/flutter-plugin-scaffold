package com.pycampers.plugin_scaffold_example

import android.os.Bundle
import com.pycampers.plugin_scaffold.createMethodChannel
import com.pycampers.plugin_scaffold.createPluginScaffold
import com.pycampers.plugin_scaffold.trySend
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MyPlugin {
    fun myFancyMethod(call: MethodCall, result: MethodChannel.Result) {
        // trySend is not required, but serves as a precautionary measure against errors.
        trySend(result) { "Hello from Kotlin!" }
    }

    fun myBrokenMethod(call: MethodCall, result: MethodChannel.Result) {
        // This won't crash the app!
        // The exception will be serialized to flutter, and is catch-able in flutter.
        throw IllegalArgumentException("Hello from Kotlin 1!")
    }

    fun myBrokenCallbackMethod(call: MethodCall, result: MethodChannel.Result) {
        // Automatic exception handling can only work in non-callback, synchronous contexts.
        //
        // So, trySend guarantees that app won't crash,
        // and errors will be serialized to flutter,
        // even in a callback context.
        java.util.Timer().schedule(
            object : java.util.TimerTask() {
                override fun run() {
                    trySend(result) {
                        throw IllegalArgumentException("Hello from Kotlin 2!")
                    }
                }
            },
            1000
        )
    }
}

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)

        createPluginScaffold("myFancyChannel", flutterView, MyPlugin())
    }
}