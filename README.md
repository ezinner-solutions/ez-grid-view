# EZ Grid View

A **crash-safe, self-aware** drop-in replacement for Flutter's `GridView` that prevents layout crashes in `Column`, `Row`, `Flex`, and nested scroll views.

## 🛑 The Problem

Flutter's `GridView` tries to expand to fill all available space in its scroll direction. When placed inside a parent with **unbounded constraints**, it throws fatal exceptions:
* `"Vertical viewport was given unbounded height."`
* `"Horizontal viewport was given unbounded width."`
* `"RenderBox was not laid out: RenderViewport... NEEDS-PAINT"`

Common scenarios that trigger this crash:
* Placing a vertical grid directly inside a **`Column`**.
* Placing a horizontal grid directly inside a **`Row`**.
* Nesting it inside another **`ListView`**, **`CustomScrollView`**, or **`SingleChildScrollView`**.
* Using it inside an unconstrained **`Flex`** or **`Wrap`**.

## ✅ The EZ Solution

`EzGridView` intercepts unbounded constraints before they can trigger a layout exception:

* **Crash Prevention:** Detects unbounded dimensions and applies a safe fallback size based on available screen space.
* **Developer Feedback (Debug Mode):** Displays a visible **red border** and logs a detailed warning identifying the exact parent widget causing the issue (e.g. `Column`, `Row`).
* **Silent Fix (Release Mode):** Silently constrains the grid so users never experience a red crash screen.
* **100% Drop-in Parity:** Supports all standard `GridView` constructors:
  * `EzGridView(...)` (children list)
  * `EzGridView.builder(...)` (on-demand item builder)
  * `EzGridView.count(...)` (fixed cross-axis count)
  * `EzGridView.extent(...)` (max cross-axis extent)
  * `EzGridView.custom(...)` (custom delegates)

## ✨ Features

* **Zero Dependencies:** Pure Flutter implementation.
* **Omni-Directional:** Protects vertical scrolling, horizontal scrolling, and cross axes.
* **Diagnostics & Telemetry:** Optional `onUnboundedDetected` callback, customizable `fallbackWidth` and `fallbackHeight`, and toggleable `showDebugIndicator`.
* **Standard Properties:** Full support for `controller`, `physics`, `shrinkWrap`, `padding`, `dragStartBehavior`, `keyboardDismissBehavior`, `clipBehavior`, and `hitTestBehavior`.

## 📦 Installation

```shell
flutter pub add ez_grid_view
```

## 🚀 Usage

### 1. Count Constructor (Inside Column)

Normally crashes in Flutter, but renders safely with `EzGridView`:

```dart
Column(
  children: [
    const Text('Gallery'),
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
    crossAxisCount: 2,
    childAspectRatio: 1.5,
  ),
  itemCount: 50,
  itemBuilder: (context, index) => Card(
    child: Center(child: Text('Item $index')),
  ),
)
```

### 3. Extent Constructor

```dart
EzGridView.extent(
  maxCrossAxisExtent: 180,
  children: List.generate(
    12,
    (index) => Card(child: Center(child: Text('Tile $index'))),
  ),
)
```

### 4. Custom Fallback & Diagnostics

```dart
EzGridView.count(
  crossAxisCount: 2,
  fallbackHeight: 250,
  showDebugIndicator: false, // Disables red border in debug mode
  onUnboundedDetected: ({
    required bool isWidthUnbounded,
    required bool isHeightUnbounded,
    required String culprit,
  }) {
    print('Unbounded layout detected caused by: $culprit');
  },
  children: const [
    Card(child: Text('A')),
    Card(child: Text('B')),
  ],
)
```

## 🤝 Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request on [GitHub](https://github.com/Evgenii-Zinner/ez-grid-view).

## 📜 License

MIT License - see the [LICENSE](LICENSE) file for details.
