import 'package:flutter/services.dart';

const _channel = MethodChannel('hackathon_hub/theme_settings');

Future<String?> readThemeSettings() =>
    _channel.invokeMethod<String>('read');

Future<void> writeThemeSettings(String value) =>
    _channel.invokeMethod<void>('write', {'value': value});
