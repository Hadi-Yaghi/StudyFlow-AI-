import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/main.dart';

void main() {
  testWidgets('StudyFlow app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
