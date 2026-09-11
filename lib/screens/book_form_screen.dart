import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';

import '../models/author.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/genre.dart';
import '../models/publisher.dart';

import '../repositories/book_repository.dart';

import '../state/reference_cache.dart';

import '../widgets/entity_form.dart';
import '../widgets/form_field_definition.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;

  const BookFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _copiesTotalController = TextEditingController();
  final _copiesAvailableController = TextEditingController();

  String? _isbnError;

  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  bool _isSaving = false;

  int? _publisherId;

  List<int> _authorIds = [];
  List<int> _genreIds = [];

  List<Book> _allBooks = [];

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
    _isbnController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _copiesTotalController.dispose();
    _copiesAvailableController.dispose();

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
      final bookRepository = context.read<BookRepository>();

      await referenceCache.load();

      final booksResult = await bookRepository.find(
        const BookQuery(page: 1, size: 10000, includeDeleted: true),
      );

      if (!mounted) return;

      _allBooks = booksResult.items;

      if (widget.isEditing) {
        final book = await bookRepository.findById(widget.id!);

        if (!mounted) return;

        if (book == null) {
          context.go('/books');
          return;
        }

        _titleController.text = book.title;
        _isbnController.text = book.isbn;
        _yearController.text = book.year.toString();
        _pagesController.text = book.pages.toString();
        _copiesTotalController.text = book.copiesTotal.toString();
        _copiesAvailableController.text = book.copiesAvailable.toString();

        _publisherId = book.publisherId;
        _authorIds = [...book.authorIds];
        _genreIds = [...book.genreIds];
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  List<Book> _booksForCascade({
    int? publisherId,
    List<int> authorIds = const [],
    List<int> genreIds = const [],
  }) {
    return _allBooks.where((book) {
      if (publisherId != null && book.publisherId != publisherId) {
        return false;
      }

      for (final authorId in authorIds) {
        if (!book.authorIds.contains(authorId)) {
          return false;
        }
      }

      for (final genreId in genreIds) {
        if (!book.genreIds.contains(genreId)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<Author> get _filteredAuthors {
    final books = _booksForCascade(
      publisherId: _publisherId,
      genreIds: _genreIds,
    );

    final availableIds = books.expand((book) => book.authorIds).toSet();

    availableIds.addAll(_authorIds);

    final authors = context.read<ReferenceCache>().authors;

    return authors.where((author) => availableIds.contains(author.id)).toList();
  }

  List<Genre> get _filteredGenres {
    final books = _booksForCascade(
      publisherId: _publisherId,
      authorIds: _authorIds,
    );

    final availableIds = books.expand((book) => book.genreIds).toSet();

    availableIds.addAll(_genreIds);

    final genres = context.read<ReferenceCache>().genres;

    return genres.where((genre) => availableIds.contains(genre.id)).toList();
  }

  List<Publisher> get _filteredPublishers {
    final books = _booksForCascade(authorIds: _authorIds, genreIds: _genreIds);

    final availableIds = books.map((book) => book.publisherId).toSet();

    if (_publisherId != null) {
      availableIds.add(_publisherId!);
    }

    final publishers = context.read<ReferenceCache>().publishers;

    return publishers
        .where((publisher) => availableIds.contains(publisher.id))
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _isbnError = null;
    });

    try {
      final repository = context.read<BookRepository>();

      final isbn = _isbnController.text.trim();

      final title = _titleController.text.trim();
      final year = int.parse(_yearController.text);
      final pages = int.parse(_pagesController.text);
      final copiesTotal = int.parse(_copiesTotalController.text);
      final copiesAvailable = int.parse(_copiesAvailableController.text);

      final publisherId = _publisherId;

      if (publisherId == null) {
        if (!mounted) return;

        setState(() {
          _isSaving = false;
        });

        return;
      }

      if (widget.isEditing) {
        final oldBook = await repository.findById(widget.id!);

        if (oldBook == null || !mounted) {
          return;
        }

        await repository.update(
          oldBook.copyWith(
            title: title,
            isbn: isbn,
            year: year,
            pages: pages,
            publisherId: publisherId,
            authorIds: _authorIds,
            genreIds: _genreIds,
            copiesTotal: copiesTotal,
            copiesAvailable: copiesAvailable,
          ),
        );
      } else {
        await repository.create(
          Book(
            id: 0,
            title: title,
            isbn: isbn,
            year: year,
            pages: pages,
            publisherId: publisherId,
            authorIds: _authorIds,
            genreIds: _genreIds,
            copiesTotal: copiesTotal,
            copiesAvailable: copiesAvailable,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _hasUnsavedChanges = false;
      });

      context.go('/books');
    } on ValidationException catch (e) {
      setState(() {
        _isbnError = e.errors['isbn'] ?? e.message;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildAuthorsField() {
    return FormField<List<int>>(
      initialValue: _authorIds,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Выберите хотя бы одного автора';
        }

        return null;
      },
      builder: (field) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Авторы',
              border: const OutlineInputBorder(),
              errorText: field.errorText,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filteredAuthors.map((author) {
                final selected = _authorIds.contains(author.id);

                return FilterChip(
                  label: Text(author.fullName),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        if (!_authorIds.contains(author.id)) {
                          _authorIds.add(author.id);
                        }
                      } else {
                        _authorIds.remove(author.id);
                      }
                    });

                    _markChanged();
                    field.didChange([..._authorIds]);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenresField() {
    return FormField<List<int>>(
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
                final selected = _genreIds.contains(genre.id);

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

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      formKey: _formKey,
      title: widget.isEditing ? 'Редактирование книги' : 'Новая книга',
      isEditing: widget.isEditing,
      isLoading: _isLoading,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      onSubmit: _submit,
      onCancel: () => context.go('/books'),
      fields: [
        FormFieldDefinition(
          label: 'Название',
          type: FormFieldType.text,
          controller: _titleController,
          validator: (value) => Validators.maxLength(value, 200),
          onChanged: (_) => _markChanged(),
        ),
        FormFieldDefinition(
          label: 'ISBN',
          type: FormFieldType.text,
          controller: _isbnController,
          errorText: _isbnError,
          validator: (value) => Validators.maxLength(value, 20),
          onChanged: (_) {
            _markChanged();

            if (_isbnError != null) {
              setState(() {
                _isbnError = null;
              });
            }
          },
        ),
        FormFieldDefinition(
          label: 'Год',
          type: FormFieldType.number,
          controller: _yearController,
          validator: (value) =>
              Validators.integer(value, min: 0, max: DateTime.now().year),
          onChanged: (_) => _markChanged(),
        ),
        FormFieldDefinition(
          label: 'Количество страниц',
          type: FormFieldType.number,
          controller: _pagesController,
          validator: Validators.positiveInteger,
          onChanged: (_) => _markChanged(),
        ),
        FormFieldDefinition(
          label: 'Всего экземпляров',
          type: FormFieldType.number,
          controller: _copiesTotalController,
          validator: Validators.positiveInteger,
          onChanged: (_) => _markChanged(),
        ),
        FormFieldDefinition(
          label: 'Доступно экземпляров',
          type: FormFieldType.number,
          controller: _copiesAvailableController,
          validator: (value) =>
              Validators.copiesAvailable(value, _copiesTotalController.text),
          onChanged: (_) => _markChanged(),
        ),
        FormFieldDefinition(
          label: 'Издательство',
          type: FormFieldType.dropdown,
          value: _publisherId,
          items: _filteredPublishers.map((publisher) {
            return DropdownMenuItem<int>(
              value: publisher.id,
              child: Text(publisher.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          validator: (value) {
            if (value == null) {
              return 'Выберите издательство';
            }

            return null;
          },
          onChanged: (value) {
            _markChanged();

            setState(() {
              _publisherId = value as int?;
            });
          },
        ),
      ],
      customFields: [_buildAuthorsField(), _buildGenresField()],
    );
  }
}
