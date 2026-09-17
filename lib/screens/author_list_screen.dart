import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../state/author_list_notifier.dart';
import '../state/auth_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/app_navigation_drawer.dart';
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

  Future<void> _deleteSelected() async {
    final notifier = context.read<AuthorListNotifier>();

    if (!notifier.hasSelection) return;

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
    context.read<AuthorListNotifier>().removeListener(_updateUrl);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    final auth = context.watch<AuthNotifier>();

    final canManage = auth.has(Role.librarian);
    final canAdmin = auth.has(Role.admin);

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
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Добавить автора',
              onPressed: () {
                context.go('/authors/new');
              },
            ),
        ],
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/authors'),
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
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Найдено: ${result.total}'),
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
              if (canManage && notifier.hasSelection)
                FilledButton.icon(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete),
                  label: Text('Удалить (${notifier.selected.length})'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (result.items.isEmpty)
            const Center(child: Text('Авторы не найдены'))
          else
            EntityTable<Author>(
              items: result.items,
              selected: notifier.selected,
              idOf: (author) => author.id,
              onToggleSelect: notifier.toggleSelection,
              sortField: query.sortField,
              sortAscending: query.sortAscending,
              onSort: notifier.sort,

              mobileItemBuilder: (author) => AuthorCard(
                author: author,
                selected: notifier.selected.contains(author.id),
                onSelectionChanged: canManage
                    ? () {
                        notifier.toggleSelection(author.id);
                      }
                    : null,
                onOpen: () {
                  context.go('/authors/${author.id}');
                },
                onEdit: canManage
                    ? () {
                        context.go('/authors/${author.id}/edit');
                      }
                    : null,
                onRestore: canAdmin && author.isDeleted
                    ? () => notifier.restoreItem(author.id)
                    : null,
                onHardDelete: canAdmin && author.isDeleted
                    ? () => notifier.hardDeleteItem(author.id)
                    : null,
              ),

              columns: [
                TableColumnSpec<Author>(
                  label: 'ФИО',
                  sortField: 'fullName',
                  build: (author) => Text(author.fullName),
                ),
                TableColumnSpec<Author>(
                  label: 'Год рождения',
                  sortField: 'birthYear',
                  build: (author) => Text(author.birthYear.toString()),
                ),
                TableColumnSpec<Author>(
                  label: 'Страна',
                  sortField: 'country',
                  build: (author) => Text(author.country),
                ),
              ],

              actions: (author) => [
                IconButton(
                  tooltip: 'Открыть',
                  onPressed: () {
                    context.go('/authors/${author.id}');
                  },
                  icon: const Icon(Icons.open_in_new),
                ),
                if (canManage)
                  IconButton(
                    tooltip: 'Редактировать',
                    onPressed: () {
                      context.go('/authors/${author.id}/edit');
                    },
                    icon: const Icon(Icons.edit),
                  ),
                if (canAdmin && author.isDeleted)
                  IconButton(
                    tooltip: 'Восстановить',
                    onPressed: () {
                      notifier.restoreItem(author.id);
                    },
                    icon: const Icon(Icons.restore),
                  ),
                if (canAdmin && author.isDeleted)
                  IconButton(
                    tooltip: 'Удалить окончательно',
                    onPressed: () {
                      notifier.hardDeleteItem(author.id);
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
