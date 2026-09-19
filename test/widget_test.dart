import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:up04_01_flutter_web/widgets/entity_form.dart';
import 'package:up04_01_flutter_web/widgets/form_field_definition.dart';

void main() {
  group('EntityForm', () {
    testWidgets(
      'shows loading indicator while loading',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EntityForm(
              formKey: GlobalKey<FormState>(),
              title: 'Фильм',
              isEditing: false,
              isLoading: true,
              isSaving: false,
              hasUnsavedChanges: false,
              onSubmit: () {},
              onCancel: () {},
              fields: const [],
            ),
          ),
        );

        expect(
          find.byType(CircularProgressIndicator),
          findsOneWidget,
        );
        expect(find.text('Фильм'), findsOneWidget);
      },
    );

    testWidgets(
      'shows validation error for required field',
          (tester) async {
        final formKey = GlobalKey<FormState>();
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: EntityForm(
              formKey: formKey,
              title: 'Фильм',
              isEditing: false,
              isLoading: false,
              isSaving: false,
              hasUnsavedChanges: false,
              onSubmit: () {
                formKey.currentState!.validate();
              },
              onCancel: () {},
              fields: [
                FormFieldDefinition(
                  label: 'Название',
                  type: FormFieldType.text,
                  controller: controller,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Поле обязательно';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.text('Создать'));
        await tester.pump();

        expect(
          find.text('Поле обязательно'),
          findsOneWidget,
        );

        controller.dispose();
      },
    );
  });
}