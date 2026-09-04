import 'package:up04_01_flutter_web/models/author.dart';
import 'package:up04_01_flutter_web/models/author_query.dart';
import 'package:up04_01_flutter_web/models/page_result.dart';
import 'package:up04_01_flutter_web/repositories/author_repository.dart';

class InMemoryAuthorRepository implements AuthorRepository {
  final List<Author> _authors = [...seedAuthors];
  int _nextId = seedAuthors.length + 1;

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _authors
        .where((a) => q.includeDeleted || !a.isDeleted)
        .toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();

      rows = rows
          .where(
            (a) =>
        a.lastName.toLowerCase().contains(needle) ||
            a.country.toLowerCase().contains(needle),
      )
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'firstName' => a.firstName.toLowerCase().compareTo(
          b.firstName.toLowerCase(),
        ),
        'country' => a.country.toLowerCase().compareTo(
          b.country.toLowerCase(),
        ),
        _ => a.lastName.toLowerCase().compareTo(
          b.lastName.toLowerCase(),
        ),
      };

      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);

    final items = from >= total
        ? <Author>[]
        : rows.sublist(from, to);

    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Author?> findById(int id) async {
    try {
      return _authors.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Author> create(Author author) async {
    final created = Author(
      id: _nextId++,
      firstName: author.firstName,
      lastName: author.lastName,
      country: author.country,
      deletedAt: author.deletedAt,
    );

    _authors.add(created);

    return created;
  }

  @override
  Future<Author> update(Author author) async {
    final i = _authors.indexWhere((a) => a.id == author.id);

    if (i == -1) {
      throw StateError('Автор ${author.id} не найден');
    }

    _authors[i] = author;

    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);

    if (i == -1) {
      throw StateError('Автор $id не найден');
    }

    _authors[i] = _authors[i].copyWith(
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);

    if (i == -1) {
      throw StateError('Автор $id не найден');
    }

    _authors[i] = _authors[i].copyWith(
      clearDeletedAt: true,
    );
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;

    for (final id in ids) {
      final i = _authors.indexWhere(
            (a) => a.id == id && !a.isDeleted,
      );

      if (i != -1) {
        _authors[i] = _authors[i].copyWith(
          deletedAt: DateTime.now(),
        );
        count++;
      }
    }

    return count;
  }
}