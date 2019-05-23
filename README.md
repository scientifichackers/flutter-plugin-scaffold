[![Sponsor](https://img.shields.io/badge/Sponsor-jaaga_labs-red.svg?style=for-the-badge)](https://www.jaaga.in/labs) [![Pub](https://img.shields.io/pub/v/method_call_dispatcher.svg?style=for-the-badge)](https://pub.dartlang.org/packages/method_call_dispatcher)

# Flutter Plugin Scaffold

Tired of endless switch-cases in your Flutter plugin code?
This module is for you!

## TLDR

It lets you turn this:-

```kotlin
channel.setMethodCallHandler { call, result ->
  when (call.method) {
    "orange" -> ...
    "banana" -> ...
    "mango" -> ...
    "apple" -> ...
    .
    .
    .
  }
}
```

Into this beauty:-

```kotlin
import com.pycampers.method_call_dispatcher.MethodCallDispatcher


class MyPlugin {
    fun orange(call: MethodCall, result: Result) {
        ...
    }

    fun banana(call: MethodCall, result: Result) {
        ...
    }

    fun mango(call: MethodCall, result: Result) {
        ...
    }

    fun apple(call: MethodCall, result: Result) {
        ...
    }

    .
    .
    .
}

createPluginScaffold("myFancyChannel", registrar.messenger(), MyPlugin())
```

## Errors

Any errors that occur in native code tend to instantly crash the app.
Sending them back to flutter can be a real PITA.

This module does everything in its power to prevent such mishaps.

```kotlin
import com.pycampers.method_call_dispatcher.MethodCallDispatcher
import com.pycampers.method_call_dispatcher.trySend


class MyPlugin {
    fun myBrokenMethod(call: MethodCall, result: MethodChannel.Result) {
        // This won't crash the app!
        // The exception will be serialized to flutter, and is catch-able in flutter.
        throw IllegalArgumentException("Hello from Kotlin!")
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
                        throw IllegalArgumentException("Hello from Kotlin!")
                    }
                }
            },
            1000
        )
    }
}
```

And yes,
You get 100% dart catch-able `PlatformExceptions` with stacktraces of native code!
```
D/MethodCallDispatcher( 3572): piping exception to flutter: java.lang.IllegalArgumentException: Hello from Kotlin!
E/flutter ( 3572): [ERROR:flutter/lib/ui/ui_dart_state.cc(148)] Unhandled Exception: PlatformException(java.lang.IllegalArgumentException, Hello from Kotlin!, java.lang.IllegalArgumentException: Hello from Kotlin!
E/flutter ( 3572): 	at com.pycampers.method_call_dispatcher_example.MyPlugin$myBrokenCallbackMethod$1$run$1.invoke(MainActivity.kt:33)
E/flutter ( 3572): 	at com.pycampers.method_call_dispatcher_example.MyPlugin$myBrokenCallbackMethod$1$run$1.invoke(MainActivity.kt:30)
E/flutter ( 3572): 	at com.pycampers.method_call_dispatcher.MethodCallDispatcherPluginKt.trySend(MethodCallDispatcherPlugin.kt:52)
E/flutter ( 3572): 	at com.pycampers.method_call_dispatcher_example.MyPlugin$myBrokenCallbackMethod$1.run(MainActivity.kt:32)
E/flutter ( 3572): 	at java.util.Timer$TimerImpl.run(Timer.java:284)
E/flutter ( 3572): )
```

## Example app

See the example app available @ [`main.dart`](example/lib/main.dart) & [`MainActivity.kt`](example/android/app/src/main/kotlin/com/pycampers/method_call_dispatcher_example/MainActivity.kt)

[Installation](https://pub.dartlang.org/packages/method_call_dispatcher#-installing-tab-) is same as for any other flutter plugin,
except that this one doesn't have any dart code :-)

The core plugin code can be found at [`MethodCallDispatcherPlugin.kt`](android/src/main/kotlin/com/pycampers/method_call_dispatcher/MethodCallDispatcherPlugin.kt)
