import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

Future<bool> loadDarkTheme() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('dark_theme') ?? false;
}

Future<void> saveDarkTheme(bool isDark) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('dark_theme', isDark);
}

ThemeMode getThemeMode(bool isDark) {
  return isDark ? ThemeMode.dark : ThemeMode.light;
}

Future<void> toggleTheme() async {
  final isDark = themeNotifier.value == ThemeMode.dark;
  final newIsDark = !isDark;

  themeNotifier.value = getThemeMode(newIsDark);
  await saveDarkTheme(newIsDark);
}