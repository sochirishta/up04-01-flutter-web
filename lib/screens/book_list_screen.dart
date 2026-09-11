import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/genre.dart';
import '../models/publisher.dart';

import '../repositories/book_repository.dart';

import '../state/book_list_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../state/reference_cache.dart';

import '../widgets/app_navigation_drawer.dart';
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

  late final BookListNotifier _notifier;
  late final ReferenceCache _referenceCache;
  late final BookRepository _bookRepository;

  List<Book> _allBooks = [];

  @override
  void initState() {
    super.initState();

    _notifier = context.read<BookListNotifier>();
    _referenceCache = context.read<ReferenceCache>();
    _bookRepository = context.read<BookRepository>();

    _searchController.text = widget.initialQuery.search;
    _yearFromController.text = widget.initialQuery.yearFrom?.toString() ?? '';
    _yearToController.text = widget.initialQuery.yearTo?.toString() ?? '';

    _notifier.addListener(_updateUrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _notifier.setQuery(widget.initialQuery);
      _referenceCache.load();
      _loadAllBooks();
    });
  }

  Future<void> _loadAllBooks() async {
    try {
      final booksResult = await _bookRepository.find(
        const BookQuery(size: 10000, includeDeleted: true),
      );

      if (!mounted) return;

      setState(() {
        _allBooks = booksResult.items;
      });
    } catch (_) {
      // Основная загрузка списка книг
      // обрабатывается через BookListNotifier.
    }
  }

  List<Author> get _filteredAuthors {
    final query = _notifier.query;
    final authors = _referenceCache.authors;

    final books = _allBooks.where((book) {
      if (query.publisherId != null && book.publisherId != query.publisherId) {
        return false;
      }

      if (query.genreId != null && !book.genreIds.contains(query.genreId)) {
        return false;
      }

      return true;
    });

    final authorIds = books.expand((book) => book.authorIds).toSet();

    return authors.where((author) => authorIds.contains(author.id)).toList();
  }

  List<Genre> get _filteredGenres {
    final query = _notifier.query;
    final genres = _referenceCache.genres;

    final books = _allBooks.where((book) {
      if (query.publisherId != null && book.publisherId != query.publisherId) {
        return false;
      }

      if (query.authorId != null && !book.authorIds.contains(query.authorId)) {
        return false;
      }

      return true;
    });

    final genreIds = books.expand((book) => book.genreIds).toSet();

    return genres.where((genre) => genreIds.contains(genre.id)).toList();
  }

  List<Publisher> get _filteredPublishers {
    final query = _notifier.query;
    final publishers = _referenceCache.publishers;

    final books = _allBooks.where((book) {
      if (query.authorId != null && !book.authorIds.contains(query.authorId)) {
        return false;
      }

      if (query.genreId != null && !book.genreIds.contains(query.genreId)) {
        return false;
      }

      return true;
    });

    final publisherIds = books.map((book) => book.publisherId).toSet();

    return publishers
        .where((publisher) => publisherIds.contains(publisher.id))
        .toList();
  }

  String _authorNames(Book book) {
    final authors = _referenceCache.authors;

    final names = book.authorIds
        .map((id) {
          for (final author in authors) {
            if (author.id == id) {
              return author.fullName;
            }
          }

          return null;
        })
        .whereType<String>()
        .toList();

    return names.isEmpty ? '—' : names.join(', ');
  }

  String _genreNames(Book book) {
    final genres = _referenceCache.genres;

    final names = book.genreIds
        .map((id) {
          for (final genre in genres) {
            if (genre.id == id) {
              return genre.name;
            }
          }

          return null;
        })
        .whereType<String>()
        .toList();

    return names.isEmpty ? '—' : names.join(', ');
  }

  String _publisherName(Book book) {
    final publishers = _referenceCache.publishers;

    for (final publisher in publishers) {
      if (publisher.id == book.publisherId) {
        return publisher.name;
      }
    }

    return '—';
  }

  void _updateUrl() {
    if (!mounted) return;

    final newLocation = _notifier.urlFor(_notifier.query);

    if (GoRouterState.of(context).uri.toString() != newLocation) {
      context.go(newLocation);
    }
  }

  Future<void> _deleteSelected() async {
    if (!_notifier.hasSelection) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книги?'),
        content: Text(
          'Вы действительно хотите удалить '
          '${_notifier.selected.length} выбранных книг?',
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
      await _notifier.deleteSelected();
    }
  }

  @override
  void dispose() {
    _notifier.removeListener(_updateUrl);

    _searchController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final references = context.watch<ReferenceCache>();

    final result = notifier.result;
    final query = notifier.query;

    if (notifier.status == LoadStatus.loading || references.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            tooltip: 'Добавить книгу',
            onPressed: () {
              context.go('/books/new');
            },
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/books'),
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
                width: 180,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: query.authorId,
                  decoration: const InputDecoration(
                    labelText: 'Автор',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Все'),
                    ),
                    for (final author in _filteredAuthors)
                      DropdownMenuItem<int?>(
                        value: author.id,
                        child: Text(
                          author.fullName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                  onChanged: notifier.setAuthor,
                ),
              ),

              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: query.genreId,
                  decoration: const InputDecoration(
                    labelText: 'Жанр',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Все'),
                    ),
                    for (final genre in _filteredGenres)
                      DropdownMenuItem<int?>(
                        value: genre.id,
                        child: Text(
                          genre.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                  onChanged: notifier.setGenre,
                ),
              ),

              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: query.publisherId,
                  decoration: const InputDecoration(
                    labelText: 'Издательство',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Все'),
                    ),
                    for (final publisher in _filteredPublishers)
                      DropdownMenuItem<int?>(
                        value: publisher.id,
                        child: Text(
                          publisher.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
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
                            onSelectionChanged: () {
                              notifier.toggleSelection(book.id);
                            },
                            onOpen: () {
                              context.go('/books/${book.id}');
                            },
                            onEdit: () {
                              context.go('/books/${book.id}/edit');
                            },
                            onRestore: book.isDeleted
                                ? () => notifier.restoreItem(book.id)
                                : null,
                            onHardDelete: book.isDeleted
                                ? () => notifier.hardDeleteItem(book.id)
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
                      label: 'Авторы',
                      build: (book) => Text(_authorNames(book)),
                    ),
                    TableColumnSpec<Book>(
                      label: 'Жанры',
                      build: (book) => Text(_genreNames(book)),
                    ),
                    TableColumnSpec<Book>(
                      label: 'Издательство',
                      build: (book) => Text(_publisherName(book)),
                    ),
                    TableColumnSpec<Book>(
                      label: 'Экземпляры',
                      build: (book) => Text(
                        '${book.copiesAvailable}/'
                        '${book.copiesTotal}',
                      ),
                    ),
                  ],
                  actions: (book) => [
                    IconButton(
                      tooltip: 'Открыть',
                      onPressed: () {
                        context.go('/books/${book.id}');
                      },
                      icon: const Icon(Icons.open_in_new),
                    ),
                    IconButton(
                      tooltip: 'Редактировать',
                      onPressed: () {
                        context.go('/books/${book.id}/edit');
                      },
                      icon: const Icon(Icons.edit),
                    ),
                    if (book.isDeleted)
                      IconButton(
                        tooltip: 'Восстановить',
                        onPressed: () {
                          notifier.restoreItem(book.id);
                        },
                        icon: const Icon(Icons.restore),
                      ),
                    if (book.isDeleted)
                      IconButton(
                        tooltip: 'Удалить окончательно',
                        onPressed: () {
                          notifier.hardDeleteItem(book.id);
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