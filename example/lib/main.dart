import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final platform = MethodChannel("myFancyChannel");

  var isWaiting = true;
  var returnValue;

  Future<void> doLoad() async {
    var value;
    try {
      value = await platform.invokeMethod("myFancyMethod");
    } catch (e) {
      value = e;
    } finally {
      if (mounted) {
        setState(() {
          isWaiting = false;
          returnValue = value;
        });
      }
    }

    platform.invokeMethod("myBrokenMethod");
    platform.invokeMethod("myBrokenCallbackMethod");
  }

  @override
  void initState() {
    super.initState();
    doLoad();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Plugin Scaffold'),
        ),
        body: Center(
          child: Text(
            isWaiting
                ? "Waiting for reply..."
                : returnValue?.toString() ?? "null",
          ),
        ),
      ),
    );
  }
}
