import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cavedivemapf/widgets/underwater_action_button.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required VoidCallback onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: UnderwaterActionButton(
              key: const Key('underwater_button'),
              size: 72,
              color: Colors.blue,
              text: 'GO',
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapWithHold(
    WidgetTester tester, {
    required Duration hold,
    Offset? moveBy,
  }) async {
    final finder = find.byKey(const Key('underwater_button'));
    final gesture = await tester.startGesture(tester.getCenter(finder));
    await tester.pump();
    if (moveBy != null) {
      await gesture.moveBy(moveBy);
      await tester.pump();
    }
    await tester.pump(hold);
    await gesture.up();
    await tester.pump();
  }

  testWidgets('ignores phantom short touch', (tester) async {
    var taps = 0;
    await pumpButton(tester, onTap: () => taps++);

    await tapWithHold(tester, hold: const Duration(milliseconds: 30));

    expect(taps, 0);
  });

  testWidgets('accepts minor drift within tolerance', (tester) async {
    var taps = 0;
    await pumpButton(tester, onTap: () => taps++);

    await tapWithHold(
      tester,
      hold: const Duration(milliseconds: 120),
      moveBy: const Offset(10, 8),
    );

    expect(taps, 1);
  });

  testWidgets('cancels touch when drift exceeds tolerance', (tester) async {
    var taps = 0;
    await pumpButton(tester, onTap: () => taps++);

    await tapWithHold(
      tester,
      hold: const Duration(milliseconds: 120),
      moveBy: const Offset(60, 0),
    );

    expect(taps, 0);
  });

  testWidgets('debounces bounce taps inside cooldown window', (tester) async {
    var taps = 0;
    await pumpButton(tester, onTap: () => taps++);

    await tapWithHold(tester, hold: const Duration(milliseconds: 120));
    await tapWithHold(tester, hold: const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 300));
    await tapWithHold(tester, hold: const Duration(milliseconds: 120));

    expect(taps, 2);
  });
}
