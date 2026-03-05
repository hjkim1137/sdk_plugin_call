import 'package:flutter_test/flutter_test.dart';
import 'package:caresens_app/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CaresensApp());
    expect(find.text('CareSens Air'), findsOneWidget);
  });
}
