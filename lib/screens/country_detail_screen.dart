import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../repositories/country_repository.dart';
import '../state/country_list_notifier.dart';

class CountryDetailScreen extends StatelessWidget {
  final String id;

  const CountryDetailScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Страна'),
      ),
      body: FutureBuilder<Country?>(
        future: context.read<CountryRepository>().findById(id),
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

          final country = snapshot.data;

          if (country == null) {
            return const Center(
              child: Text('Страна не найдена'),
            );
          }

          return _CountryCard(country: country);
        },
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  final Country country;

  const _CountryCard({
    required this.country,
  });

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить страну?'),
        content: Text(
          'Вы действительно хотите удалить '
              '«${country.name}»?',
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
        .read<CountryListNotifier>()
        .deleteCountry(country.id);

    if (!context.mounted) return;

    context.go('/countries');
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
                      country.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Редактировать',
                    onPressed: () => context.go(
                      '/countries/${country.id}/edit',
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
                value: country.name,
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