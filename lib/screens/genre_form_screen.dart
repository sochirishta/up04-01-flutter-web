import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/genre.dart';
import '../repositories/genre_repository.dart';
import '../widgets/entity_form.dart';
import '../widgets/form_field_definition.dart';

class GenreFormScreen extends StatefulWidget {
  final int? id;

  const GenreFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _hasUnsavedChanges = false;

  final _nameController = TextEditingController();

  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadGenre();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGenre() async {
    setState(() {
      _isLoading = true;
    });

    final repository = context.read<GenreRepository>();

    final genre = await repository.findById(widget.id!);

    if (!mounted) return;

    if (genre == null) {
      context.go('/genres');
      return;
    }

    _nameController.text = genre.name;
    _descriptionController.text = genre.description;

    setState(() {
      _isLoading = false;
    });
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final repository = context.read<GenreRepository>();

    final name = _nameController.text.trim();

    final description = _descriptionController.text.trim();

    try {
      if (widget.isEditing) {
        final oldGenre = await repository.findById(widget.id!);

        if (oldGenre == null) {
          throw StateError('Жанр не найден');
        }

        await repository.update(
          oldGenre.copyWith(name: name, description: description),
        );
      } else {
        await repository.create(
          Genre(id: 0, name: name, description: description),
        );
      }

      if (!mounted) return;

      context.go('/genres');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      formKey: _formKey,
      title: widget.isEditing ? 'Редактирование жанра' : 'Новый жанр',
      isEditing: widget.isEditing,
      isLoading: _isLoading,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      onSubmit: _submit,
      onCancel: () => context.go('/genres'),
      fields: [
        FormFieldDefinition(
          label: 'Название',
          type: FormFieldType.text,
          controller: _nameController,
          validator: (value) => Validators.maxLength(value, 100),
          onChanged: (_) => _markChanged(),
        ),

        FormFieldDefinition(
          label: 'Описание',
          type: FormFieldType.text,
          controller: _descriptionController,
          maxLines: 5,
          validator: (value) => Validators.maxLength(value, 500),
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }
}
