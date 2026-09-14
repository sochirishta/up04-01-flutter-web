import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../state/auth_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../state/reader_list_notifier.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/reader_card.dart';

class ReaderListScreen extends StatefulWidget {
  final ReaderQuery initialQuery;

  const ReaderListScreen({super.key, this.initialQuery = const ReaderQuery()});

  @override
  State<ReaderListScreen> createState() => _ReaderListScreenState();
}

class _ReaderListScreenState extends State<ReaderListScreen> {
  late final TextEditingController _searchController;

  ReaderListNotifier get notifier => context.read<ReaderListNotifier>();

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(text: widget.initialQuery.search);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        notifier.setQuery(widget.initialQuery);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteSelected() async {
    if (!notifier.hasSelection) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить читателей?'),
        content: Text(
          'Вы действительно хотите удалить '
          '${notifier.selected.length} выбранных читателей?',
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

    if (confirmed != true) {
      return;
    }

    try {
      await notifier.deleteSelected();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    final canManage = auth.has(Role.librarian);
    final canAdmin = auth.has(Role.admin);

    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        final result = notifier.result;
        final query = notifier.query;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Читатели'),
            actions: [
              if (canManage)
                IconButton(
                  tooltip: 'Добавить читателя',
                  onPressed: () {
                    context.go('/readers/new');
                  },
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
          drawer: const AppNavigationDrawer(currentRoute: '/readers'),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Поиск',
                    hintText: 'ФИО, email или телефон',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              notifier.clearSearch();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    notifier.search(value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Найдено: ${result.total}'),
                    const Spacer(),
                    if (canManage) ...[
                      const Text('Удалённые'),
                      Switch(
                        value: query.includeDeleted,
                        onChanged: notifier.setIncludeDeleted,
                      ),
                    ],
                    if (canManage && notifier.hasSelection) ...[
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _deleteSelected,
                        icon: const Icon(Icons.delete),
                        label: Text('Удалить (${notifier.selected.length})'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildContent(
                    canManage: canManage,
                    canAdmin: canAdmin,
                  ),
                ),
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
          ),
        );
      },
    );
  }

  Widget _buildContent({required bool canManage, required bool canAdmin}) {
    if (notifier.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.status == LoadStatus.error) {
      return Center(child: Text(notifier.errorMessage ?? 'Ошибка загрузки'));
    }

    final readers = notifier.result.items;

    if (readers.isEmpty) {
      return const Center(child: Text('Читатели не найдены'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return ListView.builder(
            itemCount: readers.length,
            itemBuilder: (context, index) {
              final reader = readers[index];

              return ReaderCard(
                reader: reader,
                selected: notifier.selected.contains(reader.id),
                onSelectionChanged: canManage
                    ? () {
                        notifier.toggleSelection(reader.id);
                      }
                    : null,
                onOpen: () {
                  context.go('/readers/${reader.id}');
                },
                onEdit: canManage
                    ? () {
                        context.go('/readers/${reader.id}/edit');
                      }
                    : null,
                onRestore: canAdmin && reader.isDeleted
                    ? () {
                        notifier.restoreItem(reader.id);
                      }
                    : null,
                onHardDelete: canAdmin && reader.isDeleted
                    ? () {
                        notifier.hardDeleteItem(reader.id);
                      }
                    : null,
              );
            },
          );
        }

        return EntityTable<Reader>(
          columns: [
            TableColumnSpec<Reader>(
              label: 'ID',
              numeric: true,
              build: (reader) => Text('${reader.id}'),
            ),
            TableColumnSpec<Reader>(
              label: 'ФИО',
              sortField: 'fullName',
              build: (reader) => Text(reader.fullName),
            ),
            TableColumnSpec<Reader>(
              label: 'Email',
              sortField: 'email',
              build: (reader) => Text(reader.email),
            ),
            TableColumnSpec<Reader>(
              label: 'Телефон',
              build: (reader) => Text(reader.phone),
            ),
            TableColumnSpec<Reader>(
              label: 'Номер карты',
              build: (reader) => Text(reader.card?.number ?? '—'),
            ),
          ],
          items: readers,
          idOf: (reader) => reader.id,
          selected: notifier.selected,
          onToggleSelect: canManage ? notifier.toggleSelection : null,
          sortField: notifier.query.sortField,
          sortAscending: notifier.query.sortAscending,
          onSort: notifier.sort,
          actions: (reader) => [
            IconButton(
              tooltip: 'Открыть',
              onPressed: () {
                context.go('/readers/${reader.id}');
              },
              icon: const Icon(Icons.open_in_new),
            ),
            if (canManage)
              IconButton(
                tooltip: 'Редактировать',
                onPressed: () {
                  context.go('/readers/${reader.id}/edit');
                },
                icon: const Icon(Icons.edit),
              ),
            if (canAdmin && reader.isDeleted)
              IconButton(
                tooltip: 'Восстановить',
                onPressed: () {
                  notifier.restoreItem(reader.id);
                },
                icon: const Icon(Icons.restore),
              ),
            if (canAdmin && reader.isDeleted)
              IconButton(
                tooltip: 'Удалить окончательно',
                onPressed: () {
                  notifier.hardDeleteItem(reader.id);
                },
                icon: const Icon(Icons.delete_forever),
              ),
          ],
        );
      },
    );
  }
}
