import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/ticket.dart';
import '../repositories/ticket_repository.dart';
import '../widgets/entity_form.dart';
import '../widgets/form_field_definition.dart';

class TicketFormScreen extends StatefulWidget {
  final String? id;

  const TicketFormScreen({
    super.key,
    this.id,
  });

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bookingController = TextEditingController();
  final _numberController = TextEditingController();

  DateTime _issuedAt = DateTime.now();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  bool get _isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _loadTicket();
    }
  }

  @override
  void dispose() {
    _bookingController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = context.read<TicketRepository>();
      final ticket = await repository.findById(widget.id!);

      if (!mounted) return;

      if (ticket == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Билет не найден'),
          ),
        );
        context.go('/tickets');
        return;
      }

      _bookingController.text = ticket.bookingId;
      _numberController.text = ticket.number;
      _issuedAt = ticket.issuedAt;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _selectIssuedAt() async {
    final initial = _issuedAt;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null || !mounted) return;

    setState(() {
      _issuedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ticket = Ticket(
      id: widget.id ?? '',
      bookingId: _bookingController.text.trim(),
      number: _numberController.text.trim(),
      issuedAt: _issuedAt,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = context.read<TicketRepository>();

      if (_isEditing) {
        await repository.update(ticket);
      } else {
        await repository.create(ticket);
      }

      if (!mounted) return;

      context.go(
        _isEditing
            ? '/tickets/${widget.id}'
            : '/tickets',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancel() {
    if (_isEditing) {
      context.go('/tickets/${widget.id}');
    } else {
      context.go('/tickets');
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      formKey: _formKey,
      title: _isEditing
          ? 'Редактирование билета'
          : 'Новый билет',
      isEditing: _isEditing,
      isLoading: _isLoading,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      onSubmit: _submit,
      onCancel: _cancel,
      fields: [
        FormFieldDefinition(
          label: 'Booking ID',
          type: FormFieldType.text,
          controller: _bookingController,
          validator: (value) => Validators.maxLength(value, 50),
          onChanged: (_) => _markChanged(),
        ),
        FormFieldDefinition(
          label: 'Номер билета',
          type: FormFieldType.text,
          controller: _numberController,
          validator: (value) => Validators.maxLength(value, 100),
          onChanged: (_) => _markChanged(),
        ),
      ],
      customFields: [
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Дата и время выдачи',
            border: OutlineInputBorder(),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatDateTime(_issuedAt),
                ),
              ),
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : _selectIssuedAt,
                child: const Text('Изменить'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}