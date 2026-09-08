import 'package:flutter/material.dart';

import 'form_field_definition.dart';

class EntityForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String title;
  final bool isEditing;
  final bool isLoading;
  final bool isSaving;
  final bool hasUnsavedChanges;

  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  final List<FormFieldDefinition> fields;
  final List<Widget> customFields;

  const EntityForm({
    super.key,
    required this.formKey,
    required this.title,
    required this.isEditing,
    required this.isLoading,
    required this.isSaving,
    required this.hasUnsavedChanges,
    required this.onSubmit,
    required this.onCancel,
    required this.fields,
    this.customFields = const [],
  });

  Future<bool> _confirmLeave(BuildContext context) async {
    if (!hasUnsavedChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text(
          'У вас есть несохранённые изменения. '
              'Вы действительно хотите уйти?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    return result == true;
  }

  Widget _buildField(FormFieldDefinition field) {
    switch (field.type) {
      case FormFieldType.text:
      case FormFieldType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: field.controller,
            validator: field.validator,
            enabled: field.enabled,
            maxLines: field.maxLines,
            keyboardType: field.keyboardType ??
                (field.type == FormFieldType.number
                    ? TextInputType.number
                    : TextInputType.text),
            onChanged: field.onChanged,
            decoration: InputDecoration(
              labelText: field.label,
              errorText: field.errorText,
              border: const OutlineInputBorder(),
            ),
          ),
        );

      case FormFieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<dynamic>(
            initialValue: field.value,
            items: field.items,
            onChanged: field.enabled ? field.onChanged : null,
            validator: field.validator == null
                ? null
                : (value) => field.validator!(value?.toString()),
            decoration: InputDecoration(
              labelText: field.label,
              errorText: field.errorText,
              border: const OutlineInputBorder(),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !hasUnsavedChanges) {
          return;
        }

        final shouldLeave = await _confirmLeave(context);

        if (shouldLeave && context.mounted) {
          onCancel();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...fields.map(_buildField),
              ...customFields,
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                      if (await _confirmLeave(context)) {
                        onCancel();
                      }
                    },
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: isSaving ? null : onSubmit,
                    child: isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      isEditing ? 'Сохранить' : 'Создать',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}