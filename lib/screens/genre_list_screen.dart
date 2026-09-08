import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../models/genre_query.dart';
import '../state/entity_list_notifier.dart';
import '../state/genre_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/genre_card.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/app_navigation_drawer.dart';

class GenreListScreen extends StatefulWidget {
  final GenreQuery initialQuery;

  const GenreListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<GenreListScreen> createState() => _GenreListScreenState();
}

class _GenreListScreenState extends State<GenreListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final notifier = context.read<GenreListNotifier>();

    notifier.addListener(_updateUrl);

    notifier.setQuery(widget.initialQuery);
    _searchController.text = widget.initialQuery.search;
  }

  void _updateUrl() {
    if (!mounted) return;

    final notifier = context.read<GenreListNotifier>();
    final newLocation = notifier.urlFor(notifier.query);

    if (GoRouterState.of(context).uri.toString() != newLocation) {
      context.go(newLocation);
    }
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<GenreListNotifier>();

    if (!notifier.hasSelection) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить жанры?'),
        content: Text(
          'Вы действительно хотите удалить '
              '${notifier.selected.length} выбранных жанров?',
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
    context.read<GenreListNotifier>().removeListener(_updateUrl);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<GenreListNotifier>();
    final result = notifier.result;
    final query = notifier.query;

    if (notifier.status == LoadStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (notifier.status == LoadStatus.error) {
      return Center(
        child: Text(
          notifier.errorMessage ?? 'Ошибка загрузки',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить жанр',
            onPressed: () {
              context.go('/genres/new');
            },
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(
        currentRoute: '/genres',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Жанры',
            style: Theme.of(context).textTheme.headlineMedium,
          ),

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
                  label: Text(
                    'Удалить (${notifier.selected.length})',
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (result.items.isEmpty)
            const Center(
              child: Text('Жанры не найдены'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: result.items
                        .map(
                          (genre) => GenreCard(
                        genre: genre,
                        selected: notifier.selected.contains(genre.id),
                        onSelectionChanged: () {
                          notifier.toggleSelection(genre.id);
                        },
                        onOpen: () {
                          context.go('/genres/${genre.id}');
                        },
                        onEdit: () {
                          context.go('/genres/${genre.id}/edit');
                        },
                        onRestore: genre.isDeleted
                            ? () => notifier.restoreItem(genre.id)
                            : null,
                        onHardDelete: genre.isDeleted
                            ? () => notifier.hardDeleteItem(genre.id)
                            : null,
                      ),
                    )
                        .toList(),
                  );
                }

                return EntityTable<Genre>(
                  items: result.items,
                  selected: notifier.selected,
                  idOf: (genre) => genre.id,
                  onToggleSelect: notifier.toggleSelection,
                  sortField: query.sortField,
                  sortAscending: query.sortAscending,
                  onSort: notifier.sort,
                  columns: [
                    TableColumnSpec<Genre>(
                      label: 'Название',
                      sortField: 'name',
                      build: (genre) => Text(genre.name),
                    ),
                    TableColumnSpec<Genre>(
                      label: 'Описание',
                      sortField: 'description',
                      build: (genre) => Text(
                        genre.description,
                      ),
                    ),
                  ],
                  actions: (genre) => [
                    IconButton(
                      tooltip: 'Открыть',
                      onPressed: () {
                        context.go('/genres/${genre.id}');
                      },
                      icon: const Icon(Icons.open_in_new),
                    ),
                    IconButton(
                      tooltip: 'Редактировать',
                      onPressed: () {
                        context.go('/genres/${genre.id}/edit');
                      },
                      icon: const Icon(Icons.edit),
                    ),
                    if (genre.isDeleted)
                      IconButton(
                        tooltip: 'Восстановить',
                        onPressed: () {
                          notifier.restoreItem(genre.id);
                        },
                        icon: const Icon(Icons.restore),
                      ),
                    if (genre.isDeleted)
                      IconButton(
                        tooltip: 'Удалить окончательно',
                        onPressed: () {
                          notifier.hardDeleteItem(genre.id);
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