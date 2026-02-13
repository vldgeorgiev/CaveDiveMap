import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cavedivemapf/models/button_config.dart';
import 'package:cavedivemapf/widgets/draggable_button_customizer.dart';

void main() {
  testWidgets('tap selects button exactly once', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DraggableButtonCustomizer(
                config: const ButtonConfig(size: 90, offsetX: 0, offsetY: 0),
                label: 'Save',
                color: Colors.green,
                icon: Icons.save,
                isSelected: false,
                onConfigChanged: (_) {},
                onTap: () => tapCount++,
                screenSize: const Size(400, 800),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DraggableButtonCustomizer));
    await tester.pumpAndSettle();

    expect(tapCount, 1);
  });
}
