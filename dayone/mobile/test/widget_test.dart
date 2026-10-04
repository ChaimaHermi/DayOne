import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayone/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash shows DayOne and the start button', (tester) async {
    await tester.pumpWidget(const DayOneApp());
    expect(find.text('DayOne'), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Commencer'), findsOneWidget);
    expect(find.text('Test Backend Connection'), findsNothing);
  });
}
