[![Sponsor](https://img.shields.io/badge/Sponsor-jaaga_labs-red.svg?style=for-the-badge)](https://www.jaaga.in/labs) [![Pub](https://img.shields.io/pub/v/plugin_scaffold.svg?style=for-the-badge)](https://pub.dartlang.org/packages/plugin_scaffold)

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
import com.pycampers.plugin_scaffold.createPluginScaffold


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


## iOS


```swift
import plugin_scaffold


enum MyError: Error {
    case fatalError
}

func myFancyMethod(call _: FlutterMethodCall, result: @escaping FlutterResult) {
    // trySend is not required, but serves as a precautionary measure against errors.
    // useful in callbacks
    trySend(result) {
        "Hello from Swift!"
    }
}

func myBrokenMethod(call _: FlutterMethodCall, result _: @escaping FlutterResult) throws {
    throw MyError.fatalError
}

func myBrokenCallbackMethod(call _: FlutterMethodCall, result _: @escaping FlutterResult) throws {
    throw NSError(domain: "hello", code: 123)
}

// unfortunately, swift just isn't dynamic enough to make full-scale dynamic dispatch possible :(
createPluginScaffold(
    messenger: messenger,
    channelName: "myFancyChannel",
    methodMap: [
        "myFancyMethod": myFancyMethod,
        "myBrokenMethod": myBrokenMethod,
        "myBrokenCallbackMethod": myBrokenCallbackMethod,
    ]
)
```

**Errors are piped as well:**

```
[VERBOSE-2:ui_dart_state.cc(148)] Unhandled Exception: PlatformException(Runner.MyError.fatalError, The operation couldn’t be completed. (Runner.MyError error 0.), 0   plugin_scaffold                     0x0000000106131435 $s15plugin_scaffold14serializeErrorySo07FlutterD0CypF + 309
1   plugin_scaffold                     0x0000000106135a39 $s15plugin_scaffold20createPluginScaffold9messenger11channelName9methodMap05eventJ0So20FlutterMethodChannelC_SDySSSo0l5EventN0CGtSo0L15BinaryMessenger_p_SSSDySSypGSDySSSo0L13StreamHandler_So8NSObjectpGtFySo0lM4CallC_yypSgctcfU_yycfU_ASycfU_ + 121
2   plugin_scaffold                     0x000000010613654d $s15plugin_scaffold20createPluginScaffold9messenger11channelName9methodMap05eventJ0So20FlutterMethodChannelC_SDySSSo0l5EventN0CGtSo0L15BinaryMessenger_p_SSSDySSypGSDySSSo0L13StreamHandler_So8NSObjectpGtFySo0lM4CallC_yypSgctcfU_yycfU_ASycfU_TA + 13
3   plugin_scaffold                     0x0000000106133099 $s15plugin_scaffold7trySendyyyypSgc_ACyKcSgtFyycfU_ + 297
<…>
[VERBOSE-2:ui_dart_state.cc(148)] Unhandled Exception: PlatformException(Error Domain=hello Code=123 "(null)", The operation couldn’t be completed. (hello error 123.), 0   plugin_scaffold                     0x0000000106131435 $s15plugin_scaffold14serializeErrorySo07FlutterD0CypF + 309
1   plugin_scaffold                     0x0000000106135a39 $s15plugin_scaffold20createPluginScaffold9messenger11channelName9methodMap05eventJ0So20FlutterMethodChannelC_SDySSSo0l5EventN0CGtSo0L15BinaryMessenger_p_SSSDySSypGSDySSSo0L13StreamHandler_So8NSObjectpGtFySo0lM4CallC_yypSgctcfU_yycfU_ASycfU_ + 121
2   plugin_scaffold                     0x000000010613654d $s15plugin_scaffold20createPluginScaffold9messenger11channelName9methodMap05eventJ0So20FlutterMethodChannelC_SDySSSo0l5EventN0CGtSo0L15BinaryMessenger_p_SSSDySSypGSDySSSo0L13StreamHandler_So8NSObjectpGtFySo0lM4CallC_yypSgctcfU_yycfU_ASycfU_TA + 13
3   plugin_scaffold                     0x0000000106133099 $s15plugin_scaffold7trySendyyyypSgc_ACyKcSgtFyycfU_ + <…>
```