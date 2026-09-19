import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';

import '../models/genre.dart';
import '../models/movie.dart';
import '../models/movie_query.dart';
import '../models/person.dart';

import '../repositories/movie_repository.dart';

import '../state/reference_cache.dart';

import '../widgets/entity_form.dart';
import '../widgets/form_field_definition.dart';

class MovieFormScreen extends StatefulWidget {
  final String? id;

  const MovieFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<MovieFormScreen> createState() => _MovieFormScreenState();
}

class _MovieFormScreenState extends State<MovieFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _durationController = TextEditingController();

  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  bool _isSaving = false;

  List<String> _genreIds = [];
  List<String> _personIds = [];

  List<Movie> _allMovies = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadData();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _durationController.dispose();

    super.dispose();
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final referenceCache = context.read<ReferenceCache>();
      final repository = context.read<MovieRepository>();

      await referenceCache.load();

      final result = await repository.find(
        const MovieQuery(
          page: 1,
          size: 10000,
          includeDeleted: true,
        ),
      );

      if (!mounted) return;

      _allMovies = result.items;

      if (widget.isEditing) {
        final movie = await repository.findById(widget.id!);

        if (!mounted) return;

        if (movie == null) {
          context.go('/movies');
          return;
        }

        _titleController.text = movie.title;
        _yearController.text = movie.year.toString();
        _durationController.text = movie.duration.toString();

        _genreIds = [...movie.genreIds];
        _personIds = [...movie.personIds];
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  List<Movie> _moviesForCascade({
    List<String> genreIds = const [],
    List<String> personIds = const [],
  }) {
    return _allMovies.where((movie) {
      for (final genreId in genreIds) {
        if (!movie.genreIds.contains(genreId)) {
          return false;
        }
      }

      for (final personId in personIds) {
        if (!movie.personIds.contains(personId)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<Genre> get _filteredGenres {
    final movies = _moviesForCascade(
      personIds: _personIds,
    );

    final availableIds = movies
        .expand((movie) => movie.genreIds)
        .toSet();

    availableIds.addAll(_genreIds);

    return context
        .read<ReferenceCache>()
        .genres
        .where((genre) => availableIds.contains(genre.id))
        .toList();
  }

  List<Person> get _filteredPersons {
    final movies = _moviesForCascade(
      genreIds: _genreIds,
    );

    final availableIds = movies
        .expand((movie) => movie.personIds)
        .toSet();

    availableIds.addAll(_personIds);

    return context
        .read<ReferenceCache>()
        .persons
        .where((person) => availableIds.contains(person.id))
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_genreIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы один жанр'),
        ),
      );
      return;
    }

    if (_personIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одну персону'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = context.read<MovieRepository>();

      final title = _titleController.text.trim();
      final year = int.parse(_yearController.text);
      final duration = int.parse(_durationController.text);

      if (widget.isEditing) {
        final oldMovie =
        await repository.findById(widget.id!);

        if (oldMovie == null || !mounted) {
          return;
        }

        await repository.update(
          oldMovie.copyWith(
            title: title,
            year: year,
            duration: duration,
            genreIds: _genreIds,
            personIds: _personIds,
          ),
        );
      } else {
        await repository.create(
          Movie(
            id: '',
            title: title,
            year: year,
            duration: duration,
            genreIds: _genreIds,
            personIds: _personIds,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _hasUnsavedChanges = false;
      });

      context.go('/movies');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildGenresField() {
    return FormField<List<String>>(
      initialValue: _genreIds,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Выберите хотя бы один жанр';
        }

        return null;
      },
      builder: (field) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Жанры',
              border: const OutlineInputBorder(),
              errorText: field.errorText,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filteredGenres.map((genre) {
                final selected =
                _genreIds.contains(genre.id);

                return FilterChip(
                  label: Text(genre.name),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        if (!_genreIds.contains(genre.id)) {
                          _genreIds.add(genre.id);
                        }
                      } else {
                        _genreIds.remove(genre.id);
                      }
                    });

                    _markChanged();
                    field.didChange([..._genreIds]);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonsField() {
    return FormField<List<String>>(
      initialValue: _personIds,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Выберите хотя бы одну персону';
        }

        return null;
      },
      builder: (field) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Персоны',
              border: const OutlineInputBorder(),
              errorText: field.errorText,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filteredPersons.map((person) {
                final selected =
                _personIds.contains(person.id);

                return FilterChip(
                  label: Text(person.fullName),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        if (!_personIds.contains(person.id)) {
                          _personIds.add(person.id);
                        }
                      } else {
                        _personIds.remove(person.id);
                      }
                    });

                    _markChanged();
                    field.didChange([..._personIds]);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      formKey: _formKey,
      title: widget.isEditing
          ? 'Редактирование фильма'
          : 'Новый фильм',
      isEditing: widget.isEditing,
      isLoading: _isLoading,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      onSubmit: _submit,
      onCancel: () => context.go('/movies'),
      fields: [
        FormFieldDefinition(
          label: 'Название',
          type: FormFieldType.text,
          controller: _titleController,
          validator: (value) =>
              Validators.maxLength(value, 200),
          onChanged: (_) => _markChanged(),
        ),
        FormFieldDefinition(
          label: 'Год',
          type: FormFieldType.number,
          controller: _yearController,
          validator: (value) => Validators.integer(
            value,
            min: 1888,
            max: DateTime.now().year,
          ),
          onChanged: (_) => _markChanged(),
        ),
        FormFieldDefinition(
          label: 'Длительность, минут',
          type: FormFieldType.number,
          controller: _durationController,
          validator: Validators.positiveInteger,
          onChanged: (_) => _markChanged(),
        ),
      ],
      customFields: [
        _buildGenresField(),
        _buildPersonsField(),
      ],
    );
  }
}