import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../models/person_query.dart';
import '../state/entity_list_notifier.dart';
import '../state/person_list_notifier.dart';
import '../state/reference_cache.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class PersonListScreen extends StatefulWidget {
  final PersonQuery initialQuery;

  const PersonListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends State<PersonListScreen> {
  final _searchController = TextEditingController();
  final _birthYearFromController = TextEditingController();
  final _birthYearToController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final notifier = context.read<PersonListNotifier>();

    _searchController.text = widget.initialQuery.search;
    _birthYearFromController.text =
        widget.initialQuery.birthYearFrom?.toString() ?? '';
    _birthYearToController.text =
        widget.initialQuery.birthYearTo?.toString() ?? '';

    notifier.addListener(_updateUrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ReferenceCache>().load();
      notifier.setQuery(widget.initialQuery);
    });
  }

  void _updateUrl() {
    if (!mounted) return;

    final notifier = context.read<PersonListNotifier>();
    final newLocation = notifier.urlFor(notifier.query);

    if (GoRouterState.of(context).uri.toString() != newLocation) {
      context.go(newLocation);
    }
  }

  @override
  void dispose() {
    context.read<PersonListNotifier>().removeListener(_updateUrl);
    _searchController.dispose();
    _birthYearFromController.dispose();
    _birthYearToController.dispose();
    super.dispose();
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<PersonListNotifier>();

    if (!notifier.hasSelection) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить персон?'),
        content: Text(
          'Вы действительно хотите удалить '
              '${notifier.selected.length} выбранных персон?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.deleteSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PersonListNotifier>();
    final references = context.watch<ReferenceCache>();
    final result = notifier.result;
    final query = notifier.query;

    if (notifier.status == LoadStatus.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (notifier.status == LoadStatus.error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notifier.errorMessage ?? 'Ошибка загрузки',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: notifier.load,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final countries = references.countries;

    String countryName(String id) {
      for (final country in countries) {
        if (country.id == id) {
          return country.name;
        }
      }
      return id;
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить персону',
            onPressed: () {
              context.go('/persons/new');
            },
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(
        currentRoute: '/persons',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Персоны',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Поиск',
              hintText: 'Имя и фамилия',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.search.isEmpty
                  ? null
                  : IconButton(
                onPressed: () {
                  _searchController.clear();
                  notifier.clearSearch();
                },
                icon: const Icon(Icons.clear),
              ),
              border: const OutlineInputBorder(),
            ),
            onChanged: notifier.search,
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _birthYearFromController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Год рождения от',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    notifier.setBirthYearFrom(
                      int.tryParse(value),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _birthYearToController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Год рождения до',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    notifier.setBirthYearTo(
                      int.tryParse(value),
                    );
                  },
                ),
              ),
              DropdownButton<String?>(
                value: query.countryId,
                hint: const Text('Страна'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все страны'),
                  ),
                  ...countries.map(
                        (country) => DropdownMenuItem<String?>(
                      value: country.id,
                      child: Text(country.name),
                    ),
                  ),
                ],
                onChanged: notifier.setCountry,
              ),
              FilterChip(
                label: const Text('Удалённые'),
                selected: query.includeDeleted,
                onSelected: notifier.setIncludeDeleted,
              ),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  _birthYearFromController.clear();
                  _birthYearToController.clear();
                  notifier.resetFilters();
                },
                child: const Text('Сбросить'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('Найдено: ${result.total}'),
              if (notifier.hasSelection)
                FilledButton.icon(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete),
                  label: Text(
                    'Удалить (${notifier.selected.length})',
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (result.items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Персоны не найдены'),
              ),
            )
          else
            EntityTable<Person>(
              items: result.items,
              selected: notifier.selected,
              idOf: (person) => person.id,
              onToggleSelect: notifier.toggleSelection,
              sortField: query.sortField,
              sortAscending: query.sortAscending,
              onSort: notifier.sort,
              mobileItemBuilder: (person) {
                return Card(
                  child: ListTile(
                    title: Text(person.fullName),
                    subtitle: Text(
                      '${person.birthYear} · '
                          '${countryName(person.countryId)}',
                    ),
                    onTap: () {
                      context.go('/persons/${person.id}');
                    },
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Открыть',
                          onPressed: () {
                            context.go('/persons/${person.id}');
                          },
                          icon: const Icon(Icons.open_in_new),
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
                      ],
                    ),
                  ),
                );
              },
              columns: [
                TableColumnSpec<Person>(
                  label: 'ФИО',
                  sortField: 'fullName',
                  build: (person) => Text(
                    person.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TableColumnSpec<Person>(
                  label: 'Год рождения',
                  sortField: 'birthYear',
                  numeric: true,
                  build: (person) => Text(
                    '${person.birthYear}',
                  ),
                ),
                TableColumnSpec<Person>(
                  label: 'Страна',
                  build: (person) => Text(
                    countryName(person.countryId),
                  ),
                ),
              ],
              actions: (person) => [
                IconButton(
                  tooltip: 'Открыть',
                  onPressed: () {
                    context.go('/persons/${person.id}');
                  },
                  icon: const Icon(Icons.open_in_new),
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
              ],
            ),

          if (result.total > 0)
            PaginationControls(
              page: result.page,
              totalPages: result.totalPages,
              hasPrevious: result.hasPrevious,
              hasNext: result.hasNext,
              pageSize: result.size,
              onFirst: notifier.firstPage,
              onPrevious: notifier.previousPage,
              onNext: notifier.nextPage,
              onLast: notifier.lastPage,
              onPageSizeChanged: notifier.changePageSize,
            ),
        ],
      ),
    );
  }
}