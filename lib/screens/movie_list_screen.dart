import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/genre.dart';
import '../models/movie.dart';
import '../models/movie_query.dart';
import '../models/person.dart';

import '../repositories/movie_repository.dart';

import '../state/auth_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../state/movie_list_notifier.dart';
import '../state/reference_cache.dart';

import '../widgets/app_navigation_drawer.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class MovieListScreen extends StatefulWidget {
  final MovieQuery initialQuery;

  const MovieListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final _searchController = TextEditingController();
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();
  final _durationFromController = TextEditingController();
  final _durationToController = TextEditingController();

  late final MovieListNotifier _notifier;
  late final ReferenceCache _referenceCache;
  late final MovieRepository _movieRepository;

  List<Movie> _allMovies = [];

  @override
  void initState() {
    super.initState();

    _notifier = context.read<MovieListNotifier>();
    _referenceCache = context.read<ReferenceCache>();
    _movieRepository = context.read<MovieRepository>();

    _searchController.text = widget.initialQuery.search;
    _yearFromController.text =
        widget.initialQuery.yearFrom?.toString() ?? '';
    _yearToController.text =
        widget.initialQuery.yearTo?.toString() ?? '';
    _durationFromController.text =
        widget.initialQuery.durationFrom?.toString() ?? '';
    _durationToController.text =
        widget.initialQuery.durationTo?.toString() ?? '';

    _notifier.addListener(_updateUrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _notifier.setQuery(widget.initialQuery);
      _referenceCache.load();
      _loadAllMovies();
    });
  }

  Future<void> _loadAllMovies() async {
    try {
      final result = await _movieRepository.find(
        const MovieQuery(
          page: 1,
          size: 10000,
          includeDeleted: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        _allMovies = result.items;
      });
    } catch (_) {
      // Основная загрузка списка обрабатывается notifier.
    }
  }

  List<Genre> get _filteredGenres {
    final query = _notifier.query;

    final movies = _allMovies.where((movie) {
      if (query.personId != null &&
          !movie.personIds.contains(query.personId)) {
        return false;
      }

      return true;
    });

    final genreIds = movies
        .expand((movie) => movie.genreIds)
        .toSet();

    return _referenceCache.genres
        .where((genre) => genreIds.contains(genre.id))
        .toList();
  }

  List<Person> get _filteredPersons {
    final query = _notifier.query;

    final movies = _allMovies.where((movie) {
      if (query.genreId != null &&
          !movie.genreIds.contains(query.genreId)) {
        return false;
      }

      return true;
    });

    final personIds = movies
        .expand((movie) => movie.personIds)
        .toSet();

    return _referenceCache.persons
        .where((person) => personIds.contains(person.id))
        .toList();
  }

  String _genreNames(Movie movie) {
    final names = movie.genreIds
        .map((id) {
      for (final genre in _referenceCache.genres) {
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

  String _personNames(Movie movie) {
    final names = movie.personIds
        .map((id) {
      for (final person in _referenceCache.persons) {
        if (person.id == id) {
          return person.fullName;
        }
      }

      return null;
    })
        .whereType<String>()
        .toList();

    return names.isEmpty ? '—' : names.join(', ');
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
        title: const Text('Удалить фильмы?'),
        content: Text(
          'Вы действительно хотите удалить '
              '${_notifier.selected.length} выбранных фильмов?',
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
      await _notifier.deleteSelected();
      await _loadAllMovies();
    }
  }

  @override
  void dispose() {
    _notifier.removeListener(_updateUrl);

    _searchController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    _durationFromController.dispose();
    _durationToController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MovieListNotifier>();
    final references = context.watch<ReferenceCache>();
    final auth = context.watch<AuthNotifier>();

    final canManage = auth.hasRole(Role.manager);
    final canAdmin = auth.isExactly(Role.admin);

    final result = notifier.result;
    final query = notifier.query;

    if (notifier.status == LoadStatus.loading ||
        references.loading) {
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
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Добавить фильм',
              onPressed: () {
                context.go('/movies/new');
              },
            ),
        ],
      ),
      drawer: const AppNavigationDrawer(
        currentRoute: '/movies',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Фильмы',
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Поиск',
              hintText: 'Название фильма',
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
                width: 200,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: query.genreId,
                  decoration: const InputDecoration(
                    labelText: 'Жанр',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Все'),
                    ),
                    for (final genre in _filteredGenres)
                      DropdownMenuItem<String?>(
                        value: genre.id,
                        child: Text(
                          genre.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: notifier.setGenre,
                ),
              ),

              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: query.personId,
                  decoration: const InputDecoration(
                    labelText: 'Персона',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Все'),
                    ),
                    for (final person in _filteredPersons)
                      DropdownMenuItem<String?>(
                        value: person.id,
                        child: Text(
                          person.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: notifier.setPerson,
                ),
              ),

              SizedBox(
                width: 120,
                child: TextField(
                  controller: _yearFromController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Год до',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    notifier.setYearTo(int.tryParse(value));
                  },
                ),
              ),

              SizedBox(
                width: 140,
                child: TextField(
                  controller: _durationFromController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Минут от',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    notifier.setDurationFrom(
                      int.tryParse(value),
                    );
                  },
                ),
              ),

              SizedBox(
                width: 140,
                child: TextField(
                  controller: _durationToController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Минут до',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    notifier.setDurationTo(
                      int.tryParse(value),
                    );
                  },
                ),
              ),

              if (canManage)
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
                  _durationFromController.clear();
                  _durationToController.clear();

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
              if (canManage && notifier.hasSelection)
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
                child: Text('Фильмов не найдено'),
              ),
            )
          else
            EntityTable<Movie>(
              items: result.items,
              selected: notifier.selected,
              idOf: (movie) => movie.id,
              onToggleSelect:
              canManage ? notifier.toggleSelection : null,
              sortField: query.sortField,
              sortAscending: query.sortAscending,
              onSort: notifier.sort,

              mobileItemBuilder: (movie) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            if (canManage)
                              Checkbox(
                                value: notifier.selected
                                    .contains(movie.id),
                                onChanged: (_) {
                                  notifier.toggleSelection(
                                    movie.id,
                                  );
                                },
                              ),
                            Expanded(
                              child: Text(
                                movie.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Открыть',
                              onPressed: () {
                                context.go(
                                  '/movies/${movie.id}',
                                );
                              },
                              icon: const Icon(
                                Icons.open_in_new,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Год: ${movie.year}'),
                        Text('Длительность: ${movie.duration} мин'),
                        Text('Жанры: ${_genreNames(movie)}'),
                        Text('Персоны: ${_personNames(movie)}'),
                        if (movie.isDeleted)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Фильм удалён',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: [
                            if (canManage)
                              IconButton(
                                tooltip: 'Редактировать',
                                onPressed: () {
                                  context.go(
                                    '/movies/${movie.id}/edit',
                                  );
                                },
                                icon: const Icon(Icons.edit),
                              ),
                            if (canAdmin && movie.isDeleted)
                              IconButton(
                                tooltip: 'Восстановить',
                                onPressed: () {
                                  notifier.restoreItem(movie.id);
                                },
                                icon: const Icon(Icons.restore),
                              ),
                            if (canAdmin && movie.isDeleted)
                              IconButton(
                                tooltip: 'Удалить окончательно',
                                onPressed: () {
                                  notifier.hardDeleteItem(
                                    movie.id,
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_forever,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },

              columns: [
                TableColumnSpec<Movie>(
                  label: 'Название',
                  sortField: 'title',
                  build: (movie) => Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TableColumnSpec<Movie>(
                  label: 'Год',
                  sortField: 'year',
                  numeric: true,
                  build: (movie) => Text('${movie.year}'),
                ),
                TableColumnSpec<Movie>(
                  label: 'Длительность',
                  sortField: 'duration',
                  numeric: true,
                  build: (movie) =>
                      Text('${movie.duration} мин'),
                ),
                TableColumnSpec<Movie>(
                  label: 'Жанры',
                  build: (movie) => Text(
                    _genreNames(movie),
                  ),
                ),
                TableColumnSpec<Movie>(
                  label: 'Персоны',
                  build: (movie) => Text(
                    _personNames(movie),
                  ),
                ),
              ],

              actions: (movie) => [
                IconButton(
                  tooltip: 'Открыть',
                  onPressed: () {
                    context.go('/movies/${movie.id}');
                  },
                  icon: const Icon(Icons.open_in_new),
                ),
                if (canManage)
                  IconButton(
                    tooltip: 'Редактировать',
                    onPressed: () {
                      context.go(
                        '/movies/${movie.id}/edit',
                      );
                    },
                    icon: const Icon(Icons.edit),
                  ),
                if (canAdmin && movie.isDeleted)
                  IconButton(
                    tooltip: 'Восстановить',
                    onPressed: () {
                      notifier.restoreItem(movie.id);
                    },
                    icon: const Icon(Icons.restore),
                  ),
                if (canAdmin && movie.isDeleted)
                  IconButton(
                    tooltip: 'Удалить окончательно',
                    onPressed: () {
                      notifier.hardDeleteItem(movie.id);
                    },
                    icon: const Icon(Icons.delete_forever),
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