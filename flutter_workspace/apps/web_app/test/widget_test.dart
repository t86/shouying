import 'package:flutter_test/flutter_test.dart';
import 'package:shouyin_web/main.dart';

void main() {
  testWidgets('shows the Web client label', (tester) async {
    await tester.pumpWidget(const ShouyinWebApp());

    expect(find.text('收银 Web 客户端'), findsOneWidget);
  });
}
