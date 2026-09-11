import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/reader_repository.dart';
import '../state/reader_list_notifier.dart';

class ReaderDetailScreen extends StatelessWidget {
  final int id;

  const ReaderDetailScreen({super.key, required this.id});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить читателя?'),
        content: const Text('Читатель будет мягко удалён.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final notifier = context.read<ReaderListNotifier>();

    try {
      await notifier.deleteReader(id);

      if (!context.mounted) return;

      context.go('/readers');
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Читатель')),
      body: FutureBuilder(
        future: context.read<ReaderRepository>().findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }

          final reader = snapshot.data;

          if (reader == null) {
            return const Center(child: Text('Читатель не найден'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reader.fullName,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Редактировать',
                          onPressed: () => context.go('/readers/$id/edit'),
                          icon: const Icon(Icons.edit),
                        ),
                        if (!reader.isDeleted)
                          IconButton(
                            tooltip: 'Удалить',
                            onPressed: () => _delete(context),
                            icon: const Icon(Icons.delete),
                          ),
                        if (reader.isDeleted) ...[
                          IconButton(
                            tooltip: 'Восстановить',
                            onPressed: () async {
                              final notifier = context
                                  .read<ReaderListNotifier>();

                              await notifier.restoreItem(id);

                              if (!context.mounted) {
                                return;
                              }

                              context.go('/readers');
                            },
                            icon: const Icon(Icons.restore),
                          ),
                          IconButton(
                            tooltip: 'Удалить окончательно',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Удалить окончательно?'),
                                  content: const Text(
                                    'Восстановление '
                                    'будет невозможно.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Отмена'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Удалить'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed != true || !context.mounted) {
                                return;
                              }

                              final notifier = context
                                  .read<ReaderListNotifier>();

                              await notifier.hardDeleteItem(id);

                              if (!context.mounted) {
                                return;
                              }

                              context.go('/readers');
                            },
                            icon: const Icon(Icons.delete_forever),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    _InfoRow(label: 'ФИО', value: reader.fullName),
                    _InfoRow(label: 'Email', value: reader.email),
                    _InfoRow(label: 'Телефон', value: reader.phone),
                    const SizedBox(height: 12),
                    Text(
                      'Библиотечная карта',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (reader.card == null)
                      const Text('Карта отсутствует')
                    else ...[
                      _InfoRow(label: 'Номер', value: reader.card!.number),
                      _InfoRow(
                        label: 'Выдана',
                        value: _date(reader.card!.issuedAt),
                      ),
                      _InfoRow(
                        label: 'Действует до',
                        value: _date(reader.card!.expiresAt),
                      ),
                    ],
                    if (reader.isDeleted)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Читатель удалён',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _date(DateTime value) {
    return value.toLocal().toString().split(' ').first;
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
