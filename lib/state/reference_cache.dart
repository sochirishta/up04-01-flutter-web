import 'package:flutter/foundation.dart';

import '../models/country.dart';
import '../models/country_query.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/hall.dart';
import '../models/hall_query.dart';
import '../models/person.dart';
import '../models/person_query.dart';

import '../repositories/country_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/hall_repository.dart';
import '../repositories/person_repository.dart';

class ReferenceCache extends ChangeNotifier {
  ReferenceCache(
      this._countryRepository,
      this._genreRepository,
      this._hallRepository,
      this._personRepository,
      );

  final CountryRepository _countryRepository;
  final GenreRepository _genreRepository;
  final HallRepository _hallRepository;
  final PersonRepository _personRepository;

  List<Country> _countries = [];
  List<Genre> _genres = [];
  List<Hall> _halls = [];
  List<Person> _persons = [];

  bool _loaded = false;
  bool _loading = false;

  List<Country> get countries => _countries;
  List<Genre> get genres => _genres;
  List<Hall> get halls => _halls;
  List<Person> get persons => _persons;

  bool get loaded => _loaded;
  bool get loading => _loading;

  Future<void> load() async {
    if (_loaded || _loading) {
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final countriesResult = await _countryRepository.find(
        const CountryQuery(size: 1000),
      );

      final genresResult = await _genreRepository.find(
        const GenreQuery(size: 1000),
      );

      final hallsResult = await _hallRepository.find(
        const HallQuery(size: 1000),
      );

      final personsResult = await _personRepository.find(
        const PersonQuery(size: 1000),
      );

      _countries = countriesResult.items;
      _genres = genresResult.items;
      _halls = hallsResult.items;
      _persons = personsResult.items;

      _loaded = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}