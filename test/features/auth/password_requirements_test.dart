import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/auth/presentation/password_requirements.dart';

void main() {
  testWidgets('acompanha o controller ao vivo: ○ curta → ✓ ok', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PasswordRequirements(controller: controller)),
      ),
    );

    expect(find.text('Pelo menos 8 caracteres'), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    controller.text = 'curta';
    await tester.pump();
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);

    controller.text = 'agora-vai-passar';
    await tester.pump();
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNothing);
  });
}
