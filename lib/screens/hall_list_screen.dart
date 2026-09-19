import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/hall.dart';
import '../models/hall_query.dart';
import '../state/entity_list_notifier.dart';
import '../state/hall_list_notifier.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class HallListScreen extends StatefulWidget {
  final HallQuery initialQuery;

  const HallListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<HallListScreen> createState() => _HallListScreenState();
}

class _HallListScreenState extends State<HallListScreen> {
  final _searchController = TextEditingController();
  final _capacityFromController = TextEditingController();
  final _capacityToController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final notifier = context.read<HallListNotifier>();

    _searchController.text = widget.initialQuery.search;
    _capacityFromController.text =
        widget.initialQuery.capacityFrom?.toString() ?? '';
    _capacityToController.text =
        widget.initialQuery.capacityTo?.toString() ?? '';

    notifier.addListener(_updateUrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      notifier.setQuery(widget.initialQuery);
    });
  }

  void _updateUrl() {
    if (!mounted) return;

    final notifier = context.read<HallListNotifier>();
    final location = notifier.urlFor(notifier.query);

    if (GoRouterState.of(context).uri.toString() != location) {
      context.go(location);
    }
  }

  @override
  void dispose() {
    context.read<HallListNotifier>().removeListener(_updateUrl);
    _searchController.dispose();
    _capacityFromController.dispose();
    _capacityToController.dispose();
    super.dispose();
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<HallListNotifier>();

    if (!notifier.hasSelection) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить залы?'),
        content: Text(
          'Вы действительно хотите удалить '
              '${notifier.selected.length} выбранных залов?',
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
    final notifier = context.watch<HallListNotifier>();
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
            tooltip: 'Добавить зал',
            onPressed: () => context.go('/halls/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(
        currentRoute: '/halls',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Залы',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Поиск',
              hintText: 'Название зала',
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
                  controller: _capacityFromController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Вместимость от',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    notifier.setCapacityFrom(
                      int.tryParse(value),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _capacityToController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Вместимость до',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    notifier.setCapacityTo(
                      int.tryParse(value),
                    );
                  },
                ),
              ),
              FilterChip(
                label: const Text('Удалённые'),
                selected: query.includeDeleted,
                onSelected: notifier.setIncludeDeleted,
              ),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  _capacityFromController.clear();
                  _capacityToController.clear();
                  notifier.resetFilters();
                },
                child: const Text('Сбросить'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
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
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Залы не найдены'),
              ),
            )
          else
            EntityTable<Hall>(
              items: result.items,
              selected: notifier.selected,
              idOf: (hall) => hall.id,
              onToggleSelect: notifier.toggleSelection,
              sortField: query.sortField,
              sortAscending: query.sortAscending,
              onSort: notifier.sort,
              columns: [
                TableColumnSpec<Hall>(
                  label: 'Название',
                  sortField: 'name',
                  build: (hall) => Text(hall.name),
                ),
                TableColumnSpec<Hall>(
                  label: 'Вместимость',
                  sortField: 'capacity',
                  numeric: true,
                  build: (hall) => Text('${hall.capacity}'),
                ),
              ],
              mobileItemBuilder: (hall) => Card(
                child: ListTile(
                  title: Text(hall.name),
                  subtitle: Text(
                    'Вместимость: ${hall.capacity}',
                  ),
                  onTap: () =>
                      context.go('/halls/${hall.id}'),
                  trailing: IconButton(
                    tooltip: 'Редактировать',
                    onPressed: () => context.go(
                      '/halls/${hall.id}/edit',
                    ),
                    icon: const Icon(Icons.edit),
                  ),
                ),
              ),
              actions: (hall) => [
                IconButton(
                  tooltip: 'Открыть',
                  onPressed: () =>
                      context.go('/halls/${hall.id}'),
                  icon: const Icon(Icons.open_in_new),
                ),
                IconButton(
                  tooltip: 'Редактировать',
                  onPressed: () => context.go(
                    '/halls/${hall.id}/edit',
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