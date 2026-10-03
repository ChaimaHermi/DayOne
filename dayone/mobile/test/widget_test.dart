import 'package:flutter_test/flutter_test.dart';

import 'package:dayone/app/app.dart';

void main() {
  testWidgets('Home screen shows title and connection button', (tester) async {
    await tester.pumpWidget(const DayOneApp());

    expect(find.text('DayOne'), findsOneWidget);
    expect(find.text('Test Backend Connection'), findsOneWidget);
  });
}
