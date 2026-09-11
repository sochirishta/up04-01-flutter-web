import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavigationDrawer extends StatelessWidget {
  final String currentRoute;

  const AppNavigationDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const DrawerHeader(
              child: Center(
                child: Text(
                  'Библиотека',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
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

            _item(
              context,
              icon: Icons.person,
              title: 'Читатели',
              route: '/readers',
            ),

            _item(
              context,
              icon: Icons.assignment,
              title: 'Выдачи',
              route: '/loans',
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
}
