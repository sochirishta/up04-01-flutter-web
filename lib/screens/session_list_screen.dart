import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../models/movie_query.dart';
import '../models/session.dart';
import '../models/session_query.dart';
import '../repositories/movie_repository.dart';
import '../state/entity_list_notifier.dart';
import '../state/reference_cache.dart';
import '../state/session_list_notifier.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class SessionListScreen extends StatefulWidget {
  final SessionQuery initialQuery;

  const SessionListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  final _searchController = TextEditingController();

  List<Movie> _movies = [];

  @override
  void initState() {
    super.initState();

    final notifier = context.read<SessionListNotifier>();

    _searchController.text = widget.initialQuery.search;
    notifier.addListener(_updateUrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ReferenceCache>().load();
      notifier.setQuery(widget.initialQuery);
      _loadMovies();
    });
  }

  Future<void> _loadMovies() async {
    try {
      final repository = context.read<MovieRepository>();

      final result = await repository.find(
        const MovieQuery(
          page: 1,
          size: 10000,
          includeDeleted: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        _movies = result.items;
      });
    } catch (_) {
      // Ошибка загрузки фильмов не должна ломать список сеансов.
    }
  }

  void _updateUrl() {
    if (!mounted) return;

    final notifier = context.read<SessionListNotifier>();
    final location = notifier.urlFor(notifier.query);

    if (GoRouterState.of(context).uri.toString() != location) {
      context.go(location);
    }
  }

  @override
  void dispose() {
    context.read<SessionListNotifier>().removeListener(_updateUrl);
    _searchController.dispose();
    super.dispose();
  }

  String _movieName(String id) {
    for (final movie in _movies) {
      if (movie.id == id) {
        return movie.title;
      }
    }

    return id;
  }

  String _hallName(ReferenceCache cache, String id) {
    for (final hall in cache.halls) {
      if (hall.id == id) {
        return hall.name;
      }
    }

    return id;
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<SessionListNotifier>();

    if (!notifier.hasSelection) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сеансы?'),
        content: Text(
          'Вы действительно хотите удалить '
              '${notifier.selected.length} выбранных сеансов?',
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
    final notifier = context.watch<SessionListNotifier>();
    final cache = context.watch<ReferenceCache>();
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
            tooltip: 'Добавить сеанс',
            onPressed: () => context.go('/sessions/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(
        currentRoute: '/sessions',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Сеансы',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Поиск',
              hintText: 'Поиск сеансов',
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
              DropdownButton<String?>(
                value: query.movieId,
                hint: const Text('Фильм'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все фильмы'),
                  ),
                  ..._movies.map(
                        (movie) => DropdownMenuItem<String?>(
                      value: movie.id,
                      child: Text(movie.title),
                    ),
                  ),
                ],
                onChanged: notifier.setMovie,
              ),
              DropdownButton<String?>(
                value: query.hallId,
                hint: const Text('Зал'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все залы'),
                  ),
                  ...cache.halls.map(
                        (hall) => DropdownMenuItem<String?>(
                      value: hall.id,
                      child: Text(hall.name),
                    ),
                  ),
                ],
                onChanged: notifier.setHall,
              ),
              FilterChip(
                label: const Text('Удалённые'),
                selected: query.includeDeleted,
                onSelected: notifier.setIncludeDeleted,
              ),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
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
                child: Text('Сеансы не найдены'),
              ),
            )
          else
            EntityTable<CinemaSession>(
              items: result.items,
              selected: notifier.selected,
              idOf: (session) => session.id,
              onToggleSelect: notifier.toggleSelection,
              sortField: query.sortField,
              sortAscending: query.sortAscending,
              onSort: notifier.sort,
              columns: [
                TableColumnSpec<CinemaSession>(
                  label: 'Фильм',
                  sortField: 'movie',
                  build: (session) => Text(
                    _movieName(session.movieId),
                  ),
                ),
                TableColumnSpec<CinemaSession>(
                  label: 'Зал',
                  sortField: 'hall',
                  build: (session) => Text(
                    _hallName(cache, session.hallId),
                  ),
                ),
                TableColumnSpec<CinemaSession>(
                  label: 'Дата',
                  sortField: 'date',
                  build: (session) => Text(
                    session.date.toLocal().toString(),
                  ),
                ),
              ],
              mobileItemBuilder: (session) => Card(
                child: ListTile(
                  title: Text(
                    _movieName(session.movieId),
                  ),
                  subtitle: Text(
                    '${_hallName(cache, session.hallId)}\n'
                        '${session.date.toLocal()}',
                  ),
                  onTap: () =>
                      context.go('/sessions/${session.id}'),
                  trailing: IconButton(
                    tooltip: 'Редактировать',
                    onPressed: () => context.go(
                      '/sessions/${session.id}/edit',
                    ),
                    icon: const Icon(Icons.edit),
                  ),
                ),
              ),
              actions: (session) => [
                IconButton(
                  tooltip: 'Открыть',
                  onPressed: () =>
                      context.go('/sessions/${session.id}'),
                  icon: const Icon(Icons.open_in_new),
                ),
                IconButton(
                  tooltip: 'Редактировать',
                  onPressed: () => context.go(
                    '/sessions/${session.id}/edit',
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