import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const String _themeKey = 'theme_mode';
  
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0; // 0 = system por padrão
    
    switch (themeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    int themeIndex = 0;
    
    switch (mode) {
      case ThemeMode.light:
        themeIndex = 1;
        break;
      case ThemeMode.dark:
        themeIndex = 2;
        break;
      case ThemeMode.system:
        themeIndex = 0;
        break;
    }
    
    await prefs.setInt(_themeKey, themeIndex);
    state = AsyncValue.data(mode);
  }

  Future<void> toggleTheme() async {
    final currentTheme = await future;
    
    switch (currentTheme) {
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
    }
  }
}