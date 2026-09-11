import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/publisher.dart';
import '../repositories/publisher_repository.dart';
import '../state/publisher_list_notifier.dart';

class PublisherDetailScreen extends StatelessWidget {
  final int id;

  const PublisherDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Издатель')),
      body: FutureBuilder<Publisher?>(
        future: context.read<PublisherRepository>().findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: '
                '${snapshot.error}',
              ),
            );
          }

          final publisher = snapshot.data;

          if (publisher == null) {
            return const Center(child: Text('Издатель не найден'));
          }

          return _PublisherCard(publisher: publisher);
        },
      ),
    );
  }
}

class _PublisherCard extends StatelessWidget {
  final Publisher publisher;

  const _PublisherCard({required this.publisher});

  Future<void> _deletePublisher(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить издателя?'),
        content: Text(
          'Вы действительно хотите удалить '
          'издателя «${publisher.name}»?',
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

    await context.read<PublisherListNotifier>().deletePublisher(publisher.id);

    if (!context.mounted) return;

    context.go('/publishers');
  }

  Future<void> _restorePublisher(BuildContext context) async {
    await context.read<PublisherListNotifier>().restoreItem(publisher.id);

    if (!context.mounted) return;

    context.go('/publishers');
  }

  Future<void> _hardDeletePublisher(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить издателя окончательно?'),
        content: Text(
          'Издатель «${publisher.name}» '
          'будет удалён без возможности '
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

    await context.read<PublisherListNotifier>().hardDeleteItem(publisher.id);

    if (!context.mounted) return;

    context.go('/publishers');
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
                      publisher.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Редактировать',
                        onPressed: () {
                          context.go(
                            '/publishers/'
                            '${publisher.id}'
                            '/edit',
                          );
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      if (!publisher.isDeleted)
                        IconButton(
                          tooltip: 'Удалить',
                          onPressed: () {
                            _deletePublisher(context);
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      if (publisher.isDeleted)
                        IconButton(
                          tooltip: 'Восстановить',
                          onPressed: () {
                            _restorePublisher(context);
                          },
                          icon: const Icon(Icons.restore),
                        ),
                      if (publisher.isDeleted)
                        IconButton(
                          tooltip: 'Удалить окончательно',
                          onPressed: () {
                            _hardDeletePublisher(context);
                          },
                          icon: const Icon(Icons.delete_forever),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _InfoRow(label: 'Название', value: publisher.name),
              _InfoRow(label: 'Город', value: publisher.city),
              _InfoRow(
                label: 'Год основания',
                value: '${publisher.foundedYear}',
              ),

              if (publisher.isDeleted)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Издатель удалён',
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
