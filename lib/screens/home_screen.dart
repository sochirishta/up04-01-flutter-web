import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../logic/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, themeMode, _) {
              return IconButton(
                onPressed: toggleTheme,
                icon: Icon(
                  themeMode == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/calculator'),
                icon: const Icon(Icons.calculate),
                label: const Text('Калькулятор'),
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: () => context.go('/converter'),
                icon: const Icon(Icons.currency_exchange),
                label: const Text('Конвертер валют'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}