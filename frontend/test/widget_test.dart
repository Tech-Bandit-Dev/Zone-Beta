import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zone/main.dart';

void main() {
  testWidgets('Landing screen shows sign up and log in',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZoneApp()));

    expect(find.text('Zone'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
