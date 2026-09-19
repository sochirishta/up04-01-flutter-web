import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../models/country_query.dart';
import '../state/country_list_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class CountryListScreen extends StatefulWidget {
  final CountryQuery initialQuery;

  const CountryListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<CountryListScreen> createState() => _CountryListScreenState();
}

class _CountryListScreenState extends State<CountryListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final notifier = context.read<CountryListNotifier>();

    _searchController.text = widget.initialQuery.search;
    notifier.addListener(_updateUrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      notifier.setQuery(widget.initialQuery);
    });
  }

  void _updateUrl() {
    if (!mounted) return;

    final notifier = context.read<CountryListNotifier>();
    final location = notifier.urlFor(notifier.query);

    if (GoRouterState.of(context).uri.toString() != location) {
      context.go(location);
    }
  }

  @override
  void dispose() {
    context.read<CountryListNotifier>().removeListener(_updateUrl);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<CountryListNotifier>();

    if (!notifier.hasSelection) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить страны?'),
        content: Text(
          'Вы действительно хотите удалить '
              '${notifier.selected.length} выбранных стран?',
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

    if (confirmed == true) {
      await notifier.deleteSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CountryListNotifier>();
    final result = notifier.result;
    final query = notifier.query;

    if (notifier.status == LoadStatus.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Добавить страну',
            onPressed: () => context.go('/countries/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(
        currentRoute: '/countries',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Страны',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Поиск',
              hintText: 'Название страны',
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
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('Найдено: ${result.total}'),
              FilterChip(
                label: const Text('Удалённые'),
                selected: query.includeDeleted,
                onSelected: notifier.setIncludeDeleted,
              ),
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
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Страны не найдены'),
              ),
            )
          else
            EntityTable<Country>(
              items: result.items,
              selected: notifier.selected,
              idOf: (country) => country.id,
              onToggleSelect: notifier.toggleSelection,
              sortField: query.sortField,
              sortAscending: query.sortAscending,
              onSort: notifier.sort,
              columns: [
                TableColumnSpec<Country>(
                  label: 'Название',
                  sortField: 'name',
                  build: (country) => Text(
                    country.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              mobileItemBuilder: (country) => Card(
                child: ListTile(
                  title: Text(country.name),
                  onTap: () =>
                      context.go('/countries/${country.id}'),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Открыть',
                        onPressed: () =>
                            context.go('/countries/${country.id}'),
                        icon: const Icon(Icons.open_in_new),
                      ),
                      IconButton(
                        tooltip: 'Редактировать',
                        onPressed: () => context.go(
                          '/countries/${country.id}/edit',
                        ),
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                ),
              ),
              actions: (country) => [
                IconButton(
                  tooltip: 'Открыть',
                  onPressed: () =>
                      context.go('/countries/${country.id}'),
                  icon: const Icon(Icons.open_in_new),
                ),
                IconButton(
                  tooltip: 'Редактировать',
                  onPressed: () => context.go(
                    '/countries/${country.id}/edit',
                  ),
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