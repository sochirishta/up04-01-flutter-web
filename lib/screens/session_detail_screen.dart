import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/session.dart';
import '../repositories/session_repository.dart';
import '../state/auth_notifier.dart';
import '../state/reference_cache.dart';
import '../state/session_list_notifier.dart';

class SessionDetailScreen extends StatelessWidget {
  final String id;

  const SessionDetailScreen({
    super.key,
    required this.id,
  });

  Future<void> _deleteSession(
      BuildContext context,
      CinemaSession session,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сеанс?'),
        content: const Text(
          'Сеанс будет помечен как удалённый.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context
        .read<SessionListNotifier>()
        .deleteSession(session.id);

    if (!context.mounted) return;

    context.go('/sessions');
  }

  Future<void> _restoreSession(
      BuildContext context,
      CinemaSession session,
      ) async {
    await context
        .read<SessionListNotifier>()
        .restoreItem(session.id);

    if (!context.mounted) return;

    context.go('/sessions');
  }

  Future<void> _hardDeleteSession(
      BuildContext context,
      CinemaSession session,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Удалить сеанс окончательно?',
        ),
        content: const Text(
          'Сеанс будет удалён без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(true),
            child: const Text('Удалить окончательно'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context
        .read<SessionListNotifier>()
        .hardDeleteItem(session.id);

    if (!context.mounted) return;

    context.go('/sessions');
  }

  String _movieName(
      BuildContext context,
      String movieId,
      ) {
    return movieId.isEmpty ? '—' : movieId;
  }

  String _hallName(
      BuildContext context,
      String hallId,
      ) {
    final halls = context.read<ReferenceCache>().halls;

    for (final hall in halls) {
      if (hall.id == hallId) {
        return '${hall.name} (${hall.capacity} мест)';
      }
    }

    return hallId.isEmpty ? '—' : hallId;
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    final canManage = auth.hasRole(Role.manager);
    final canAdmin = auth.isExactly(Role.admin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сеанс'),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Редактировать',
              onPressed: () {
                context.go('/sessions/$id/edit');
              },
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: FutureBuilder<CinemaSession?>(
        future: context
            .read<SessionRepository>()
            .findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
              ),
            );
          }

          final session = snapshot.data;

          if (session == null) {
            return const Center(
              child: Text('Сеанс не найден'),
            );
          }

          return _SessionCard(
            session: session,
            canManage: canManage,
            canAdmin: canAdmin,
            movieName: _movieName,
            hallName: _hallName,
            formatDateTime: _formatDateTime,
            onEdit: () {
              context.go('/sessions/${session.id}/edit');
            },
            onDelete: () {
              _deleteSession(context, session);
            },
            onRestore: () {
              _restoreSession(context, session);
            },
            onHardDelete: () {
              _hardDeleteSession(context, session);
            },
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final CinemaSession session;
  final bool canManage;
  final bool canAdmin;

  final String Function(
      BuildContext context,
      String movieId,
      ) movieName;

  final String Function(
      BuildContext context,
      String hallId,
      ) hallName;

  final String Function(DateTime value) formatDateTime;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onHardDelete;

  const _SessionCard({
    required this.session,
    required this.canManage,
    required this.canAdmin,
    required this.movieName,
    required this.hallName,
    required this.formatDateTime,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
    required this.onHardDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Информация о сеансе',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (canManage)
                        IconButton(
                          tooltip: 'Редактировать',
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit),
                        ),
                      if (canManage && !session.isDeleted)
                        IconButton(
                          tooltip: 'Удалить',
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete),
                        ),
                      if (canAdmin && session.isDeleted)
                        IconButton(
                          tooltip: 'Восстановить',
                          onPressed: onRestore,
                          icon: const Icon(Icons.restore),
                        ),
                      if (canAdmin && session.isDeleted)
                        IconButton(
                          tooltip: 'Удалить окончательно',
                          onPressed: onHardDelete,
                          icon: const Icon(
                            Icons.delete_forever,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InfoRow(
                label: 'Фильм',
                value: movieName(
                  context,
                  session.movieId,
                ),
              ),
              _InfoRow(
                label: 'ID фильма',
                value: session.movieId,
              ),
              _InfoRow(
                label: 'Зал',
                value: hallName(
                  context,
                  session.hallId,
                ),
              ),
              _InfoRow(
                label: 'Дата и время',
                value: formatDateTime(session.date),
              ),
              _InfoRow(
                label: 'ID',
                value: session.id,
              ),
              if (session.isDeleted)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Сеанс удалён',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
}