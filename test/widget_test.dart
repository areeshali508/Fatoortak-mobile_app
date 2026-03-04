// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:fatoortak_mobile_app/main.dart';

void main() {
  testWidgets('App shows splash screen on start', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('SMART INVOICING SOLUTIONS'), findsNothing);
    expect(find.text('v1.0.2'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Object widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/images/logo_fb.png',
      ),
      findsOneWidget,
    );
  });
}
