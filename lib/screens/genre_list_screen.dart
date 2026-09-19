import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../models/genre_query.dart';
import '../state/entity_list_notifier.dart';
import '../state/genre_list_notifier.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

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

    _searchController.text = widget.initialQuery.search;

    notifier.addListener(_updateUrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      notifier.setQuery(widget.initialQuery);
    });
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
              hintText: 'Название жанра',
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
                child: Text('Жанры не найдены'),
              ),
            )
          else
            EntityTable<Genre>(
              items: result.items,
              selected: notifier.selected,
              idOf: (genre) => genre.id,
              onToggleSelect: notifier.toggleSelection,
              sortField: query.sortField,
              sortAscending: query.sortAscending,
              onSort: notifier.sort,
              mobileItemBuilder: (genre) {
                return Card(
                  child: ListTile(
                    title: Text(genre.name),
                    onTap: () {
                      context.go('/genres/${genre.id}');
                    },
                    trailing: Wrap(
                      children: [
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
                            context.go(
                              '/genres/${genre.id}/edit',
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
                TableColumnSpec<Genre>(
                  label: 'Название',
                  sortField: 'name',
                  build: (genre) => Text(
                    genre.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    context.go(
                      '/genres/${genre.id}/edit',
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