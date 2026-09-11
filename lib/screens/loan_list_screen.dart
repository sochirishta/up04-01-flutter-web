import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:up04_01_flutter_web/widgets/app_navigation_drawer.dart';

import '../models/loan.dart';
import '../models/loan_query.dart';
import '../state/loan_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/loan_card.dart';

class LoanListScreen extends StatefulWidget {
  final LoanQuery initialQuery;

  const LoanListScreen({super.key, this.initialQuery = const LoanQuery()});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> {
  late final TextEditingController _searchController;

  LoanListNotifier get notifier => context.read<LoanListNotifier>();

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        final result = notifier.result;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Выдачи'),
            actions: [
              IconButton(
                tooltip: 'Добавить выдачу',
                onPressed: () => context.go('/loans/new'),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          drawer: const AppNavigationDrawer(currentRoute: '/loans'),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 400,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Поиск',
                          hintText: 'ID читателя или книги',
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
                    ),
                    DropdownButton<String?>(
                      value: notifier.query.status,
                      hint: const Text('Статус'),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Все'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'active',
                          child: Text('Активные'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'overdue',
                          child: Text('Просроченные'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'returned',
                          child: Text('Возвращённые'),
                        ),
                      ],
                      onChanged: notifier.setStatus,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Найдено: ${result.total}'),
                ),

                const SizedBox(height: 12),

                Expanded(child: _buildContent()),

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

  Widget _buildContent() {
    if (notifier.status == LoanLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.status == LoanLoadStatus.error) {
      return Center(child: Text(notifier.errorMessage ?? 'Ошибка загрузки'));
    }

    final loans = notifier.result.items;

    if (loans.isEmpty) {
      return const Center(child: Text('Выдачи не найдены'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return ListView.builder(
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];

              return LoanCard(
                loan: loan,
                selected: false,
                onSelectionChanged: () {},
                onOpen: () {
                  context.go('/loans/${loan.id}');
                },
                onEdit: () {
                  context.go('/loans/${loan.id}/edit');
                },
              );
            },
          );
        }

        return EntityTable<Loan>(
          columns: [
            TableColumnSpec<Loan>(
              label: 'ID',
              numeric: true,
              build: (loan) => Text('${loan.id}'),
            ),
            TableColumnSpec<Loan>(
              label: 'Читатель',
              numeric: true,
              build: (loan) => Text('${loan.readerId}'),
            ),
            TableColumnSpec<Loan>(
              label: 'Книга',
              numeric: true,
              build: (loan) => Text('${loan.bookId}'),
            ),
            TableColumnSpec<Loan>(
              label: 'Выдана',
              sortField: 'issuedAt',
              build: (loan) => Text(_date(loan.issuedAt)),
            ),
            TableColumnSpec<Loan>(
              label: 'Вернуть до',
              sortField: 'dueAt',
              build: (loan) => Text(_date(loan.dueAt)),
            ),
            TableColumnSpec<Loan>(
              label: 'Статус',
              sortField: 'status',
              build: (loan) => Text(loan.status),
            ),
          ],
          items: loans,
          idOf: (loan) => loan.id,
          selected: const {},
          sortField: notifier.query.sortField,
          sortAscending: notifier.query.sortAscending,
          onSort: notifier.sort,
          actions: (loan) => [
            IconButton(
              tooltip: 'Открыть',
              onPressed: () {
                context.go('/loans/${loan.id}');
              },
              icon: const Icon(Icons.open_in_new),
            ),
            IconButton(
              tooltip: 'Редактировать',
              onPressed: () {
                context.go('/loans/${loan.id}/edit');
              },
              icon: const Icon(Icons.edit),
            ),
          ],
        );
      },
    );
  }

  static String _date(DateTime value) {
    return value.toLocal().toString().split(' ').first;
  }
}
