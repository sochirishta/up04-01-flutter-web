import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int page;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
  final int pageSize;

  final VoidCallback onFirst;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLast;
  final ValueChanged<int> onPageSizeChanged;

  const PaginationControls({
    super.key,
    required this.page,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
    required this.pageSize,
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onLast,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          IconButton(
            tooltip: 'Первая',
            onPressed: hasPrevious ? onFirst : null,
            icon: const Icon(Icons.first_page),
          ),
          IconButton(
            tooltip: 'Предыдущая',
            onPressed: hasPrevious ? onPrevious : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$page / $totalPages'),
          IconButton(
            tooltip: 'Следующая',
            onPressed: hasNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'Последняя',
            onPressed: hasNext ? onLast : null,
            icon: const Icon(Icons.last_page),
          ),
          DropdownButton<int>(
            value: pageSize,
            items: const [
              DropdownMenuItem(
                value: 10,
                child: Text('10'),
              ),
              DropdownMenuItem(
                value: 25,
                child: Text('25'),
              ),
              DropdownMenuItem(
                value: 50,
                child: Text('50'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                onPageSizeChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}