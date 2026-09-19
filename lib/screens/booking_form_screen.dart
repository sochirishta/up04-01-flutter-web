import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../repositories/booking_repository.dart';
import '../core/api_exceptions.dart';

class BookingFormScreen extends StatefulWidget {
  final String? id;

  const BookingFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _sessionController = TextEditingController();
  final _userController = TextEditingController();
  final _rowController = TextEditingController();
  final _seatController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _userController.dispose();
    _rowController.dispose();
    _seatController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!widget.isEditing) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    final repository = context.read<BookingRepository>();

    try {
      final booking = await repository.findById(widget.id!);

      if (!mounted) return;

      if (booking == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бронирование не найдено'),
          ),
        );
        context.go('/bookings');
        return;
      }

      _sessionController.text = booking.sessionId;
      _userController.text = booking.userId;
      _rowController.text = booking.row.toString();
      _seatController.text = booking.seat.toString();

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

      context.go('/bookings');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sessionId = _sessionController.text.trim();
    final userId = _userController.text.trim();
    final row = int.tryParse(_rowController.text.trim());
    final seat = int.tryParse(_seatController.text.trim());

    if (row == null || seat == null) {
      return;
    }

    setState(() => _saving = true);

    final repository = context.read<BookingRepository>();

    try {
      if (widget.isEditing) {
        final old = await repository.findById(widget.id!);

        if (old == null) {
          throw StateError('Бронирование не найдено');
        }

        await repository.update(
          old.copyWith(
            sessionId: sessionId,
            userId: userId,
            row: row,
            seat: seat,
          ),
        );
      } else {
        await repository.create(
          Booking(
            id: '',
            sessionId: sessionId,
            userId: userId,
            row: row,
            seat: seat,
          ),
        );
      }

      if (!mounted) return;

      context.go('/bookings');
    } on ConflictException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing
                ? 'Редактирование бронирования'
                : 'Новое бронирование',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Редактирование бронирования'
              : 'Новое бронирование',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _sessionController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'ID сеанса',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите ID сеанса';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _userController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'ID пользователя',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите ID пользователя';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rowController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ряд',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');

                if (parsed == null) {
                  return 'Введите целое число';
                }

                if (parsed <= 0) {
                  return 'Ряд должен быть больше 0';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _seatController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Место',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');

                if (parsed == null) {
                  return 'Введите целое число';
                }

                if (parsed <= 0) {
                  return 'Место должно быть больше 0';
                }

                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => context.go('/bookings'),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    widget.isEditing ? 'Сохранить' : 'Создать',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}