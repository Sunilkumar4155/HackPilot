import 'theme_storage_stub.dart'
    if (dart.library.html) 'theme_storage_web.dart'
    if (dart.library.io) 'theme_storage_native.dart' as platform;

class ThemeStorage {
  ThemeStorage._();

  static Future<String?> read() => platform.readThemeSettings();

  static Future<void> write(String value) =>
      platform.writeThemeSettings(value);
}
