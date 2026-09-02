import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'logic/theme.dart';
import 'router.dart';

void main() {
  usePathUrlStrategy();
  _initTheme();
  runApp(const MyApp());
}

Future<void> _initTheme() async {
  final isDark = await loadDarkTheme();
  themeNotifier.value = getThemeMode(isDark);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: 'UP04.01 Flutter Web',
          debugShowCheckedModeBanner: false,

          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
            ),
            useMaterial3: true,
          ),

          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),

          themeMode: themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}