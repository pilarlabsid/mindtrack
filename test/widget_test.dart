import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrack/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MindTrackApp());
    expect(find.byType(MainNavigation), findsOneWidget);
  });
}
