import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_hackathon_finder/widgets/custom_button.dart';
import 'package:ai_hackathon_finder/widgets/custom_textfield.dart';
import 'package:ai_hackathon_finder/theme/app_theme.dart';

void main() {
  group('Widget Tests: CustomButton', () {
    testWidgets('CustomButton renders text and triggers onPressed callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomButton(
                text: 'REGISTER NOW',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('REGISTER NOW'), findsOneWidget);
      await tester.tap(find.text('REGISTER NOW'));
      expect(tapped, isTrue);
    });

    testWidgets('CustomButton shows progress indicator when isLoading is true and ignores tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomButton(
                text: 'SUBMITTING',
                isLoading: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('SUBMITTING'), findsNothing);

      await tester.tap(find.byType(CustomButton));
      expect(tapped, isFalse);
    });

    testWidgets('CustomButton renders icon when supplied', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomButton(
                text: 'EXPLORE',
                icon: const Icon(Icons.explore_rounded, key: Key('btn_icon')),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('btn_icon')), findsOneWidget);
      expect(find.text('EXPLORE'), findsOneWidget);
    });
  });

  group('Widget Tests: CustomTextField', () {
    testWidgets('CustomTextField renders label, hint, and accepts user text entry', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CustomTextField(
                controller: controller,
                labelText: 'EMAIL ADDRESS',
                hintText: 'developer@hackpilot.dev',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
          ),
        ),
      );

      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.text('developer@hackpilot.dev'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'test@domain.com');
      expect(controller.text, 'test@domain.com');
    });

    testWidgets('CustomTextField executes validation callback and displays error', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextField(
                controller: controller,
                hintText: 'Enter password',
                validator: (val) => (val == null || val.length < 6) ? 'Password too short' : null,
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Password too short'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '123456');
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Password too short'), findsNothing);
    });
  });

  group('Widget Tests: AppTheme System Tokens', () {
    test('AppTheme dark and light modes provide valid contrasting palettes', () {
      final darkTheme = AppTheme.dark;
      final lightTheme = AppTheme.light;

      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.brightness, Brightness.light);

      expect(darkTheme.scaffoldBackgroundColor, isNotNull);
      expect(lightTheme.scaffoldBackgroundColor, isNotNull);
      expect(darkTheme.scaffoldBackgroundColor != lightTheme.scaffoldBackgroundColor, isTrue);
    });
  });
}
