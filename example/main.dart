import 'package:ez_grid_view/ez_grid_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EZ Grid View Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const GridDemoScreen(),
    );
  }
}

class GridDemoScreen extends StatelessWidget {
  const GridDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('EZ Grid View Demo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '1. Safe in Column (Unbounded Height fallback)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            // Normally crashes in Column, but safely handled with debug indicator
            EzGridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 6,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => Container(
                color: Colors.indigo[100 * (index % 9 + 1)],
                alignment: Alignment.center,
                child: Text('Item $index'),
              ),
            ),

            const Divider(height: 32),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '2. Safe in Row (Unbounded Width fallback)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            // Normally crashes in Row, but safely handled
            SizedBox(
              height: 100,
              child: Row(
                children: [
                  const Text('Start'),
                  EzGridView.builder(
                    scrollDirection: Axis.horizontal,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 5,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) => Container(
                      width: 80,
                      color: Colors.teal[100 * (index % 9 + 1)],
                      alignment: Alignment.center,
                      child: Text('H-Item $index'),
                    ),
                  ),
                  const Text('End'),
                ],
              ),
            ),

            const Divider(height: 32),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '3. Count Constructor (EzGridView.count)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(
              height: 140,
              child: EzGridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: List.generate(
                  8,
                  (index) => Container(
                    color: Colors.purple[100 * (index % 8 + 1)],
                    alignment: Alignment.center,
                    child: Text('C-$index'),
                  ),
                ),
              ),
            ),

            const Divider(height: 32),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '4. Extent Constructor (EzGridView.extent)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(
              height: 140,
              child: EzGridView.extent(
                maxCrossAxisExtent: 100,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: List.generate(
                  8,
                  (index) => Container(
                    color: Colors.amber[100 * (index % 8 + 1)],
                    alignment: Alignment.center,
                    child: Text('E-$index'),
                  ),
                ),
              ),
            ),

            const Divider(height: 32),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '5. Correct Usage inside Flex (Wrapped in Expanded)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(
              height: 200,
              child: Column(
                children: [
                  const Text('Header inside constrained column'),
                  Expanded(
                    child: EzGridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: 12,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) => Container(
                        color: Colors.orange[100 * (index % 9 + 1)],
                        alignment: Alignment.center,
                        child: Text('$index'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
