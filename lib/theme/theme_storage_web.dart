// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

const _key = 'hackathon_hub_theme_settings';

Future<String?> readThemeSettings() async => html.window.localStorage[_key];

Future<void> writeThemeSettings(String value) async {
  html.window.localStorage[_key] = value;
}
