import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final _platform = MethodChannel("myFancyChannel");

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String result;

  Future<void> doLoad() async {
    final value = await _platform.invokeMethod("myFancyMethod");
    if (!mounted) return;
    setState(() {
      result = value;
    });

    _platform.invokeMethod("myBrokenMethod");

    _platform.invokeMethod("myBrokenCallbackMethod");
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
          title: const Text('Flutter MethodCallDispatcher'),
        ),
        body: Center(
          child: Text(result ?? "Waiting for reply..."),
        ),
      ),
    );
  }
}
