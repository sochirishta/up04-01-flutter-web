import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/movie.dart';
import '../models/movie_query.dart';
import '../models/session.dart';
import '../repositories/movie_repository.dart';
import '../repositories/session_repository.dart';
import '../state/reference_cache.dart';

class SessionFormScreen extends StatefulWidget {
  final String? id;

  const SessionFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _movieId;
  String? _hallId;
  DateTime? _date;

  List<Movie> _movies = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final movieRepository = context.read<MovieRepository>();
      final sessionRepository = context.read<SessionRepository>();
      final referenceCache = context.read<ReferenceCache>();

      await referenceCache.load();

      final movieResult = await movieRepository.find(
        const MovieQuery(
          page: 1,
          size: 10000,
          includeDeleted: true,
        ),
      );

      if (!mounted) return;

      _movies = movieResult.items;

      if (widget.isEditing) {
        final session = await sessionRepository.findById(widget.id!);

        if (!mounted) return;

        if (session == null) {
          context.go('/sessions');
          return;
        }

        _movieId = session.movieId;
        _hallId = session.hallId;
        _date = session.date;
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _date ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _date = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_movieId == null || _movieId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите фильм'),
        ),
      );
      return;
    }

    if (_hallId == null || _hallId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите зал'),
        ),
      );
      return;
    }

    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Укажите дату и время сеанса'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = context.read<SessionRepository>();

      if (widget.isEditing) {
        final oldSession = await repository.findById(widget.id!);

        if (!mounted) return;

        if (oldSession == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сеанс не найден'),
            ),
          );
          return;
        }

        await repository.update(
          oldSession.copyWith(
            movieId: _movieId,
            hallId: _hallId,
            date: _date,
          ),
        );
      } else {
        await repository.create(
          CinemaSession(
            id: '',
            movieId: _movieId!,
            hallId: _hallId!,
            date: _date!,
          ),
        );
      }

      if (!mounted) return;

      context.go('/sessions');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
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

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Не выбрано';
    }

    final local = value.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final halls = context.watch<ReferenceCache>().halls;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Редактирование сеанса'
              : 'Новый сеанс',
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _movies.any(
                              (movie) => movie.id == _movieId,
                        )
                            ? _movieId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Фильм',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final movie in _movies)
                            DropdownMenuItem<String>(
                              value: movie.id,
                              child: Text(
                                '${movie.title} (${movie.year})',
                              ),
                            ),
                        ],
                        validator: Validators.required,
                        onChanged: (value) {
                          setState(() {
                            _movieId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: halls.any(
                              (hall) => hall.id == _hallId,
                        )
                            ? _hallId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Зал',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final hall in halls)
                            DropdownMenuItem<String>(
                              value: hall.id,
                              child: Text(
                                '${hall.name} '
                                    '(${hall.capacity} мест)',
                              ),
                            ),
                        ],
                        validator: Validators.required,
                        onChanged: (value) {
                          setState(() {
                            _hallId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      FormField<DateTime>(
                        validator: (_) {
                          if (_date == null) {
                            return 'Укажите дату и время';
                          }
                          return null;
                        },
                        builder: (field) {
                          return InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Дата и время',
                              border:
                              const OutlineInputBorder(),
                              errorText: field.errorText,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatDateTime(_date),
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () async {
                                    await _pickDateTime();
                                    field.didChange(_date);
                                  },
                                  icon: const Icon(
                                    Icons.calendar_month,
                                  ),
                                  label: const Text(
                                    'Выбрать',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () =>
                                context.go('/sessions'),
                            child: const Text('Отмена'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed:
                            _isSaving ? null : _submit,
                            child: _isSaving
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              widget.isEditing
                                  ? 'Сохранить'
                                  : 'Создать',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}