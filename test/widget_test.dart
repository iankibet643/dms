import 'package:flutter_test/flutter_test.dart';
import 'package:my_desktop_uploader/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SphereDmsApp());
    expect(find.text('Sphere DMS'), findsWidgets);
  });
}
