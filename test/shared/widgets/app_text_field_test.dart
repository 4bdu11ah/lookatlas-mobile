import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';

void main() {
  testWidgets('AppTextField manages an optional controller and shows a label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppTextField(
            labelText: 'Product name *',
            hintText: 'e.g., Classic Cotton T-Shirt',
          ),
        ),
      ),
    );

    expect(find.text('Product name *'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Leather Bag');
    expect(find.text('Leather Bag'), findsOneWidget);
  });

  testWidgets('AppTextField shows its hint and reports text changes', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? changedText;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            hintText: 'Describe the edit',
            onChanged: (value) => changedText = value,
          ),
        ),
      ),
    );

    expect(find.text('Describe the edit'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Use golden-hour light');

    expect(changedText, 'Use golden-hour light');
  });

  testWidgets('AppTextField configures multiline input from its line limits', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            minLines: 5,
            maxLines: 6,
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.minLines, 5);
    expect(textField.maxLines, 6);
    expect(textField.textInputAction, TextInputAction.newline);
    expect(textField.keyboardType, TextInputType.multiline);
  });

  testWidgets(
    'AppTextField enforces and displays its optional character limit',
    (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppTextField(controller: controller, maxLength: 5),
          ),
        ),
      );

      expect(find.text('0/5'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('0/5')).dx,
        tester.getTopLeft(find.byType(AppTextField)).dx,
      );

      await tester.enterText(find.byType(TextField), '1234567');
      await tester.pump();

      expect(controller.text, '12345');
      expect(find.text('5/5'), findsOneWidget);
    },
  );

  testWidgets('AppTextField can hide its built-in character counter', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            maxLength: 5,
            showCounter: false,
          ),
        ),
      ),
    );

    expect(find.text('0/5'), findsNothing);

    await tester.enterText(find.byType(TextField), '1234567');
    await tester.pump();

    expect(controller.text, '12345');
    expect(find.text('5/5'), findsNothing);
  });

  testWidgets('AppTextField accepts an explicit keyboard type', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            keyboardType: TextInputType.number,
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.keyboardType, TextInputType.number);
  });

  testWidgets(
    'AppTextField capitalizes sentences except for email and password fields',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Column(
              children: [
                AppTextField(fieldKey: ValueKey('name')),
                AppTextField(
                  fieldKey: ValueKey('email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                AppTextField(fieldKey: ValueKey('password'), obscureText: true),
              ],
            ),
          ),
        ),
      );

      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('name')),
                matching: find.byType(TextField),
              ),
            )
            .textCapitalization,
        TextCapitalization.sentences,
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('email')),
                matching: find.byType(TextField),
              ),
            )
            .textCapitalization,
        TextCapitalization.none,
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('password')),
                matching: find.byType(TextField),
              ),
            )
            .textCapitalization,
        TextCapitalization.none,
      );
    },
  );

  testWidgets('AppTextField forwards focus settings', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(focusNode: focusNode, autofocus: true),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.focusNode, same(focusNode));
    expect(textField.autofocus, isTrue);
  });

  testWidgets('AppTextField supports leading and trailing widgets', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            fieldKey: const ValueKey('search-field'),
            hintText: 'Search products',
            leading: const Icon(Icons.search),
            trailing: InkWell(
              key: const ValueKey('clear-search'),
              onTap: () => cleared = true,
              child: const Icon(Icons.close),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('search-field')),
      'bag',
    );
    await tester.tap(find.byKey(const ValueKey('clear-search')));

    expect(controller.text, 'bag');
    expect(cleared, isTrue);
  });

  testWidgets('AppTextField accepts a custom single-line height', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(controller: controller, height: 40),
        ),
      ),
    );

    expect(tester.getSize(find.byType(TextField)).height, 40);
  });

  testWidgets('AppTextField displays validator errors inline', (tester) async {
    final fieldKey = GlobalKey<FormFieldState<String>>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            fieldKey: fieldKey,
            validator: (value) => (value?.trim().length ?? 0) <= 10
                ? 'Enter more than 10 characters.'
                : null,
          ),
        ),
      ),
    );

    fieldKey.currentState!.validate();
    await tester.pump();

    expect(find.text('Enter more than 10 characters.'), findsOneWidget);
  });

  testWidgets('AppTextField supports password and form behavior', (
    tester,
  ) async {
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            helperText: 'Use at least 8 characters',
            onFieldSubmitted: (value) => submitted = value,
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.obscureText, isTrue);
    expect(textField.autofillHints, const [AutofillHints.password]);
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'secure-password');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 'secure-password');
  });

  testWidgets('AppTextField supports expanding input without enforcing limit', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            height: 180,
            child: AppTextField(
              controller: controller,
              expands: true,
              minLines: null,
              maxLines: null,
              maxLength: 5,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              showCounter: false,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '1234567');

    expect(controller.text, '1234567');
  });
}
