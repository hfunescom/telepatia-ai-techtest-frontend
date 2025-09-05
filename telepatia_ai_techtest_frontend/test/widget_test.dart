import 'package:flutter_test/flutter_test.dart';

import 'package:telepatia_ai_techtest_frontend/main.dart';

void main() {
  testWidgets('shows app bar title', (WidgetTester tester) async {
    await tester.pumpWidget(const TelepatiaApp());
    expect(find.text('Doctor Helper'), findsOneWidget);
  });
}
