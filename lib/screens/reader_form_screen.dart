import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/library_card.dart';
import '../models/reader.dart';
import '../repositories/reader_repository.dart';
import '../widgets/entity_form.dart';
import '../widgets/form_field_definition.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;

  const ReaderFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() =>
      _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();

  bool _hasUnsavedChanges = false;
  bool _hasCard = true;
  bool _isLoading = false;
  bool _isSaving = false;

  String? _emailError;

  DateTime _issuedAt = DateTime.now();

  DateTime _expiresAt =
  DateTime.now().add(const Duration(days: 365));

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadReader();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadReader() async {
    setState(() {
      _isLoading = true;
    });

    final repository = context.read<ReaderRepository>();

    final reader = await repository.findById(widget.id!);

    if (!mounted) return;

    if (reader == null) {
      context.go('/readers');
      return;
    }

    _nameController.text = reader.fullName;
    _emailController.text = reader.email;
    _phoneController.text = reader.phone;

    if (reader.card != null) {
      _hasCard = true;
      _cardNumberController.text = reader.card!.number;
      _issuedAt = reader.card!.issuedAt;
      _expiresAt = reader.card!.expiresAt;
    } else {
      _hasCard = false;
    }

    setState(() {
      _isLoading = false;
      _hasUnsavedChanges = false;
    });
  }

  String? _validateEmail(String? value) {
    final requiredError = Validators.required(value);

    if (requiredError != null) {
      return requiredError;
    }

    final email = value!.trim();

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email)) {
      return 'Введите корректный email';
    }

    if (_emailError != null) {
      return _emailError;
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _emailError = null;
    });

    final repository = context.read<ReaderRepository>();

    try {
      LibraryCard? card;

      if (_hasCard) {
        card = LibraryCard(
          id: widget.id ?? 0,
          number: _cardNumberController.text.trim(),
          issuedAt: _issuedAt,
          expiresAt: _expiresAt,
        );
      }

      if (widget.isEditing) {
        final old = await repository.findById(widget.id!);

        if (old == null) {
          throw StateError('Читатель не найден');
        }

        await repository.update(
          old.copyWith(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            card: card,
            clearCard: !_hasCard,
          ),
        );
      } else {
        await repository.create(
          Reader(
            id: 0,
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            card: card,
          ),
        );
      }

      if (!mounted) return;

      // Сохранение успешно — предупреждение больше не нужно.
      setState(() {
        _hasUnsavedChanges = false;
      });

      context.go('/readers');
    } catch (e) {
      if (!mounted) return;

      final message = e.toString();

      if (message.contains('email уже существует')) {
        setState(() {
          _emailError =
          'Читатель с таким email уже существует';
        });

        _formKey.currentState!.validate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickDate(bool issued) async {
    final current = issued ? _issuedAt : _expiresAt;

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    _markChanged();

    setState(() {
      if (issued) {
        _issuedAt = picked;
      } else {
        _expiresAt = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      formKey: _formKey,
      title: widget.isEditing
          ? 'Редактирование читателя'
          : 'Новый читатель',
      isEditing: widget.isEditing,
      isLoading: _isLoading,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      onSubmit: _submit,
      onCancel: () => context.go('/readers'),
      fields: [
        FormFieldDefinition(
          label: 'ФИО',
          type: FormFieldType.text,
          controller: _nameController,
          validator: (value) =>
              Validators.maxLength(value, 100),
          onChanged: (_) => _markChanged(),
        ),

        FormFieldDefinition(
          label: 'Email',
          type: FormFieldType.text,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          validator: _validateEmail,
          onChanged: (_) {
            _markChanged();

            if (_emailError != null) {
              setState(() {
                _emailError = null;
              });
            }
          },
        ),

        FormFieldDefinition(
          label: 'Телефон',
          type: FormFieldType.text,
          controller: _phoneController,
          validator: (value) =>
              Validators.maxLength(value, 30),
          onChanged: (_) => _markChanged(),
        ),
      ],
      customFields: [
        SwitchListTile(
          title: const Text('Библиотечная карта'),
          value: _hasCard,
          onChanged: (value) {
            _markChanged();

            setState(() {
              _hasCard = value;
            });
          },
        ),

        if (_hasCard) ...[
          const SizedBox(height: 12),

          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Номер карты',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (!_hasCard) {
                return null;
              }

              return Validators.maxLength(value, 50);
            },
            onChanged: (_) => _markChanged(),
          ),

          const SizedBox(height: 12),

          ListTile(
            title: const Text('Выдана'),
            subtitle: Text(
              _issuedAt
                  .toLocal()
                  .toString()
                  .split(' ')
                  .first,
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(true),
          ),

          ListTile(
            title: const Text('Действует до'),
            subtitle: Text(
              _expiresAt
                  .toLocal()
                  .toString()
                  .split(' ')
                  .first,
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(false),
          ),
        ],
      ],
    );
  }
}