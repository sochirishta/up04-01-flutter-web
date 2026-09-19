import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../state/auth_notifier.dart';
import '../state/booking_list_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({
    super.key,
  });

  @override
  State<BookingListScreen> createState() =>
      _BookingListScreenState();
}

class _BookingListScreenState
    extends State<BookingListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<BookingListNotifier>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<BookingListNotifier>();

    if (notifier.selected.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить выбранные бронирования?'),
        content: Text(
          'Будет удалено записей: ${notifier.selected.length}.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await notifier.deleteSelected();
  }

  String _statusText(LoadStatus status) {
    switch (status) {
      case LoadStatus.idle:
        return '';
      case LoadStatus.loading:
        return 'Загрузка...';
      case LoadStatus.success:
        return '';
      case LoadStatus.error:
        return 'Ошибка загрузки';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final notifier = context.watch<BookingListNotifier>();

    final canManage = auth.hasRole(Role.manager);
    final canAdmin = auth.isExactly(Role.admin);

    final result = notifier.result;
    final items = result.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирования'),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Новое бронирование',
              onPressed: () {
                context.go('/bookings/new');
              },
              icon: const Icon(Icons.add),
            ),
          if (canManage && notifier.selected.isNotEmpty)
            IconButton(
              tooltip: 'Удалить выбранные',
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment:
              WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Поиск',
                      hintText: 'ID, сеанс, пользователь...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                      _searchController.text.isEmpty
                          ? null
                          : IconButton(
                        tooltip: 'Очистить',
                        onPressed: () {
                          _searchController.clear();
                          notifier.clearSearch();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                    onChanged: (value) {
                      notifier.search(value);
                      setState(() {});
                    },
                  ),
                ),
                FilterChip(
                  label: const Text('Удалённые'),
                  selected: notifier.query.includeDeleted,
                  onSelected: canAdmin
                      ? notifier.setIncludeDeleted
                      : null,
                ),
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    notifier.resetFilters();
                    setState(() {});
                  },
                  child: const Text('Сбросить'),
                ),
              ],
            ),
          ),
          if (notifier.status == LoadStatus.error)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                notifier.errorMessage ??
                    _statusText(notifier.status),
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          Expanded(
            child: notifier.status == LoadStatus.loading &&
                items.isEmpty
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : items.isEmpty
                ? const Center(
              child: Text(
                'Бронирований не найдено',
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: EntityTable<Booking>(
                items: items,
                idOf: (booking) => booking.id,
                selected: notifier.selected,
                onToggleSelect:
                notifier.toggleSelection,
                sortField:
                notifier.query.sortField,
                sortAscending:
                notifier.query.sortAscending,
                onSort: notifier.sort,
                columns: [
                  TableColumnSpec<Booking>(
                    label: 'ID',
                    sortField: 'id',
                    build: (booking) =>
                        Text(booking.id),
                  ),
                  TableColumnSpec<Booking>(
                    label: 'Сеанс',
                    sortField: 'session',
                    build: (booking) =>
                        Text(booking.sessionId),
                  ),
                  TableColumnSpec<Booking>(
                    label: 'Пользователь',
                    sortField: 'user',
                    build: (booking) =>
                        Text(booking.userId),
                  ),
                  TableColumnSpec<Booking>(
                    label: 'Ряд',
                    sortField: 'row',
                    numeric: true,
                    build: (booking) =>
                        Text('${booking.row}'),
                  ),
                  TableColumnSpec<Booking>(
                    label: 'Место',
                    sortField: 'seat',
                    numeric: true,
                    build: (booking) =>
                        Text('${booking.seat}'),
                  ),
                ],
                actions: (booking) => [
                  IconButton(
                    tooltip: 'Открыть',
                    onPressed: () {
                      context.go(
                        '/bookings/${booking.id}',
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                  ),
                  if (canManage)
                    IconButton(
                      tooltip: 'Редактировать',
                      onPressed: () {
                        context.go(
                          '/bookings/'
                              '${booking.id}/edit',
                        );
                      },
                      icon: const Icon(Icons.edit),
                    ),
                ],
                mobileItemBuilder: (booking) {
                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: ListTile(
                      title: Text(
                        'Бронирование ${booking.id}',
                      ),
                      subtitle: Text(
                        'Сеанс: ${booking.sessionId}\n'
                            'Пользователь: ${booking.userId}\n'
                            'Ряд: ${booking.row}, '
                            'место: ${booking.seat}',
                      ),
                      isThreeLine: true,
                      leading: Checkbox(
                        value: notifier.selected
                            .contains(booking.id),
                        onChanged: (_) {
                          notifier.toggleSelection(
                            booking.id,
                          );
                        },
                      ),
                      trailing: IconButton(
                        tooltip: 'Открыть',
                        onPressed: () {
                          context.go(
                            '/bookings/${booking.id}',
                          );
                        },
                        icon: const Icon(
                          Icons.chevron_right,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: PaginationControls(
              page: result.page,
              totalPages: result.totalPages,
              hasPrevious: result.hasPrevious,
              hasNext: result.hasNext,
              pageSize: result.size,
              onFirst: notifier.firstPage,
              onPrevious: notifier.previousPage,
              onNext: notifier.nextPage,
              onLast: notifier.lastPage,
              onPageSizeChanged:
              notifier.changePageSize,
            ),
          ),
        ],
      ),
    );
  }
}