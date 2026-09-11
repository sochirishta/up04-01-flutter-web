import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../state/entity_list_notifier.dart';
import '../state/publisher_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/publisher_card.dart';
import '../widgets/app_navigation_drawer.dart';

class PublisherListScreen extends StatefulWidget {
  final PublisherQuery initialQuery;

  const PublisherListScreen({super.key, required this.initialQuery});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

class _PublisherListScreenState extends State<PublisherListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final notifier = context.read<PublisherListNotifier>();

    notifier.addListener(_updateUrl);

    notifier.setQuery(widget.initialQuery);

    _searchController.text = widget.initialQuery.search;
  }

  void _updateUrl() {
    if (!mounted) return;

    final notifier = context.read<PublisherListNotifier>();

    final newLocation = notifier.urlFor(notifier.query);

    if (GoRouterState.of(context).uri.toString() != newLocation) {
      context.go(newLocation);
    }
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<PublisherListNotifier>();

    if (!notifier.hasSelection) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить издателей?'),
        content: Text(
          'Вы действительно хотите удалить '
          '${notifier.selected.length} выбранных издателей?',
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

    if (confirmed == true) {
      await notifier.deleteSelected();
    }
  }

  @override
  void dispose() {
    context.read<PublisherListNotifier>().removeListener(_updateUrl);

    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PublisherListNotifier>();

    final result = notifier.result;
    final query = notifier.query;

    if (notifier.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.status == LoadStatus.error) {
      return Center(child: Text(notifier.errorMessage ?? 'Ошибка загрузки'));
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить издателя',
            onPressed: () {
              context.go('/publishers/new');
            },
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/publishers'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Издатели', style: Theme.of(context).textTheme.headlineMedium),

          const SizedBox(height: 16),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Поиск',
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Найдено: ${result.total}'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Удалённые'),
                  Switch(
                    value: query.includeDeleted,
                    onChanged: notifier.setIncludeDeleted,
                  ),
                ],
              ),
              if (notifier.hasSelection)
                FilledButton.icon(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete),
                  label: Text('Удалить (${notifier.selected.length})'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (result.items.isEmpty)
            const Center(child: Text('Издатели не найдены'))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: result.items
                        .map(
                          (publisher) => PublisherCard(
                            publisher: publisher,
                            selected: notifier.selected.contains(publisher.id),
                            onSelectionChanged: () {
                              notifier.toggleSelection(publisher.id);
                            },
                            onOpen: () {
                              context.go('/publishers/${publisher.id}');
                            },
                            onEdit: () {
                              context.go('/publishers/${publisher.id}/edit');
                            },
                            onRestore: publisher.isDeleted
                                ? () => notifier.restoreItem(publisher.id)
                                : null,
                            onHardDelete: publisher.isDeleted
                                ? () => notifier.hardDeleteItem(publisher.id)
                                : null,
                          ),
                        )
                        .toList(),
                  );
                }

                return EntityTable<Publisher>(
                  items: result.items,
                  selected: notifier.selected,
                  idOf: (publisher) => publisher.id,
                  onToggleSelect: notifier.toggleSelection,
                  sortField: query.sortField,
                  sortAscending: query.sortAscending,
                  onSort: notifier.sort,
                  columns: [
                    TableColumnSpec<Publisher>(
                      label: 'Название',
                      sortField: 'name',
                      build: (publisher) => Text(publisher.name),
                    ),
                    TableColumnSpec<Publisher>(
                      label: 'Город',
                      sortField: 'city',
                      build: (publisher) => Text(publisher.city),
                    ),
                    TableColumnSpec<Publisher>(
                      label: 'Год основания',
                      sortField: 'foundedYear',
                      build: (publisher) =>
                          Text(publisher.foundedYear.toString()),
                    ),
                  ],
                  actions: (publisher) => [
                    IconButton(
                      tooltip: 'Открыть',
                      onPressed: () {
                        context.go('/publishers/${publisher.id}');
                      },
                      icon: const Icon(Icons.open_in_new),
                    ),
                    IconButton(
                      tooltip: 'Редактировать',
                      onPressed: () {
                        context.go('/publishers/${publisher.id}/edit');
                      },
                      icon: const Icon(Icons.edit),
                    ),
                    if (publisher.isDeleted)
                      IconButton(
                        tooltip: 'Восстановить',
                        onPressed: () {
                          notifier.restoreItem(publisher.id);
                        },
                        icon: const Icon(Icons.restore),
                      ),
                    if (publisher.isDeleted)
                      IconButton(
                        tooltip: 'Удалить окончательно',
                        onPressed: () {
                          notifier.hardDeleteItem(publisher.id);
                        },
                        icon: const Icon(Icons.delete_forever),
                      ),
                  ],
                );
              },
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
