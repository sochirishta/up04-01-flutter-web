import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author_query.dart';
import '../models/author.dart';
import '../state/author_list_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/author_card.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class AuthorListScreen extends StatefulWidget {
  final AuthorQuery initialQuery;

  const AuthorListScreen({super.key, required this.initialQuery});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final notifier = context.read<AuthorListNotifier>();
    
    notifier.addListener(_updateUrl);

    notifier.setQuery(widget.initialQuery);
    _searchController.text = widget.initialQuery.search;
  }

  void _updateUrl() {
    if (!mounted) return;
    final notifier = context.read<AuthorListNotifier>();
    final newLocation = notifier.urlFor(notifier.query);
    if (GoRouterState.of(context).uri.toString() != newLocation) {
      context.go(newLocation);
    }
  }

  @override
  void dispose() {
    context.read<AuthorListNotifier>().removeListener(_updateUrl);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
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
        title: const Text('Авторы'),
        actions: [
          TextButton(
            onPressed: () => context.go('/books'),
            child: const Text('Книги'),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Авторы', style: Theme.of(context).textTheme.headlineMedium),
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

          Row(
            children: [
              Text('Найдено: ${result.total}'),
              const Spacer(),
              const Text('Удалённые'),
              Switch(
                value: query.includeDeleted,
                onChanged: notifier.setIncludeDeleted,
              ),
            ],
          ),

          if (notifier.hasSelection)
            FilledButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Удалить авторов?'),
                    content: Text(
                      'Вы действительно хотите удалить '
                          '${notifier.selected.length} выбранных авторов?',
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
              },
              icon: const Icon(Icons.delete),
              label: Text(
                'Удалить (${notifier.selected.length})',
              ),
            ),

          const SizedBox(height: 16),

          if (result.items.isEmpty)
            const Center(child: Text('Авторы не найдены'))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: result.items
                        .map(
                          (author) => AuthorCard(
                            author: author,
                            selected: notifier.selected.contains(author.id),
                            onSelectionChanged: () =>
                                notifier.toggleSelection(author.id),
                            onOpen: () => context.go('/authors/${author.id}'),
                            onRestore: author.isDeleted
                                ? () => notifier.restore(author.id)
                                : null,
                            onHardDelete: author.isDeleted
                                ? () => notifier.hardDelete(author.id)
                                : null,
                          ),
                        )
                        .toList(),
                  );
                }

                return EntityTable<Author>(
                  items: result.items,
                  selected: notifier.selected,
                  idOf: (author) => author.id,
                  onToggleSelect: notifier.toggleSelection,
                  sortField: query.sortField,
                  sortAscending: query.sortAscending,
                  onSort: notifier.sort,
                  columns: [
                    TableColumnSpec<Author>(
                      label: 'Имя',
                      sortField: 'firstName',
                      build: (author) => Text(author.firstName),
                    ),
                    TableColumnSpec<Author>(
                      label: 'Фамилия',
                      sortField: 'lastName',
                      build: (author) => Text(author.lastName),
                    ),
                    TableColumnSpec<Author>(
                      label: 'Страна',
                      sortField: 'country',
                      build: (author) => Text(author.country),
                    ),
                  ],
                  actions: (author) => [
                    IconButton(
                      onPressed: () => context.go('/authors/${author.id}'),
                      icon: const Icon(Icons.open_in_new),
                    ),
                    if (author.isDeleted)
                      IconButton(
                        onPressed: () => notifier.restore(author.id),
                        icon: const Icon(Icons.restore),
                      ),
                    if (author.isDeleted)
                      IconButton(
                        onPressed: () => notifier.hardDelete(author.id),
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