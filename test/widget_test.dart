import 'package:flutter_test/flutter_test.dart';

import 'package:relationship_xp/app/relationship_xp_app.dart';

void main() {
  testWidgets('Relationship XP home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const RelationshipXpApp());

    expect(find.text('Relationship XP'), findsOneWidget);
    expect(find.text('Welcome to Relationship XP'), findsOneWidget);
    expect(find.text('Your Brownie Points'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
