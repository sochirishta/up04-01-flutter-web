import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../widgets/app_navigation_drawer.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  String? _error;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = context.read<Dio>();

      final response = await dio.get(
        '/users',
        queryParameters: {'page': 1, 'size': 100, 'sort': 'username,asc'},
      );

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;

      _users = items
          .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final exception = mapDioError(e);

      setState(() {
        _error = exception.message;
      });

      return;
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });

      return;
    } catch (_) {
      setState(() {
        _error = 'Не удалось загрузить пользователей.';
      });

      return;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление пользователями'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/admin/users'),
      body: Padding(padding: const EdgeInsets.all(16), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 48),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(child: Text('Пользователи не найдены'));
    }

    return Card(
      child: ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _users[index];

          return ListTile(
            leading: CircleAvatar(
              child: Text(user.username.substring(0, 1).toUpperCase()),
            ),
            title: Text(user.fullName),
            subtitle: Text(
              '@${user.username}\n${user.email ?? 'Email не указан'}',
            ),
            isThreeLine: true,
            trailing: Chip(label: Text(_roleName(user.role))),
          );
        },
      ),
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
