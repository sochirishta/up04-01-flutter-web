import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../repositories/genre_repository.dart';
import '../state/genre_list_notifier.dart';

class GenreDetailScreen extends StatelessWidget {
  final int id;

  const GenreDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Жанр')),
      body: FutureBuilder<Genre?>(
        future: context.read<GenreRepository>().findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }

          final genre = snapshot.data;

          if (genre == null) {
            return const Center(child: Text('Жанр не найден'));
          }

          return _GenreCard(genre: genre);
        },
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  final Genre genre;

  const _GenreCard({required this.genre});

  Future<void> _deleteGenre(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить жанр?'),
        content: Text(
          'Вы действительно хотите удалить жанр '
          '«${genre.name}»?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<GenreListNotifier>().deleteGenre(genre.id);

    if (!context.mounted) return;

    context.go('/genres');
  }

  Future<void> _restoreGenre(BuildContext context) async {
    await context.read<GenreListNotifier>().restoreItem(genre.id);

    if (!context.mounted) return;

    context.go('/genres');
  }

  Future<void> _hardDeleteGenre(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить жанр окончательно?'),
        content: Text(
          'Жанр «${genre.name}» будет удалён без возможности '
          'восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Удалить окончательно'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<GenreListNotifier>().hardDeleteItem(genre.id);

    if (!context.mounted) return;

    context.go('/genres');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      genre.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Редактировать',
                        onPressed: () {
                          context.go('/genres/${genre.id}/edit');
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      if (!genre.isDeleted)
                        IconButton(
                          tooltip: 'Удалить',
                          onPressed: () {
                            _deleteGenre(context);
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      if (genre.isDeleted)
                        IconButton(
                          tooltip: 'Восстановить',
                          onPressed: () {
                            _restoreGenre(context);
                          },
                          icon: const Icon(Icons.restore),
                        ),
                      if (genre.isDeleted)
                        IconButton(
                          tooltip: 'Удалить окончательно',
                          onPressed: () {
                            _hardDeleteGenre(context);
                          },
                          icon: const Icon(Icons.delete_forever),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _InfoRow(label: 'Название', value: genre.name),
              _InfoRow(label: 'Описание', value: genre.description),

              if (genre.isDeleted)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Жанр удалён',
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

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
