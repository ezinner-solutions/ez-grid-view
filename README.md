# EzGridView

A defensive, crash-safe drop-in replacement for Flutter's `GridView` that automatically handles unbounded height and width constraints in `Column`, `Row`, `Flex`, and nested scroll views.

[![pub package](https://img.shields.io/pub/v/ez_grid_view.svg)](https://pub.dev/packages/ez_grid_view)
[![likes](https://img.shields.io/pub/likes/ez_grid_view.svg)](https://pub.dev/packages/ez_grid_view)
[![popularity](https://img.shields.io/pub/popularity/ez_grid_view.svg)](https://pub.dev/packages/ez_grid_view)
[![pub points](https://img.shields.io/pub/points/ez_grid_view.svg)](https://pub.dev/packages/ez_grid_view)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Problem Statement

In Flutter, standard `GridView` widgets expand to fill all available space along their scrolling axis. When placed inside an unconstrained parent (such as a vertical `Column` or horizontal `Row`), Flutter's viewport layout cannot compute finite dimensions, resulting in an immediate crash and the red error screen:

* Placing a vertical `GridView` inside a `Column` or `Flex` without `Expanded` or `Flexible`.
* Placing a horizontal `GridView` inside a `Row` without explicit width constraints.
* Nesting a `GridView` directly inside another scroll view (`CustomScrollView`, `ListView`, `SingleChildScrollView`) without `shrinkWrap: true`.
* Rendering inside unconstrained wrappers like `UnconstrainedBox` or floating cards.

### Targeted Error Signatures
`EzGridView` catches and prevents the following Flutter layout runtime exceptions:
* `"Vertical viewport was given unbounded height"`
* `"Horizontal viewport was given unbounded width"`
* `"RenderBox was not laid out: RenderViewport #... NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE"`
* `"Failed assertion: line ... pos ...: 'hasSize'"`
* `"A RenderFlex overflowed by ... pixels on the bottom"`

## Technical Solution

`EzGridView` intercepts incoming constraints before the `RenderViewport` can throw a fatal layout exception:

1. **Defensive Layout Fallback:** Uses `LayoutBuilder` to detect infinite constraints along the scrolling or cross axes. When detected, it calculates a responsive fallback size (50% of available screen height/width via `MediaQuery`/`View`) so the widget renders visibly.
2. **Debug Diagnostics:** In debug mode, highlights the widget with a visible red outline border and logs an actionable `FlutterError` identifying the exact parent widget (`Column`, `Row`, `Flex`, etc.) causing the violation.
3. **Silent Release Protection:** In release mode, silently applies the fallback dimensions so end users never experience a crash or red screen.
4. **100% Drop-in Parity:** Supports all five standard `GridView` constructors:
   * `EzGridView(...)` (children list)
   * `EzGridView.builder(...)` (on-demand item builder)
   * `EzGridView.count(...)` (fixed cross-axis count)
   * `EzGridView.extent(...)` (max cross-axis extent)
   * `EzGridView.custom(...)` (custom child delegates)

## Installation

```shell
flutter pub add ez_grid_view
```

## Quick Migration

Replace standard `GridView` with `EzGridView`:

```diff
- GridView.count(
+ EzGridView.count(
    crossAxisCount: 2,
    children: const [Card(child: Text('1')), Card(child: Text('2'))],
  )
```

## Usage Examples

### 1. Crash Prevention inside a Column

In standard Flutter, placing `GridView.count` directly inside a `Column` throws `"Vertical viewport was given unbounded height"`. `EzGridView` prevents the crash:

```dart
Column(
  children: [
    const Text('Gallery'),
    // Does not crash. Renders safely with a red diagnostic outline in debug mode:
    EzGridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: List.generate(
        9,
        (index) => Card(child: Center(child: Text('$index'))),
      ),
    ),
  ],
)
```

### 2. Builder Constructor

```dart
EzGridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemCount: 30,
  itemBuilder: (context, index) => Card(child: Center(child: Text('$index'))),
)
```

### 3. Extent Constructor

```dart
EzGridView.extent(
  maxCrossAxisExtent: 150,
  crossAxisSpacing: 8,
  mainAxisSpacing: 8,
  children: List.generate(12, (index) => Card(child: Center(child: Text('Tile $index')))),
)
```

### 4. Custom Fallback Dimensions & Telemetry Callback

```dart
EzGridView.count(
  crossAxisCount: 2,
  fallbackHeight: 250, // Custom fallback height when unbounded
  showDebugIndicator: false, // Disables red border in debug mode
  onUnboundedDetected: ({
    required bool isWidthUnbounded,
    required bool isHeightUnbounded,
    required String culprit,
  }) {
    // Send diagnostics to your logging or telemetry service
    debugPrint('Unbounded layout caught in $culprit: width=$isWidthUnbounded, height=$isHeightUnbounded');
  },
  children: const [
    Card(child: Text('Item A')),
    Card(child: Text('Item B')),
  ],
)
```

## Permanent Architectural Resolution

While `EzGridView` safely handles constraint failures, the recommended structural patterns in Flutter include:

```dart
// Option A: Provide flex expansion inside Column or Row
Column(
  children: [
    Expanded(
      child: EzGridView.builder(...),
    ),
  ],
)

// Option B: Provide explicit bounding dimensions
SizedBox(
  height: 300,
  child: EzGridView.count(...),
)

// Option C: Use shrinkWrap for small, finite grids
EzGridView.count(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisCount: 2,
  children: const [Card(child: Text('1')), Card(child: Text('2'))],
)
```

## API Reference

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `gridDelegate` | `SliverGridDelegate` | *Required* | Controls layout of tiles in the grid. |
| `childrenDelegate` | `SliverChildDelegate` | *Required* | Supplies children to the viewport. |
| `scrollDirection` | `Axis` | `Axis.vertical` | Scrolling direction (`Axis.vertical` or `Axis.horizontal`). |
| `reverse` | `bool` | `false` | Whether to reverse scroll direction. |
| `controller` | `ScrollController?` | `null` | Controls the scroll position. |
| `primary` | `bool?` | `null` | Whether this is the primary scroll view. |
| `physics` | `ScrollPhysics?` | `null` | Scroll physics configuration. |
| `shrinkWrap` | `bool` | `false` | Whether the extent should wrap the contents. |
| `padding` | `EdgeInsetsGeometry?` | `null` | Viewport content padding. |
| `scrollCacheExtent` | `ScrollCacheExtent?` | `null` | Viewport cache area for pre-rendering offscreen tiles. |
| `showDebugIndicator` | `bool` | `true` | Shows a red outline border in debug mode when unbounded. |
| `fallbackWidth` | `double?` | `null` | Explicit fallback width when horizontal dimension is unbounded. |
| `fallbackHeight` | `double?` | `null` | Explicit fallback height when vertical dimension is unbounded. |
| `onUnboundedDetected` | `Function?` | `null` | Diagnostic callback invoked when an unbounded parent is encountered. |

## Sponsoring & Support

If this package saved you debugging time, consider supporting ongoing maintenance:
* [GitHub Sponsors](https://github.com/sponsors/Evgenii-Zinner/)
* [Thanks.dev](https://thanks.dev/u/gh/evgenii-zinner)
* [Buy Me a Coffee](https://buymeacoffee.com/evgeniizinner)

## License

MIT License. See [LICENSE](LICENSE) for details.
