import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/theme/app_theme.dart';
import 'package:look_atlas/shared/widgets/app_dropdown.dart';

void main() {
  testWidgets('appDropdown_opensMenuAndSelectsValue', (tester) async {
    var selected = 'Female';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: SizedBox(
                  width: 260,
                  child: AppDropdown<String>(
                    value: selected,
                    values: const ['Female', 'Male', 'Non-binary'],
                    labelFor: (value) => value,
                    onChanged: (value) => setState(() => selected = value),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Female'), findsOneWidget);

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();

    expect(find.text('Male'), findsOneWidget);

    await tester.tap(find.text('Male'));
    await tester.pumpAndSettle();

    expect(find.text('Male'), findsOneWidget);
    expect(selected, 'Male');
  });
}
