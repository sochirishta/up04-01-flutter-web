import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../state/auth_notifier.dart';

class AppNavigationDrawer extends StatelessWidget {
  final String currentRoute;

  const AppNavigationDrawer({
    super.key,
    required this.currentRoute,
  });

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
                    'Кинотеатр',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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

            _item(
              context,
              icon: Icons.movie,
              title: 'Фильмы',
              route: '/movies',
            ),

            _item(
              context,
              icon: Icons.category,
              title: 'Жанры',
              route: '/genres',
            ),

            _item(
              context,
              icon: Icons.person,
              title: 'Персоны',
              route: '/persons',
            ),

            _item(
              context,
              icon: Icons.public,
              title: 'Страны',
              route: '/countries',
            ),

            if (auth.hasRole(Role.manager))
              _item(
                context,
                icon: Icons.meeting_room,
                title: 'Залы',
                route: '/halls',
              ),

            _item(
              context,
              icon: Icons.schedule,
              title: 'Сеансы',
              route: '/sessions',
            ),

            if (auth.hasRole(Role.manager))
              _item(
                context,
                icon: Icons.event_seat,
                title: 'Брони',
                route: '/bookings',
              ),

            if (auth.hasRole(Role.manager))
              _item(
                context,
                icon: Icons.confirmation_number,
                title: 'Билеты',
                route: '/tickets',
              ),

            if (auth.isExactly(Role.admin))
              _item(
                context,
                icon: Icons.admin_panel_settings,
                title: 'Пользователи',
                route: '/admin/users',
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
    final selected =
        currentRoute == route ||
            (route != '/' && currentRoute.startsWith('$route/'));

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
      case Role.viewer:
        return 'Зритель';
      case Role.manager:
        return 'Менеджер';
      case Role.admin:
        return 'Администратор';
    }
  }
}