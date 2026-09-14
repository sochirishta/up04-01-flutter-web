import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../state/auth_notifier.dart';

class AppNavigationDrawer extends StatelessWidget {
  final String currentRoute;

  const AppNavigationDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Библиотека',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (auth.user != null) ...[
                    const SizedBox(height: 8),
                    Text(auth.user!.fullName),
                    Text(
                      _roleName(auth.user!.role),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (auth.isExactly(Role.reader))
              _item(
                context,
                icon: Icons.account_circle,
                title: 'Мой профиль',
                route: '/my-profile',
              ),
            _item(
              context,
              icon: Icons.menu_book,
              title: 'Книги',
              route: '/books',
            ),
            _item(
              context,
              icon: Icons.people,
              title: 'Авторы',
              route: '/authors',
            ),
            _item(
              context,
              icon: Icons.category,
              title: 'Жанры',
              route: '/genres',
            ),
            _item(
              context,
              icon: Icons.business,
              title: 'Издательства',
              route: '/publishers',
            ),
            if (auth.has(Role.librarian))
              _item(
                context,
                icon: Icons.person,
                title: 'Читатели',
                route: '/readers',
              ),
            if (auth.isExactly(Role.admin))
              _item(
                context,
                icon: Icons.admin_panel_settings,
                title: 'Пользователи',
                route: '/admin/users',
              ),
            _item(
              context,
              icon: Icons.assignment,
              title: 'Выдачи',
              route: '/loans',
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Выйти'),
              onTap: () async {
                await auth.logout();

                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final selected = currentRoute == route;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();

        if (!selected) {
          context.go(route);
        }
      },
    );
  }

  String _roleName(Role role) {
    switch (role) {
      case Role.reader:
        return 'Читатель';
      case Role.librarian:
        return 'Библиотекарь';
      case Role.admin:
        return 'Администратор';
    }
  }
}
