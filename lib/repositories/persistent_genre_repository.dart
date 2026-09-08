import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';

class PersistentGenreRepository implements GenreRepository {
  PersistentGenreRepository(this._prefs) {
    _loadInitialData();
  }

  final SharedPreferences _prefs;

  static const _storageKey = 'genres_v1';

  final List<Genre> _genres = [];

  void _loadInitialData() {
    final raw = _prefs.getStringList(_storageKey);

    if (raw == null) {
      _genres.addAll(_seedGenres);
      _save();
      return;
    }

    _genres.clear();

    for (final item in raw) {
      try {
        final json = jsonDecode(item);

        if (json is Map<String, dynamic>) {
          _genres.add(Genre.fromJson(json));
        }
      } catch (_) {
      }
    }
  }

  Future<void> _save() async {
    await _prefs.setStringList(
      _storageKey,
      _genres
          .map((genre) => jsonEncode(genre.toJson()))
          .toList(),
    );
  }

  @override
  Future<PageResult<Genre>> find(GenreQuery q) async {
    var rows = List<Genre>.from(_genres);

    if (!q.includeDeleted) {
      rows = rows.where((genre) => !genre.isDeleted).toList();
    }

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();

      rows = rows
          .where(
            (genre) =>
        genre.name.toLowerCase().contains(needle) ||
            genre.description.toLowerCase().contains(needle),
      )
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'description' => a.description
            .toLowerCase()
            .compareTo(b.description.toLowerCase()),
        _ => a.name
            .toLowerCase()
            .compareTo(b.name.toLowerCase()),
      };

      return q.sortAscending ? result : -result;
    });

    final total = rows.length;

    final from = (q.page - 1) * q.size;

    if (from >= total) {
      return PageResult(
        items: const [],
        page: q.page,
        size: q.size,
        total: total,
      );
    }

    final to = (from + q.size) > total
        ? total
        : from + q.size;

    final items = rows.sublist(from, to);

    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Genre?> findById(int id) async {
    for (final genre in _genres) {
      if (genre.id == id && !genre.isDeleted) {
        return genre;
      }
    }

    return null;
  }

  @override
  Future<Genre> create(Genre genre) async {
    final nextId = _genres.isEmpty
        ? 1
        : _genres
        .map((genre) => genre.id)
        .reduce((a, b) => a > b ? a : b) +
        1;

    final created = Genre(
      id: nextId,
      name: genre.name,
      description: genre.description,
    );

    _genres.add(created);

    await _save();

    return created;
  }

  @override
  Future<Genre> update(Genre genre) async {
    final index = _genres.indexWhere(
          (item) => item.id == genre.id,
    );

    if (index == -1) {
      throw Exception('Жанр не найден');
    }

    _genres[index] = genre;

    await _save();

    return genre;
  }

  @override
  Future<void> delete(int id) async {
    final index = _genres.indexWhere(
          (genre) => genre.id == id,
    );

    if (index == -1) {
      throw Exception('Жанр не найден');
    }

    _genres[index] = _genres[index].copyWith(
      deletedAt: DateTime.now(),
    );

    await _save();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var deleted = 0;

    for (final id in ids) {
      final index = _genres.indexWhere(
            (genre) => genre.id == id,
      );

      if (index == -1 || _genres[index].isDeleted) {
        continue;
      }

      _genres[index] = _genres[index].copyWith(
        deletedAt: DateTime.now(),
      );

      deleted++;
    }

    await _save();

    return deleted;
  }

  @override
  Future<void> restore(int id) async {
    final index = _genres.indexWhere(
          (genre) => genre.id == id,
    );

    if (index == -1) {
      throw Exception('Жанр не найден');
    }

    _genres[index] = _genres[index].copyWith(
      clearDeletedAt: true,
    );

    await _save();
  }

  @override
  Future<void> hardDelete(int id) async {
    _genres.removeWhere(
          (genre) => genre.id == id,
    );

    await _save();
  }
}

const _seedGenres = [
  Genre(
    id: 1,
    name: 'Фантастика',
    description: 'Произведения о вымышленных мирах и технологиях',
  ),
  Genre(
    id: 2,
    name: 'Роман',
    description: 'Крупная форма повествовательной прозы',
  ),
  Genre(
    id: 3,
    name: 'Детектив',
    description: 'Произведения о расследовании преступлений',
  ),
  Genre(
    id: 4,
    name: 'Фэнтези',
    description: 'Произведения с элементами магии и вымышленных миров',
  ),
  Genre(
    id: 5,
    name: 'Приключения',
    description: 'Произведения о путешествиях и приключениях',
  ),
  Genre(
    id: 6,
    name: 'Драма',
    description: 'Литературные произведения с конфликтным сюжетом',
  ),
];