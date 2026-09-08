import 'package:flutter/material.dart';

enum FormFieldType {
  text,
  number,
  dropdown,
}

class FormFieldDefinition {
  final String label;
  final FormFieldType type;

  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? errorText;

  final List<DropdownMenuItem<dynamic>>? items;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;

  final bool enabled;
  final int? maxLines;
  final TextInputType? keyboardType;

  const FormFieldDefinition({
    required this.label,
    required this.type,
    this.controller,
    this.validator,
    this.errorText,
    this.items,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
  });
}