import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plugin_scaffold/plugin_scaffold.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

final channel = MethodChannel("myFancyChannel");

class _MyAppState extends State<MyApp> {
  var isWaiting = true;
  var returnValue;
  final errors = <String>[];
  final counterStream1 = PluginScaffold.createStream(channel, "counter", 1000);
  final counterStream2 = PluginScaffold.createStream(channel, "counter", 2000);

  Future<void> doLoad() async {
    var value;
    try {
      value = await channel.invokeMethod("myFancyMethod");
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

    try {
      await channel.invokeMethod("myBrokenMethod");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errors.add(e.toString());
      });
    }

    try {
      await channel.invokeMethod("myBrokenCallbackMethod");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errors.add(e.toString());
      });
    }

    try {
      await for (final _ in PluginScaffold.createStream(channel, "broken")) {}
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errors.add(e.toString());
      });
    }
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
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              Text(
                isWaiting
                    ? "Waiting for reply..."
                    : returnValue?.toString() ?? "null",
              ),
              StreamBuilder(
                stream: counterStream1,
                builder: (context, snapshot) {
                  return Text(snapshot.data?.toString() ?? "null");
                },
              ),
              StreamBuilder(
                stream: counterStream2,
                builder: (context, snapshot) {
                  return Text(snapshot.data?.toString() ?? "null");
                },
              ),
              if (errors != null)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors.map((it) {
                      return Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(it),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
