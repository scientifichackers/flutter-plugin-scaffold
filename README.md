[![Sponsor](https://img.shields.io/badge/Sponsor-jaaga_labs-red.svg?style=for-the-badge)](https://www.jaaga.in/labs)
[![Pub](https://img.shields.io/pub/v/plugin_scaffold.svg?style=for-the-badge)](https://pub.dartlang.org/packages/plugin_scaffold)

# Flutter Plugin Scaffold

Tired of endless switch-cases in your Flutter plugin code?
This module is for you!

- Dynamic method dispatch (Only Kotlin)
- Built-in error serialization for both platforms
- Superior streams.

## TLDR

It lets you turn this:-

```kotlin
channel.setMethodCallHandler { call, result ->
  when (call.method) {
    "orange" -> ...
    "banana" -> ...
    "mango" -> ...
    "apple" -> ...
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
}

createPluginScaffold(registrar.messenger(), "myFancyChannel", MyPlugin())
```

## Errors

Any errors that occur in native code tend to instantly crash the app.
Sending them back to flutter can be a real PITA.

This module does everything in its power to prevent such mishaps.

So yes,
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

## Streams

Flutter's `EventChannel`, has a flaw in that it only lets you open only a single stream at a time.

Plugin Scaffold's stream methods build upon regular `MethodChannel` callback methods,
and provide a more flexible solution.

*This comes with a caveat, though. You can no longer use regular `MethodChannel.setMethodCallHandler()`,
and must use `PluginScaffold.setMethodCallHandler()` instead.*

## Install

First install the plugin using regular instructions on [dart pub](https://pub.dartlang.org/packages/plugin_scaffold#-installing-tab-).

Next, add this line to `ios/<plugin-name>.podspec`

```
s.dependency 'plugin_scaffold'
```

Finally, add this line to `android/build.gradle`

```
dependencies {
    implementation project(path: ':plugin_scaffold')
    ...
}
```

## Usage

The example is app available @ [`main.dart`](example/lib/main.dart),
[`MainActivity.kt`](example/android/app/src/main/kotlin/com/pycampers/plugin_scaffold_example/MainActivity.kt)
& [`AppDelegate.dart`](example/ios/Runner/AppDelegate.swift)

The core plugin code can be found @ [`plugin_scaffold.dart`](lib/plugin_scaffold.dart),
[`MethodCallDispatcherPlugin.kt`](android/src/main/kotlin/com/pycampers/plugin_scaffold/PluginScaffoldPlugin.kt)
& [`SwiftPluginScaffoldPlugin.swift`](ios/Classes/SwiftPluginScaffoldPlugin.swift)
