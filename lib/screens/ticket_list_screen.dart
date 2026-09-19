import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/ticket.dart';
import '../models/ticket_query.dart';
import '../state/entity_list_notifier.dart';
import '../state/ticket_list_notifier.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class TicketListScreen extends StatefulWidget {
  final TicketQuery initialQuery;

  const TicketListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _bookingController;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(
      text: widget.initialQuery.search,
    );

    _bookingController = TextEditingController(
      text: widget.initialQuery.bookingId ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final notifier = context.read<TicketListNotifier>();

      notifier.setQuery(widget.initialQuery);
      notifier.addListener(_updateUrl);
    });
  }

  @override
  void dispose() {
    final notifier = context.read<TicketListNotifier>();
    notifier.removeListener(_updateUrl);

    _searchController.dispose();
    _bookingController.dispose();

    super.dispose();
  }

  void _updateUrl() {
    if (!mounted) return;

    final notifier = context.read<TicketListNotifier>();
    final newLocation = notifier.urlFor(notifier.query);

    if (GoRouterState.of(context).uri.toString() != newLocation) {
      context.go(newLocation);
    }
  }

  Future<void> _applyFilters() async {
    final notifier = context.read<TicketListNotifier>();

    final bookingId = _bookingController.text.trim();

    await notifier.setBooking(
      bookingId.isEmpty ? null : bookingId,
    );
  }

  Future<void> _bulkDelete() async {
    final notifier = context.read<TicketListNotifier>();

    if (!notifier.hasSelection) return;

    final count = notifier.selected.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление билетов'),
        content: Text(
          'Удалить выбранные билеты ($count шт.)?',
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

    if (confirmed != true || !mounted) return;

    await notifier.deleteSelected();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Удалено: $count'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TicketListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Билеты'),
        actions: [
          IconButton(
            tooltip: 'Добавить билет',
            onPressed: () => context.go('/tickets/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(
        currentRoute: '/tickets',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Поиск',
                    hintText: 'Номер билета...',
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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _bookingController,
                        decoration: const InputDecoration(
                          labelText: 'Booking ID',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.filter_alt),
                      label: const Text('Применить'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _bookingController.clear();
                        notifier.resetFilters();
                      },
                      child: const Text('Сбросить'),
                    ),
                    FilterChip(
                      label: const Text('Удалённые'),
                      selected: notifier.query.includeDeleted,
                      onSelected: notifier.setIncludeDeleted,
                    ),
                  ],
                ),
                if (notifier.hasSelection)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Text(
                          'Выбрано: ${notifier.selected.length}',
                        ),
                        const SizedBox(width: 12),
                        FilledButton.tonalIcon(
                          onPressed: _bulkDelete,
                          icon: const Icon(Icons.delete),
                          label: const Text('Удалить выбранные'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (notifier.status) {
              LoadStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              LoadStatus.error => Center(
                child: Text(
                  notifier.errorMessage ?? 'Ошибка загрузки',
                ),
              ),
              _ => _buildContent(notifier),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TicketListNotifier notifier) {
    if (notifier.result.items.isEmpty) {
      return const Center(
        child: Text('Билетов нет'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: EntityTable<Ticket>(
            columns: [
              TableColumnSpec<Ticket>(
                label: 'Booking',
                sortField: 'booking',
                build: (ticket) => Text(ticket.bookingId),
              ),
              TableColumnSpec<Ticket>(
                label: 'Номер',
                sortField: 'number',
                build: (ticket) => Text(ticket.number),
              ),
              TableColumnSpec<Ticket>(
                label: 'Выдан',
                sortField: 'issuedAt',
                build: (ticket) =>
                    Text(_formatDateTime(ticket.issuedAt)),
              ),
            ],
            items: notifier.result.items,
            idOf: (ticket) => ticket.id,
            selected: notifier.selected,
            onToggleSelect: notifier.toggleSelection,
            sortField: notifier.query.sortField,
            sortAscending: notifier.query.sortAscending,
            onSort: notifier.sort,
            actions: (ticket) => [
              IconButton(
                tooltip: 'Открыть',
                onPressed: () {
                  context.go('/tickets/${ticket.id}');
                },
                icon: const Icon(Icons.open_in_new),
              ),
              IconButton(
                tooltip: 'Изменить',
                onPressed: () {
                  context.go('/tickets/${ticket.id}/edit');
                },
                icon: const Icon(Icons.edit),
              ),
            ],
            mobileItemBuilder: (ticket) {
              return Card(
                child: ListTile(
                  title: Text(ticket.number),
                  subtitle: Text(
                    'Booking: ${ticket.bookingId}\n'
                        'Выдан: ${_formatDateTime(ticket.issuedAt)}',
                  ),
                  isThreeLine: true,
                  onTap: () {
                    context.go('/tickets/${ticket.id}');
                  },
                  trailing: IconButton(
                    tooltip: 'Изменить',
                    onPressed: () {
                      context.go('/tickets/${ticket.id}/edit');
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ),
              );
            },
          ),
        ),
        PaginationControls(
          page: notifier.result.page,
          totalPages: notifier.result.totalPages,
          hasPrevious: notifier.result.hasPrevious,
          hasNext: notifier.result.hasNext,
          pageSize: notifier.result.size,
          onFirst: notifier.firstPage,
          onPrevious: notifier.previousPage,
          onNext: notifier.nextPage,
          onLast: notifier.lastPage,
          onPageSizeChanged: notifier.changePageSize,
        ),
      ],
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}