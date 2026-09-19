import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/country.dart';
import '../repositories/country_repository.dart';
import '../widgets/entity_form.dart';
import '../widgets/form_field_definition.dart';

class CountryFormScreen extends StatefulWidget {
  final String? id;

  const CountryFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<CountryFormScreen> createState() => _CountryFormScreenState();
}

class _CountryFormScreenState extends State<CountryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadCountry();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCountry() async {
    setState(() => _isLoading = true);

    try {
      final repository = context.read<CountryRepository>();
      final country = await repository.findById(widget.id!);

      if (!mounted) return;

      if (country == null) {
        context.go('/countries');
        return;
      }

      _nameController.text = country.name;

      setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final repository = context.read<CountryRepository>();
    final name = _nameController.text.trim();

    try {
      if (widget.isEditing) {
        final oldCountry =
        await repository.findById(widget.id!);

        if (oldCountry == null) {
          throw StateError('Страна не найдена');
        }

        await repository.update(
          oldCountry.copyWith(name: name),
        );
      } else {
        await repository.create(
          Country(
            id: '',
            name: name,
          ),
        );
      }

      if (!mounted) return;

      context.go('/countries');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      formKey: _formKey,
      title: widget.isEditing
          ? 'Редактирование страны'
          : 'Новая страна',
      isEditing: widget.isEditing,
      isLoading: _isLoading,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      onSubmit: _submit,
      onCancel: () => context.go('/countries'),
      fields: [
        FormFieldDefinition(
          label: 'Название',
          type: FormFieldType.text,
          controller: _nameController,
          validator: (value) =>
              Validators.maxLength(value, 100),
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }
}