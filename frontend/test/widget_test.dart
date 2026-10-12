import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zone/main.dart';

void main() {
  testWidgets('Landing screen shows get started and log in',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZoneApp()));

    expect(find.text('Zone'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });
}
