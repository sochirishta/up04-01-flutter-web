import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';

import '../repositories/author_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';

class ReferenceCache extends ChangeNotifier {
  ReferenceCache(
    this._authorRepository,
    this._genreRepository,
    this._publisherRepository,
  );

  final AuthorRepository _authorRepository;
  final GenreRepository _genreRepository;
  final PublisherRepository _publisherRepository;

  List<Author> _authors = [];
  List<Genre> _genres = [];
  List<Publisher> _publishers = [];

  bool _loaded = false;
  bool _loading = false;

  List<Author> get authors => _authors;
  List<Genre> get genres => _genres;
  List<Publisher> get publishers => _publishers;

  bool get loaded => _loaded;
  bool get loading => _loading;

  Future<void> load() async {
    if (_loaded || _loading) {
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final authorsResult = await _authorRepository.find(
        const AuthorQuery(size: 1000),
      );

      final genresResult = await _genreRepository.find(
        const GenreQuery(size: 1000),
      );

      final publishersResult = await _publisherRepository.find(
        const PublisherQuery(size: 1000),
      );

      _authors = authorsResult.items;
      _genres = genresResult.items;
      _publishers = publishersResult.items;

      _loaded = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
