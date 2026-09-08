import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/publisher.dart';
import '../repositories/publisher_repository.dart';
import '../widgets/entity_form.dart';
import '../widgets/form_field_definition.dart';

class PublisherFormScreen extends StatefulWidget {
  final int? id;

  const PublisherFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<PublisherFormScreen> createState() =>
      _PublisherFormScreenState();
}

class _PublisherFormScreenState
    extends State<PublisherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _hasUnsavedChanges = false;

  final _nameController =
  TextEditingController();

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  final _cityController =
  TextEditingController();

  final _foundedYearController =
  TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadPublisher();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _foundedYearController.dispose();
    super.dispose();
  }

  Future<void> _loadPublisher() async {
    setState(() {
      _isLoading = true;
    });

    final repository =
    context.read<PublisherRepository>();

    final publisher =
    await repository.findById(widget.id!);

    if (!mounted) return;

    if (publisher == null) {
      context.go('/publishers');
      return;
    }

    _nameController.text =
        publisher.name;

    _cityController.text =
        publisher.city;

    _foundedYearController.text =
        publisher.foundedYear.toString();

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
    context.read<PublisherRepository>();

    final name =
    _nameController.text.trim();

    final city =
    _cityController.text.trim();

    final foundedYear =
    int.parse(
      _foundedYearController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        final oldPublisher =
        await repository.findById(widget.id!);

        if (oldPublisher == null) {
          throw StateError(
            'Издательство не найдено',
          );
        }

        await repository.update(
          oldPublisher.copyWith(
            name: name,
            city: city,
            foundedYear: foundedYear,
          ),
        );
      } else {
        await repository.create(
          Publisher(
            id: 0,
            name: name,
            city: city,
            foundedYear: foundedYear,
          ),
        );
      }

      if (!mounted) return;

      context.go('/publishers');
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
          ? 'Редактирование издателя'
          : 'Новое издательство',
      isEditing: widget.isEditing,
      isLoading: _isLoading,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      onSubmit: _submit,
      onCancel: () =>
          context.go('/publishers'),
      fields: [
        FormFieldDefinition(
          label: 'Название',
          type: FormFieldType.text,
          controller: _nameController,
          validator: (value) =>
              Validators.maxLength(value, 100),
          onChanged: (_) => _markChanged(),
        ),

        FormFieldDefinition(
          label: 'Город',
          type: FormFieldType.text,
          controller: _cityController,
          validator: (value) =>
              Validators.maxLength(value, 100),
          onChanged: (_) => _markChanged(),
        ),

        FormFieldDefinition(
          label: 'Год основания',
          type: FormFieldType.number,
          controller: _foundedYearController,
          validator: (value) => Validators.integer(
            value,
            min: 0,
            max: DateTime.now().year,
          ),
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }
}