import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/hall.dart';
import '../repositories/hall_repository.dart';
import '../state/hall_list_notifier.dart';

class HallDetailScreen extends StatelessWidget {
  final String id;

  const HallDetailScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Зал'),
      ),
      body: FutureBuilder<Hall?>(
        future: context.read<HallRepository>().findById(id),
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

          final hall = snapshot.data;

          if (hall == null) {
            return const Center(
              child: Text('Зал не найден'),
            );
          }

          return _HallCard(hall: hall);
        },
      ),
    );
  }
}

class _HallCard extends StatelessWidget {
  final Hall hall;

  const _HallCard({
    required this.hall,
  });

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить зал?'),
        content: Text(
          'Вы действительно хотите удалить '
              '«${hall.name}»?',
        ),
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

    if (confirmed != true || !context.mounted) return;

    await context
        .read<HallListNotifier>()
        .deleteHall(hall.id);

    if (!context.mounted) return;

    context.go('/halls');
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
                children: [
                  Expanded(
                    child: Text(
                      hall.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Редактировать',
                    onPressed: () => context.go(
                      '/halls/${hall.id}/edit',
                    ),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    tooltip: 'Удалить',
                    onPressed: () => _delete(context),
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InfoRow(
                label: 'Название',
                value: hall.name,
              ),
              _InfoRow(
                label: 'Вместимость',
                value: '${hall.capacity}',
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}