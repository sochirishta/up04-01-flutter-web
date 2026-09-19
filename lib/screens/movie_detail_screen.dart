import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../repositories/movie_repository.dart';
import '../state/auth_notifier.dart';
import '../state/movie_list_notifier.dart';
import '../state/reference_cache.dart';
import '../models/app_user.dart';

class MovieDetailScreen extends StatelessWidget {
  final String id;

  const MovieDetailScreen({
    super.key,
    required this.id,
  });

  Future<void> _deleteMovie(
      BuildContext context,
      Movie movie,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить фильм?'),
        content: Text(
          'Вы действительно хотите удалить фильм '
              '«${movie.title}»?',
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
        .read<MovieListNotifier>()
        .deleteMovie(movie.id);

    if (!context.mounted) return;

    context.go('/movies');
  }

  Future<void> _restoreMovie(
      BuildContext context,
      Movie movie,
      ) async {
    await context
        .read<MovieListNotifier>()
        .restoreItem(movie.id);

    if (!context.mounted) return;

    context.go('/movies');
  }

  Future<void> _hardDeleteMovie(
      BuildContext context,
      Movie movie,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Удалить фильм окончательно?',
        ),
        content: Text(
          'Фильм «${movie.title}» будет удалён '
              'без возможности восстановления.',
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
            child: const Text(
              'Удалить окончательно',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context
        .read<MovieListNotifier>()
        .hardDeleteItem(movie.id);

    if (!context.mounted) return;

    context.go('/movies');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    final canManage = auth.hasRole(Role.manager);
    final canAdmin = auth.isExactly(Role.admin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Фильм'),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Редактировать',
              onPressed: () {
                context.go('/movies/$id/edit');
              },
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: FutureBuilder<Movie?>(
        future: context
            .read<MovieRepository>()
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

          final movie = snapshot.data;

          if (movie == null) {
            return const Center(
              child: Text('Фильм не найден'),
            );
          }

          return _MovieCard(
            movie: movie,
            canManage: canManage,
            canAdmin: canAdmin,
            onEdit: () {
              context.go(
                '/movies/${movie.id}/edit',
              );
            },
            onDelete: () {
              _deleteMovie(context, movie);
            },
            onRestore: () {
              _restoreMovie(context, movie);
            },
            onHardDelete: () {
              _hardDeleteMovie(context, movie);
            },
          );
        },
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final Movie movie;
  final bool canManage;
  final bool canAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onHardDelete;

  const _MovieCard({
    required this.movie,
    required this.canManage,
    required this.canAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
    required this.onHardDelete,
  });

  String _genreNames(BuildContext context) {
    final genres = context.read<ReferenceCache>().genres;

    final names = movie.genreIds
        .map((id) {
      for (final genre in genres) {
        if (genre.id == id) {
          return genre.name;
        }
      }

      return null;
    })
        .whereType<String>()
        .toList();

    return names.isEmpty ? '—' : names.join(', ');
  }

  String _personNames(BuildContext context) {
    final persons =
        context.read<ReferenceCache>().persons;

    final names = movie.personIds
        .map((id) {
      for (final person in persons) {
        if (person.id == id) {
          return person.fullName;
        }
      }

      return null;
    })
        .whereType<String>()
        .toList();

    return names.isEmpty ? '—' : names.join(', ');
  }

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
                  Expanded(
                    child: Text(
                      movie.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (canManage)
                        IconButton(
                          tooltip: 'Редактировать',
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit),
                        ),
                      if (canManage && !movie.isDeleted)
                        IconButton(
                          tooltip: 'Удалить',
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete),
                        ),
                      if (canAdmin && movie.isDeleted)
                        IconButton(
                          tooltip: 'Восстановить',
                          onPressed: onRestore,
                          icon: const Icon(Icons.restore),
                        ),
                      if (canAdmin && movie.isDeleted)
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
                label: 'Год',
                value: '${movie.year}',
              ),
              _InfoRow(
                label: 'Длительность',
                value: '${movie.duration} мин',
              ),
              _InfoRow(
                label: 'Жанры',
                value: _genreNames(context),
              ),
              _InfoRow(
                label: 'Персоны',
                value: _personNames(context),
              ),
              _InfoRow(
                label: 'ID',
                value: movie.id,
              ),

              if (movie.isDeleted)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Фильм удалён',
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
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}