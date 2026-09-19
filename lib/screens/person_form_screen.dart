import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/person.dart';
import '../repositories/person_repository.dart';
import '../state/reference_cache.dart';
import '../widgets/entity_form.dart';
import '../widgets/form_field_definition.dart';

class PersonFormScreen extends StatefulWidget {
  final String? id;

  const PersonFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _birthYearController = TextEditingController();

  String? _countryId;

  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferenceCache>().load();

      if (widget.isEditing) {
        _loadPerson();
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _loadPerson() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = context.read<PersonRepository>();
      final person = await repository.findById(widget.id!);

      if (!mounted) return;

      if (person == null) {
        context.go('/persons');
        return;
      }

      _fullNameController.text = person.fullName;
      _birthYearController.text = person.birthYear.toString();
      _countryId = person.countryId;

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
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

    if (_countryId == null || _countryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите страну'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final repository = context.read<PersonRepository>();

    final fullName = _fullNameController.text.trim();
    final birthYear =
    int.parse(_birthYearController.text.trim());

    try {
      if (widget.isEditing) {
        final oldPerson =
        await repository.findById(widget.id!);

        if (oldPerson == null) {
          throw StateError('Персона не найдена');
        }

        await repository.update(
          oldPerson.copyWith(
            fullName: fullName,
            birthYear: birthYear,
            countryId: _countryId!,
          ),
        );
      } else {
        await repository.create(
          Person(
            id: '',
            fullName: fullName,
            birthYear: birthYear,
            countryId: _countryId!,
          ),
        );
      }

      if (!mounted) return;

      context.go('/persons');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
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
    final references = context.watch<ReferenceCache>();

    return EntityForm(
      formKey: _formKey,
      title: widget.isEditing
          ? 'Редактирование персоны'
          : 'Новая персона',
      isEditing: widget.isEditing,
      isLoading: _isLoading || references.loading,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      onSubmit: _submit,
      onCancel: () => context.go('/persons'),
      fields: [
        FormFieldDefinition(
          label: 'ФИО',
          type: FormFieldType.text,
          controller: _fullNameController,
          validator: (value) =>
              Validators.maxLength(value, 150),
          onChanged: (_) => _markChanged(),
        ),
        FormFieldDefinition(
          label: 'Год рождения',
          type: FormFieldType.number,
          controller: _birthYearController,
          validator: (value) {
            final error = Validators.required(value);

            if (error != null) return error;

            final year = int.tryParse(value!.trim());

            if (year == null) {
              return 'Введите целое число';
            }

            if (year < 1800 || year > DateTime.now().year) {
              return 'Некорректный год рождения';
            }

            return null;
          },
          onChanged: (_) => _markChanged(),
        ),
        FormFieldDefinition(
          label: 'Страна',
          type: FormFieldType.dropdown,
          value: _countryId,
          items: [
            ...references.countries.map(
                  (country) => DropdownMenuItem<String>(
                value: country.id,
                child: Text(country.name),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _countryId = value;
              _hasUnsavedChanges = true;
            });
          },
        ),
      ],
    );
  }
}