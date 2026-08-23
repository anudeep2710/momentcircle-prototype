import 'package:flutter_test/flutter_test.dart';

import 'package:momentcircle/main.dart';

void main() {
  testWidgets('shows the first MomentCircle demo step', (tester) async {
    await tester.pumpWidget(const MomentCircleApp());

    expect(find.text('MomentCircle'), findsOneWidget);
    expect(find.text('Create event + QR'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
  });
}
