// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:doctor_app/main.dart';

void main() {
  testWidgets('doctor app renders the home screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MyApp());

    expect(find.text('Halo, Pengguna'), findsOneWidget);
    expect(find.text('Carego Wallet'), findsOneWidget);
    expect(find.text('Isi Saldo'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
