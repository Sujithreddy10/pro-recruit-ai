import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

void main() {
  testWidgets('App design system smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text('Hylo Design System', style: AppTypography.titleMedium),
          ),
        ),
      ),
    );

    expect(find.text('Hylo Design System'), findsOneWidget);
    expect(find.byType(Container), findsWidgets);
  });
}
