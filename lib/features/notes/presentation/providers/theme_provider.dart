import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  late Box _settingsBox;

  ThemeNotifier() : super(ThemeMode.system) {
    _init();
  }

  Future<void> _init() async {
    _settingsBox = await Hive.openBox('smart_settings_box');
    final String? themeStr = _settingsBox.get('theme_mode') as String?;
    if (themeStr != null) {
      if (themeStr == 'light') {
        state = ThemeMode.light;
      } else if (themeStr == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) {
      modeStr = 'light';
    } else if (mode == ThemeMode.dark) {
      modeStr = 'dark';
    }
    await _settingsBox.put('theme_mode', modeStr);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
