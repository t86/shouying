import 'package:flutter_test/flutter_test.dart';
import 'package:shouyin_windows/main.dart';

void main() {
  testWidgets('shows the Windows client label', (tester) async {
    await tester.pumpWidget(const ShouyinWindowsApp());

    expect(find.text('收银 Windows 客户端'), findsOneWidget);
  });
}
