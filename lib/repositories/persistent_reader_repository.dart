import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import 'reader_repository.dart';

class PersistentReaderRepository implements ReaderRepository {
  static const _key = 'readers_v1';
  static const _loanKey = 'loans_v1';

  final SharedPreferences _prefs;

  List<Reader> _readers = [];
  int _nextId = 1;

  PersistentReaderRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);

    if (raw == null) {
      _readers = [...seedReaders];
      _recalculateNextId();
      _persist();
      return;
    }

    try {
      final list = jsonDecode(raw) as List;

      _readers = list
          .map(
            (e) => Reader.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();

      _recalculateNextId();
    } catch (_) {
      _readers = [...seedReaders];
      _recalculateNextId();
      _persist();
    }
  }

  void _recalculateNextId() {
    _nextId = _readers.isEmpty
        ? 1
        : _readers
        .map((e) => e.id)
        .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(
        _readers.map((e) => e.toJson()).toList(),
      ),
    );
  }

  bool _hasLoans(int readerId) {
    final raw = _prefs.getString(_loanKey);

    if (raw == null) return false;

    try {
      final list = jsonDecode(raw) as List;

      return list.any((e) {
        final map = Map<String, dynamic>.from(e as Map);

        return map['readerId'] == readerId;
      });
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PageResult<Reader>> find(ReaderQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _readers
        .where((r) => q.includeDeleted || !r.isDeleted)
        .toList();

    final search = q.search.trim().toLowerCase();

    if (search.isNotEmpty) {
      rows = rows
          .where(
            (r) =>
        r.fullName.toLowerCase().contains(search) ||
            r.email.toLowerCase().contains(search) ||
            r.phone.toLowerCase().contains(search) ||
            (r.card?.number.toLowerCase().contains(search) ?? false),
      )
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'email' => a.email.toLowerCase().compareTo(
          b.email.toLowerCase(),
        ),
        _ => a.fullName.toLowerCase().compareTo(
          b.fullName.toLowerCase(),
        ),
      };

      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size).clamp(0, total);

    final items = from >= total
        ? <Reader>[]
        : rows.sublist(from, to);

    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Reader?> findById(int id) async {
    try {
      return _readers.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Reader> create(Reader reader) async {
    final emailExists = _readers.any(
          (r) =>
      !r.isDeleted &&
          r.email.toLowerCase() ==
              reader.email.trim().toLowerCase(),
    );

    if (emailExists) {
      throw StateError(
        'Читатель с таким email уже существует',
      );
    }

    final created = Reader(
      id: _nextId++,
      fullName: reader.fullName,
      email: reader.email,
      phone: reader.phone,
      card: reader.card,
    );

    _readers.add(created);
    await _persist();

    return created;
  }

  @override
  Future<Reader> update(Reader reader) async {
    final index = _readers.indexWhere(
          (r) => r.id == reader.id,
    );

    if (index == -1) {
      throw StateError(
        'Читатель ${reader.id} не найден',
      );
    }

    final emailExists = _readers.any(
          (r) =>
      r.id != reader.id &&
          !r.isDeleted &&
          r.email.toLowerCase() ==
              reader.email.trim().toLowerCase(),
    );

    if (emailExists) {
      throw StateError(
        'Читатель с таким email уже существует',
      );
    }

    _readers[index] = reader;
    await _persist();

    return reader;
  }

  @override
  Future<void> delete(int id) async {
    if (_hasLoans(id)) {
      throw StateError(
        'Нельзя удалить читателя: у него есть связанные выдачи',
      );
    }

    final index = _readers.indexWhere(
          (r) => r.id == id,
    );

    if (index == -1) {
      throw StateError('Читатель $id не найден');
    }

    _readers[index] = _readers[index].copyWith(
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
      } catch (_) {}
    }

    return count;
  }

  @override
  Future<void> restore(int id) async {
    final index = _readers.indexWhere(
          (r) => r.id == id,
    );

    if (index == -1) {
      throw StateError('Читатель $id не найден');
    }

    _readers[index] = _readers[index].copyWith(
      clearDeletedAt: true,
    );

    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    if (_hasLoans(id)) {
      throw StateError(
        'Нельзя окончательно удалить читателя: у него есть выдачи',
      );
    }

    _readers.removeWhere((r) => r.id == id);

    await _persist();
  }
}