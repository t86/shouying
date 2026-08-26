import 'package:flutter_test/flutter_test.dart';
import 'package:shouyin_android/main.dart';

void main() {
  testWidgets('shows the Android client label', (tester) async {
    await tester.pumpWidget(const ShouyinAndroidApp());

    expect(find.text('收银 Android 客户端'), findsOneWidget);
  });
}
