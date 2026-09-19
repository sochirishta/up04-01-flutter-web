import 'package:flutter/material.dart';

import '../widgets/app_navigation_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кинотеатр')),
      drawer: const AppNavigationDrawer(currentRoute: '/'),
      body: const Center(child: Text('Выберите раздел кинотеатра')),
    );
  }
}
