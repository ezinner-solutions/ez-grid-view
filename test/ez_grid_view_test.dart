import 'package:ez_grid_view/ez_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EzGridView', () {
    testWidgets('renders normally inside bounded constraints',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: EzGridView.count(
                crossAxisCount: 2,
                children: const [
                  Text('Item 1'),
                  Text('Item 2'),
                  Text('Item 3'),
                  Text('Item 4'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 4'), findsOneWidget);
      expect(_hasRedBorder(tester), isFalse);
    });

    testWidgets('prevents crash and renders inside unbounded Column',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Header'),
                EzGridView.count(
                  crossAxisCount: 2,
                  children: const [
                    Text('Tile 1'),
                    Text('Tile 2'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Tile 1'), findsOneWidget);
      expect(find.text('Tile 2'), findsOneWidget);
      expect(_hasRedBorder(tester), isTrue);
    });

    testWidgets('prevents crash and renders inside unbounded Row',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: Row(
                children: [
                  const Text('Start'),
                  EzGridView.count(
                    scrollDirection: Axis.horizontal,
                    crossAxisCount: 1,
                    children: const [
                      Text('H1'),
                      Text('H2'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('H1'), findsOneWidget);
      expect(_hasRedBorder(tester), isTrue);
    });

    testWidgets('invokes onUnboundedDetected callback with culprit information',
        (WidgetTester tester) async {
      bool? detectedWidth;
      bool? detectedHeight;
      String? detectedCulprit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                EzGridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) => Text('Item $index'),
                  onUnboundedDetected: ({
                    required bool isWidthUnbounded,
                    required bool isHeightUnbounded,
                    required String culprit,
                  }) {
                    detectedWidth = isWidthUnbounded;
                    detectedHeight = isHeightUnbounded;
                    detectedCulprit = culprit;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
      expect(detectedHeight, isTrue);
      expect(detectedWidth, isFalse);
      expect(detectedCulprit, 'Column');
    });

    testWidgets(
        'respects custom fallbackWidth and fallbackHeight in UnconstrainedBox',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnconstrainedBox(
              child: EzGridView.count(
                crossAxisCount: 2,
                fallbackWidth: 220,
                fallbackHeight: 180,
                children: const [
                  Text('Custom Sized'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final fallbackBox = sizedBoxes.firstWhere(
        (box) => box.width == 220 && box.height == 180,
      );
      expect(fallbackBox, isNotNull);
      expect(find.text('Custom Sized'), findsOneWidget);
    });

    testWidgets('hides debug red border when showDebugIndicator is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                EzGridView.count(
                  crossAxisCount: 2,
                  showDebugIndicator: false,
                  children: const [
                    Text('No Border'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
      expect(find.text('No Border'), findsOneWidget);
      expect(_hasRedBorder(tester), isFalse);
    });

    testWidgets('renders normally inside Flexible in Column without fix',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Flexible(
                  child: EzGridView.count(
                    crossAxisCount: 2,
                    children: const [
                      Text('Flex 1'),
                      Text('Flex 2'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_hasRedBorder(tester), isFalse);
      expect(find.text('Flex 1'), findsOneWidget);
    });

    testWidgets('EzGridView.extent constructor positions items correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: EzGridView.extent(
                maxCrossAxisExtent: 150,
                children: const [
                  Text('Ext 1'),
                  Text('Ext 2'),
                  Text('Ext 3'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Ext 1'), findsOneWidget);
      expect(find.text('Ext 2'), findsOneWidget);
      expect(find.text('Ext 3'), findsOneWidget);
    });

    testWidgets('default EzGridView constructor works with children',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: EzGridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                children: const [
                  Text('Child 1'),
                  Text('Child 2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
    });

    testWidgets('EzGridView.builder constructor works with itemBuilder',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: EzGridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemCount: 4,
                itemBuilder: (context, index) => Text('Builder $index'),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Builder 0'), findsOneWidget);
      expect(find.text('Builder 3'), findsOneWidget);
    });

    testWidgets('EzGridView.custom constructor works with custom delegates',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: EzGridView.custom(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                childrenDelegate: SliverChildListDelegate(
                  const [
                    Text('Custom 1'),
                    Text('Custom 2'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Custom 1'), findsOneWidget);
      expect(find.text('Custom 2'), findsOneWidget);
    });

    testWidgets('shrinkWrap: true avoids unbounded vertical error in Column',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                EzGridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    Text('Shrunk 1'),
                    Text('Shrunk 2'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Shrunk 1'), findsOneWidget);
      expect(_hasRedBorder(tester), isFalse);
    });
  });
}

bool _hasRedBorder(WidgetTester tester) {
  final containers = tester.widgetList<Container>(find.byType(Container));
  for (final c in containers) {
    if (c.decoration is BoxDecoration) {
      final box = c.decoration as BoxDecoration;
      if (box.border is Border) {
        final b = box.border as Border;
        if (b.top.color == Colors.red) return true;
      }
    }
  }
  return false;
}
