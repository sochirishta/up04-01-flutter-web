import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import 'book_repository.dart';
import 'publisher_repository.dart';
import '../models/book_query.dart';

class PersistentPublisherRepository implements PublisherRepository {
  static const _key = 'publishers_v2';

  final SharedPreferences _prefs;
  final BookRepository _bookRepository;

  List<Publisher> _publishers = [];
  int _nextId = 1;

  PersistentPublisherRepository(
      this._prefs,
      this._bookRepository,
      ) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);

    if (raw == null) {
      _publishers = [...seedPublishers];
      _recalculateNextId();
      _persist();
      return;
    }

    try {
      final list = jsonDecode(raw) as List;

      _publishers = list
          .map(
            (e) => Publisher.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();

      _recalculateNextId();
    } catch (_) {
      _publishers = [...seedPublishers];
      _recalculateNextId();
      _persist();
    }
  }

  void _recalculateNextId() {
    _nextId = _publishers.isEmpty
        ? 1
        : _publishers
        .map((e) => e.id)
        .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(
        _publishers.map((e) => e.toJson()).toList(),
      ),
    );
  }

  @override
  Future<PageResult<Publisher>> find(PublisherQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _publishers
        .where((p) => q.includeDeleted || !p.isDeleted)
        .toList();

    final search = q.search.trim().toLowerCase();

    if (search.isNotEmpty) {
      rows = rows
          .where(
            (p) =>
        p.name.toLowerCase().contains(search) ||
            p.city.toLowerCase().contains(search),
      )
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        'foundedYear' => a.foundedYear.compareTo(b.foundedYear),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };

      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size).clamp(0, total);

    final items = from >= total
        ? <Publisher>[]
        : rows.sublist(from, to);

    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Publisher?> findById(int id) async {
    try {
      return _publishers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Publisher> create(Publisher publisher) async {
    final created = Publisher(
      id: _nextId++,
      name: publisher.name,
      city: publisher.city,
      foundedYear: publisher.foundedYear,
    );

    _publishers.add(created);
    await _persist();

    return created;
  }

  @override
  Future<Publisher> update(Publisher publisher) async {
    final index = _publishers.indexWhere(
          (p) => p.id == publisher.id,
    );

    if (index == -1) {
      throw StateError(
        'Издатель ${publisher.id} не найден',
      );
    }

    _publishers[index] = publisher;
    await _persist();

    return publisher;
  }

  Future<int> booksCount(int publisherId) async {
    final result = await _bookRepository.find(
      // Здесь intentionally ищем включая удалённые книги.
      // Связь существует независимо от soft-delete.
      const _PublisherBookQuery(),
    );

    return result.items
        .where((book) => book.publisherId == publisherId)
        .length;
  }

  @override
  Future<void> delete(int id) async {
    final count = await booksCount(id);

    if (count > 0) {
      throw StateError(
        'Нельзя удалить издателя: с ним связано книг: $count',
      );
    }

    final index = _publishers.indexWhere(
          (p) => p.id == id,
    );

    if (index == -1) {
      throw StateError('Издатель $id не найден');
    }

    _publishers[index] = _publishers[index].copyWith(
      deletedAt: DateTime.now(),
    );

    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;

    for (final id in ids) {
      try {
        await delete(id);
        count++;
      } catch (_) {
        // Связанный издатель пропускается.
      }
    }

    return count;
  }

  @override
  Future<void> restore(int id) async {
    final index = _publishers.indexWhere(
          (p) => p.id == id,
    );

    if (index == -1) {
      throw StateError('Издатель $id не найден');
    }

    _publishers[index] = _publishers[index].copyWith(
      clearDeletedAt: true,
    );

    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    final count = await booksCount(id);

    if (count > 0) {
      throw StateError(
        'Нельзя окончательно удалить издателя: с ним связано книг: $count',
      );
    }

    _publishers.removeWhere((p) => p.id == id);
    await _persist();
  }
}

class _PublisherBookQuery extends BookQuery {
  const _PublisherBookQuery()
      : super(
    includeDeleted: true,
    size: 1000000,
  );
}