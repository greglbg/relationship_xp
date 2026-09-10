import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:relationship_xp/auth/login_screen.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Relationship XP'), findsOneWidget);
    expect(find.text('Sign in'), findsAtLeastNWidgets(1));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
