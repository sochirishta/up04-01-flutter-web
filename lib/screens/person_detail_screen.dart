import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../repositories/person_repository.dart';
import '../state/person_list_notifier.dart';
import '../state/reference_cache.dart';

class PersonDetailScreen extends StatelessWidget {
  final String id;

  const PersonDetailScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Персона'),
      ),
      body: FutureBuilder<Person?>(
        future: context.read<PersonRepository>().findById(id),
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

          final person = snapshot.data;

          if (person == null) {
            return const Center(
              child: Text('Персона не найдена'),
            );
          }

          return _PersonCard(person: person);
        },
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;

  const _PersonCard({
    required this.person,
  });

  Future<void> _deletePerson(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить персону?'),
        content: Text(
          'Вы действительно хотите удалить '
              '«${person.fullName}»?',
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
        .read<PersonListNotifier>()
        .deletePerson(person.id);

    if (!context.mounted) return;

    context.go('/persons');
  }

  @override
  Widget build(BuildContext context) {
    final references = context.watch<ReferenceCache>();

    String countryName = person.countryId;

    for (final country in references.countries) {
      if (country.id == person.countryId) {
        countryName = country.name;
        break;
      }
    }

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
                      person.fullName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Редактировать',
                    onPressed: () {
                      context.go(
                        '/persons/${person.id}/edit',
                      );
                    },
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    tooltip: 'Удалить',
                    onPressed: () {
                      _deletePerson(context);
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InfoRow(
                label: 'ФИО',
                value: person.fullName,
              ),
              _InfoRow(
                label: 'Год рождения',
                value: '${person.birthYear}',
              ),
              _InfoRow(
                label: 'Страна',
                value: countryName,
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