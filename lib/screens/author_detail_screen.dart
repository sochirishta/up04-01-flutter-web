import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../state/author_list_notifier.dart';

class AuthorDetailScreen extends StatelessWidget {
  final int id;

  const AuthorDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Автор')),
      body: FutureBuilder<Author?>(
        future: context.read<AuthorRepository>().findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }

          final author = snapshot.data;

          if (author == null) {
            return const Center(child: Text('Автор не найден'));
          }

          return _AuthorCard(author: author);
        },
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  final Author author;

  const _AuthorCard({required this.author});

  Future<void> _deleteAuthor(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автора?'),
        content: Text(
          'Вы действительно хотите удалить автора '
          '«${author.fullName}»?',
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

    await context.read<AuthorListNotifier>().deleteAuthor(author.id);

    if (!context.mounted) return;

    context.go('/authors');
  }

  Future<void> _restoreAuthor(BuildContext context) async {
    await context.read<AuthorListNotifier>().restoreItem(author.id);

    if (!context.mounted) return;

    context.go('/authors');
  }

  Future<void> _hardDeleteAuthor(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автора окончательно?'),
        content: Text(
          'Автор «${author.fullName}» будет удалён без '
          'возможности восстановления.',
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

    await context.read<AuthorListNotifier>().hardDeleteItem(author.id);

    if (!context.mounted) return;

    context.go('/authors');
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
                      author.fullName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Редактировать',
                        onPressed: () {
                          context.go('/authors/${author.id}/edit');
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      if (!author.isDeleted)
                        IconButton(
                          tooltip: 'Удалить',
                          onPressed: () {
                            _deleteAuthor(context);
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      if (author.isDeleted)
                        IconButton(
                          tooltip: 'Восстановить',
                          onPressed: () {
                            _restoreAuthor(context);
                          },
                          icon: const Icon(Icons.restore),
                        ),
                      if (author.isDeleted)
                        IconButton(
                          tooltip: 'Удалить окончательно',
                          onPressed: () {
                            _hardDeleteAuthor(context);
                          },
                          icon: const Icon(Icons.delete_forever),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _InfoRow(label: 'ФИО', value: author.fullName),
              _InfoRow(
                label: 'Год рождения',
                value: author.birthYear.toString(),
              ),
              _InfoRow(label: 'Страна', value: author.country),

              if (author.isDeleted)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Автор удалён',
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
