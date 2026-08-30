import 'package:flutter_test/flutter_test.dart';
import 'package:all_in_one_app/main.dart';

void main() {
  testWidgets('App boots to home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AllInOneApp());
    await tester.pumpAndSettle();
    expect(find.text('What do you want to use?'), findsOneWidget);
  });
}
