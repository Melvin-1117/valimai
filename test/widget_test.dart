import 'package:flutter_test/flutter_test.dart';
import 'package:valimai/main.dart';

void main() {
  testWidgets('Valimai app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ValimaiApp());

    // Verify that the title VALIMAI and Home screen are rendered.
    expect(find.text('VALIMAI'), findsWidgets);
    expect(find.text('Good morning, Alex'), findsOneWidget);
    expect(find.text('START WORKOUT'), findsOneWidget);
  });
}
