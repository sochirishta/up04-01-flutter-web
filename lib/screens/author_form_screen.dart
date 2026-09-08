import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../widgets/entity_form.dart';
import '../widgets/form_field_definition.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;

  const AuthorFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() =>
      _AuthorFormScreenState();
}

class _AuthorFormScreenState
    extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _hasUnsavedChanges = false;

  final _fullNameController =
  TextEditingController();

  final _birthYearController =
  TextEditingController();

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  final _countryController =
  TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadAuthor();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthYearController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthor() async {
    setState(() {
      _isLoading = true;
    });

    final repository =
    context.read<AuthorRepository>();

    final author =
    await repository.findById(widget.id!);

    if (!mounted) return;

    if (author == null) {
      context.go('/authors');
      return;
    }

    _fullNameController.text =
        author.fullName;

    _birthYearController.text =
        author.birthYear.toString();

    _countryController.text =
        author.country;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final repository =
    context.read<AuthorRepository>();

    final fullName =
    _fullNameController.text.trim();

    final birthYear =
    int.parse(_birthYearController.text.trim());

    final country =
    _countryController.text.trim();

    try {
      if (widget.isEditing) {
        final oldAuthor =
        await repository.findById(widget.id!);

        if (oldAuthor == null) {
          throw StateError('Автор не найден');
        }

        await repository.update(
          oldAuthor.copyWith(
            fullName: fullName,
            birthYear: birthYear,
            country: country,
          ),
        );
      } else {
        await repository.create(
          Author(
            id: 0,
            fullName: fullName,
            birthYear: birthYear,
            country: country,
          ),
        );
      }

      if (!mounted) return;

      context.go('/authors');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
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

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      formKey: _formKey,
      title: widget.isEditing
          ? 'Редактирование автора'
          : 'Новый автор',
      isEditing: widget.isEditing,
      isLoading: _isLoading,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      onSubmit: _submit,
      onCancel: () => context.go('/authors'),
      fields: [
        FormFieldDefinition(
          label: 'ФИО',
          type: FormFieldType.text,
          controller: _fullNameController,
          validator: (value) =>
              Validators.maxLength(value, 100),
          onChanged: (_) => _markChanged(),
        ),

        FormFieldDefinition(
          label: 'Год рождения',
          type: FormFieldType.number,
          controller: _birthYearController,
          validator: (value) => Validators.integer(
            value,
            min: 0,
            max: DateTime.now().year,
          ),
          onChanged: (_) => _markChanged(),
        ),

        FormFieldDefinition(
          label: 'Страна',
          type: FormFieldType.text,
          controller: _countryController,
          validator: (value) =>
              Validators.maxLength(value, 100),
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }
}