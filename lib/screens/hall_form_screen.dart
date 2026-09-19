import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/hall.dart';
import '../repositories/hall_repository.dart';
import '../widgets/entity_form.dart';
import '../widgets/form_field_definition.dart';

class HallFormScreen extends StatefulWidget {
  final String? id;

  const HallFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<HallFormScreen> createState() => _HallFormScreenState();
}

class _HallFormScreenState extends State<HallFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadHall();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _loadHall() async {
    setState(() => _isLoading = true);

    try {
      final repository = context.read<HallRepository>();
      final hall = await repository.findById(widget.id!);

      if (!mounted) return;

      if (hall == null) {
        context.go('/halls');
        return;
      }

      _nameController.text = hall.name;
      _capacityController.text = hall.capacity.toString();

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

    final repository = context.read<HallRepository>();

    final name = _nameController.text.trim();
    final capacity = int.parse(
      _capacityController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        final oldHall =
        await repository.findById(widget.id!);

        if (oldHall == null) {
          throw StateError('Зал не найден');
        }

        await repository.update(
          oldHall.copyWith(
            name: name,
            capacity: capacity,
          ),
        );
      } else {
        await repository.create(
          Hall(
            id: '',
            name: name,
            capacity: capacity,
          ),
        );
      }

      if (!mounted) return;

      context.go('/halls');
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
          ? 'Редактирование зала'
          : 'Новый зал',
      isEditing: widget.isEditing,
      isLoading: _isLoading,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      onSubmit: _submit,
      onCancel: () => context.go('/halls'),
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
          label: 'Вместимость',
          type: FormFieldType.number,
          controller: _capacityController,
          validator: (value) {
            final error = Validators.required(value);
            if (error != null) return error;

            final capacity =
            int.tryParse(value!.trim());

            if (capacity == null) {
              return 'Введите целое число';
            }

            if (capacity <= 0) {
              return 'Вместимость должна быть больше нуля';
            }

            return null;
          },
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }
}