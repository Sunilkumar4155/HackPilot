import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_storage.dart';

class ThemeProvider extends ChangeNotifier {
  HubPalette _palette = HubPalette.hackathonNight;
  bool _isDark = true;
  int _revision = 0;

  HubPalette get palette => _palette;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;
  ThemeData get lightTheme => AppTheme.lightFor(_palette);
  ThemeData get darkTheme => AppTheme.darkFor(_palette);

  Future<void> load() async {
    final startingRevision = _revision;
    try {
      final saved = await ThemeStorage.read();
      if (startingRevision == _revision && saved != null) {
        _palette = HubPalette.hackathonNight;
        // Keep the product on its dark, high-contrast event identity.
        _isDark = true;
      }
    } catch (_) {
      // Keep the in-memory defaults if local settings are unavailable.
    }
    notifyListeners();
  }

  Future<void> selectPalette(HubPalette palette) async {
    if (_palette.id == palette.id) return;
    _palette = HubPalette.hackathonNight;
    _revision++;
    notifyListeners();
    await _persist();
  }

  void toggleTheme(bool value) {
    if (_isDark) return;
    _isDark = true;
    _revision++;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      await ThemeStorage.write('${_palette.id}|${_isDark ? 1 : 0}');
    } catch (_) {
      // Theme selection remains active for the current session.
    }
  }
}
