import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book_query.dart';
import '../models/book.dart';
import '../state/book_list_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/book_card.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class BookListScreen extends StatefulWidget {
  final BookQuery initialQuery;

  const BookListScreen({super.key, required this.initialQuery});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _searchController = TextEditingController();
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final notifier = context.read<BookListNotifier>();

    notifier.addListener(_updateUrl);

    notifier.setQuery(widget.initialQuery);

    _searchController.text = widget.initialQuery.search;
    _yearFromController.text = widget.initialQuery.yearFrom?.toString() ?? '';
    _yearToController.text = widget.initialQuery.yearTo?.toString() ?? '';
  }

  void _updateUrl() {
    if (!mounted) return;
    final notifier = context.read<BookListNotifier>();
    final newLocation = notifier.urlFor(notifier.query);
    if (GoRouterState.of(context).uri.toString() != newLocation) {
      context.go(newLocation);
    }
  }

  @override
  void dispose() {
    context.read<BookListNotifier>().removeListener(_updateUrl);
    _searchController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final result = notifier.result;
    final query = notifier.query;

    if (notifier.status == LoadStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (notifier.status == LoadStatus.error) {
      return Scaffold(
        body: Center(child: Text(notifier.errorMessage ?? 'Ошибка загрузки')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книги'),
        actions: [
          TextButton(
            onPressed: () => context.go('/authors'),
            child: const Text('Авторы'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Книги', style: Theme.of(context).textTheme.headlineMedium),

          const SizedBox(height: 16),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Поиск',
              hintText: 'Название или ISBN',
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<int?>(
                  initialValue: query.genreId,
                  decoration: const InputDecoration(
                    labelText: 'Жанр ID',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Все'),
                    ),
                    for (final id in List.generate(10, (index) => index + 1))
                      DropdownMenuItem<int?>(value: id, child: Text('ID $id')),
                  ],
                  onChanged: notifier.setGenre,
                ),
              ),

              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int?>(
                  initialValue: query.publisherId,
                  decoration: const InputDecoration(
                    labelText: 'Издатель ID',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Все'),
                    ),
                    for (final id in List.generate(10, (index) => index + 1))
                      DropdownMenuItem<int?>(value: id, child: Text('ID $id')),
                  ],
                  onChanged: notifier.setPublisher,
                ),
              ),

              SizedBox(
                width: 120,
                child: TextField(
                  controller: _yearFromController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Год от',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    notifier.setYearFrom(int.tryParse(value));
                  },
                ),
              ),

              SizedBox(
                width: 120,
                child: TextField(
                  controller: _yearToController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Год до',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    notifier.setYearTo(int.tryParse(value));
                  },
                ),
              ),

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

              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  _yearFromController.clear();
                  _yearToController.clear();
                  notifier.resetFilters();
                },
                child: const Text('Сбросить'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Text('Найдено: ${result.total}'),
              const Spacer(),
              if (notifier.hasSelection)
                FilledButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Удалить книги?'),
                        content: Text(
                          'Вы действительно хотите удалить '
                          '${notifier.selected.length} выбранных книг?',
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
                  label: Text('Удалить (${notifier.selected.length})'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (result.items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Книг не найдено'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: result.items
                        .map(
                          (book) => BookCard(
                            book: book,
                            selected: notifier.selected.contains(book.id),
                            onSelectionChanged: () =>
                                notifier.toggleSelection(book.id),
                            onOpen: () => context.go('/books/${book.id}'),
                            onRestore: book.isDeleted
                                ? () => notifier.restore(book.id)
                                : null,
                            onHardDelete: book.isDeleted
                                ? () => notifier.hardDelete(book.id)
                                : null,
                          ),
                        )
                        .toList(),
                  );
                }

                return EntityTable<Book>(
                  items: result.items,
                  selected: notifier.selected,
                  idOf: (book) => book.id,
                  onToggleSelect: notifier.toggleSelection,
                  sortField: query.sortField,
                  sortAscending: query.sortAscending,
                  onSort: notifier.sort,
                  columns: [
                    TableColumnSpec<Book>(
                      label: 'Название',
                      sortField: 'title',
                      build: (book) => Text(book.title),
                    ),
                    TableColumnSpec<Book>(
                      label: 'ISBN',
                      sortField: 'isbn',
                      build: (book) => Text(book.isbn),
                    ),
                    TableColumnSpec<Book>(
                      label: 'Год',
                      sortField: 'year',
                      numeric: true,
                      build: (book) => Text('${book.year}'),
                    ),
                    TableColumnSpec<Book>(
                      label: 'Страницы',
                      sortField: 'pages',
                      numeric: true,
                      build: (book) => Text('${book.pages}'),
                    ),
                    TableColumnSpec<Book>(
                      label: 'Жанр ID',
                      build: (book) => Text(book.genreIds.join(', ')),
                    ),
                    TableColumnSpec<Book>(
                      label: 'Издатель ID',
                      build: (book) => Text('${book.publisherId}'),
                    ),
                    TableColumnSpec<Book>(
                      label: 'Экземпляры',
                      build: (book) =>
                          Text('${book.copiesAvailable}/${book.copiesTotal}'),
                    ),
                  ],
                  actions: (book) => [
                    IconButton(
                      tooltip: 'Открыть',
                      onPressed: () => context.go('/books/${book.id}'),
                      icon: const Icon(Icons.open_in_new),
                    ),
                    if (book.isDeleted)
                      IconButton(
                        tooltip: 'Восстановить',
                        onPressed: () => notifier.restore(book.id),
                        icon: const Icon(Icons.restore),
                      ),
                    if (book.isDeleted)
                      IconButton(
                        tooltip: 'Удалить окончательно',
                        onPressed: () => notifier.hardDelete(book.id),
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
