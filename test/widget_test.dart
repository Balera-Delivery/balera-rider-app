import 'package:flutter_test/flutter_test.dart';
import 'package:balera_rider_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BalerraRiderApp());
    expect(find.byType(BalerraRiderApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
