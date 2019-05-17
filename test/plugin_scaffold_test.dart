import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_scaffold/plugin_scaffold.dart';

void main() {
  const MethodChannel channel = MethodChannel('plugin_scaffold');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await PluginScaffold.platformVersion, '42');
  });
}
