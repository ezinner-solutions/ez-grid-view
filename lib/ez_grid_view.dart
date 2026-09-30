import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A defensive, self-aware drop-in replacement for [GridView] that prevents
/// layout crashes when placed inside parents with unbounded constraints.
///
/// In standard Flutter, placing a [GridView] inside a [Column], [Row],
/// [Flex], or nested scroll view results in a fatal layout exception:
/// * `"Vertical viewport was given unbounded height"`
/// * `"Horizontal viewport was given unbounded width"`
///
/// [EzGridView] intercepts these unbounded constraints before they cause
/// a crash:
///
/// * **Crash Prevention:** Automatically detects unbounded dimensions in the scrolling
///   or cross axes and applies a sensible, bounded fallback size.
/// * **Developer Feedback:** In debug mode, displays a visible red indicator and logs
///   a detailed, actionable [FlutterError] explaining the exact parent culprit
///   (e.g., [Column], [Row]) and how to permanently fix it.
/// * **Silent Protection:** In release mode, silently resolves the layout so users
///   never experience a red screen of death.
/// * **100% Drop-in Parity:** Supports all standard [GridView] constructors:
///   [EzGridView.new], [EzGridView.builder], [EzGridView.count], [EzGridView.extent],
///   and [EzGridView.custom].
///
/// ## Layout algorithm
///
/// 1. Uses a [LayoutBuilder] to inspect incoming box constraints.
/// 2. If constraints are bounded in both the scrolling and cross axes (or if [shrinkWrap] is true),
///    renders standard [GridView] directly.
/// 3. If unbounded constraints are detected:
///    - Calculates a safe fallback size based on available screen space via [MediaQuery] or [View].
///    - Reports a structured error with culprit diagnosis via [_EzGridViewHelper.reportUnboundedError] in debug mode.
///    - Invokes [onUnboundedDetected] callback if provided.
///    - Wraps the [GridView] in a [SizedBox] with bounded dimensions.
///    - When [showDebugIndicator] is true and running in debug mode, applies a red outline border.
///
/// ## Examples
///
/// ### Safe inside a Column (Crash Prevention)
///
/// ```dart
/// Column(
///   children: [
///     const Text('Header'),
///     // Won't crash! Automatically constrained with a debug warning.
///     EzGridView.count(
///       crossAxisCount: 2,
///       children: const [
///         Card(child: Text('Item 1')),
///         Card(child: Text('Item 2')),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// ### Builder Constructor
///
/// ```dart
/// EzGridView.builder(
///   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
///     crossAxisCount: 3,
///     crossAxisSpacing: 8,
///     mainAxisSpacing: 8,
///   ),
///   itemCount: 30,
///   itemBuilder: (context, index) => Card(child: Center(child: Text('$index'))),
/// )
/// ```
///
/// ### Count Constructor
///
/// ```dart
/// EzGridView.count(
///   crossAxisCount: 3,
///   children: List.generate(9, (index) => Text('Tile $index')),
/// )
/// ```
///
/// ### Extent Constructor
///
/// ```dart
/// EzGridView.extent(
///   maxCrossAxisExtent: 150,
///   children: List.generate(12, (index) => Text('Tile $index')),
/// )
/// ```
///
/// See also:
///
///  * [GridView], the standard Flutter grid layout scroll view.
///  * [EzListView], the companion defensive list view widget.
///  * [EzCustomScrollView], the companion defensive sliver scroll view.
class EzGridView extends StatelessWidget {
  /// The builder used to construct children for [EzGridView.builder].
  final NullableIndexedWidgetBuilder? itemBuilder;

  /// The number of items for [EzGridView.builder].
  final int? itemCount;

  /// A delegate that controls the layout of the children within the [GridView].
  final SliverGridDelegate gridDelegate;

  /// A delegate that provides the children for the [GridView].
  final SliverChildDelegate childrenDelegate;

  /// See [GridView.scrollDirection].
  final Axis scrollDirection;

  /// See [GridView.reverse].
  final bool reverse;

  /// See [GridView.controller].
  final ScrollController? controller;

  /// See [GridView.primary].
  final bool? primary;

  /// See [GridView.physics].
  final ScrollPhysics? physics;

  /// See [GridView.shrinkWrap].
  final bool shrinkWrap;

  /// See [GridView.padding].
  final EdgeInsetsGeometry? padding;

  /// The viewport area to pre-render for offscreen children.
  ///
  /// See [ScrollView.scrollCacheExtent].
  final ScrollCacheExtent? scrollCacheExtent;

  /// See [GridView.semanticChildCount].
  final int? semanticChildCount;

  /// See [GridView.dragStartBehavior].
  final DragStartBehavior dragStartBehavior;

  /// See [GridView.keyboardDismissBehavior].
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// See [GridView.restorationId].
  final String? restorationId;

  /// See [GridView.clipBehavior].
  final Clip clipBehavior;

  /// See [GridView.hitTestBehavior].
  final HitTestBehavior hitTestBehavior;

  /// Whether to display a visible red outline border in debug mode when
  /// unbounded constraints are detected.
  ///
  /// Defaults to `true`.
  final bool showDebugIndicator;

  /// Explicit fallback width to apply when an unbounded horizontal constraint
  /// is detected.
  ///
  /// If `null`, defaults to 50% of the screen width.
  final double? fallbackWidth;

  /// Explicit fallback height to apply when an unbounded vertical constraint
  /// is detected.
  ///
  /// If `null`, defaults to 50% of available screen height.
  final double? fallbackHeight;

  /// Optional callback invoked in debug mode when unbounded constraints are
  /// detected.
  final void Function({
    required bool isWidthUnbounded,
    required bool isHeightUnbounded,
    required String culprit,
  })? onUnboundedDetected;

  /// Creates a defensive, crash-safe [GridView] with a custom [gridDelegate] and child list.
  EzGridView({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    required this.gridDelegate,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    this.scrollCacheExtent,
    List<Widget> children = const <Widget>[],
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.showDebugIndicator = true,
    this.fallbackWidth,
    this.fallbackHeight,
    this.onUnboundedDetected,
  })  : itemBuilder = null,
        itemCount = children.length,
        childrenDelegate = SliverChildListDelegate(
          children,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        );

  /// Creates a defensive, crash-safe [GridView] that builds items on demand.
  EzGridView.builder({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    required this.gridDelegate,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    this.scrollCacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.showDebugIndicator = true,
    this.fallbackWidth,
    this.fallbackHeight,
    this.onUnboundedDetected,
  })  : itemBuilder = itemBuilder,
        itemCount = itemCount,
        childrenDelegate = SliverChildBuilderDelegate(
          itemBuilder,
          findChildIndexCallback: findChildIndexCallback,
          childCount: itemCount,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        );

  /// Creates a defensive, crash-safe [GridView] with a fixed number of tiles in the cross axis.
  EzGridView.count({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    this.scrollCacheExtent,
    List<Widget> children = const <Widget>[],
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.showDebugIndicator = true,
    this.fallbackWidth,
    this.fallbackHeight,
    this.onUnboundedDetected,
  })  : itemBuilder = null,
        itemCount = children.length,
        gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        childrenDelegate = SliverChildListDelegate(
          children,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        );

  /// Creates a defensive, crash-safe [GridView] with tiles that have a maximum cross-axis extent.
  EzGridView.extent({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    required double maxCrossAxisExtent,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    this.scrollCacheExtent,
    List<Widget> children = const <Widget>[],
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.showDebugIndicator = true,
    this.fallbackWidth,
    this.fallbackHeight,
    this.onUnboundedDetected,
  })  : itemBuilder = null,
        itemCount = children.length,
        gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        childrenDelegate = SliverChildListDelegate(
          children,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        );

  /// Creates a defensive, crash-safe [GridView] with custom [gridDelegate] and [childrenDelegate].
  const EzGridView.custom({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    required this.gridDelegate,
    required this.childrenDelegate,
    this.scrollCacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.showDebugIndicator = true,
    this.fallbackWidth,
    this.fallbackHeight,
    this.onUnboundedDetected,
  })  : itemBuilder = null,
        itemCount = null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isUnboundedHeight = constraints.maxHeight.isInfinite;
        final bool isUnboundedWidth = constraints.maxWidth.isInfinite;

        final bool isVertical = scrollDirection == Axis.vertical;

        bool needsFixHeight = false;
        bool needsFixWidth = false;

        if (isVertical) {
          if (isUnboundedHeight && !shrinkWrap) needsFixHeight = true;
          if (isUnboundedWidth) needsFixWidth = true;
        } else {
          if (isUnboundedWidth && !shrinkWrap) needsFixWidth = true;
          if (isUnboundedHeight) needsFixHeight = true;
        }

        final Widget gridView = _buildGridView();

        if (!needsFixHeight && !needsFixWidth) {
          return gridView;
        }

        final fallbackDimensions =
            _EzGridViewHelper.calculateFallbackDimensions(
          context: context,
          constraints: constraints,
          needsFixWidth: needsFixWidth,
          needsFixHeight: needsFixHeight,
          customFallbackWidth: fallbackWidth,
          customFallbackHeight: fallbackHeight,
        );

        if (kDebugMode) {
          final culprit = _EzGridViewHelper.findCulprit(context);

          _EzGridViewHelper.reportUnboundedError(
            needsFixWidth: needsFixWidth,
            needsFixHeight: needsFixHeight,
            scrollDirection: scrollDirection,
            shrinkWrap: shrinkWrap,
            culprit: culprit,
          );

          if (onUnboundedDetected != null) {
            onUnboundedDetected!(
              isWidthUnbounded: needsFixWidth,
              isHeightUnbounded: needsFixHeight,
              culprit: culprit,
            );
          }

          if (showDebugIndicator) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2.5),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: SizedBox(
                width: fallbackDimensions.width,
                height: fallbackDimensions.height,
                child: gridView,
              ),
            );
          }
        }

        return SizedBox(
          width: fallbackDimensions.width,
          height: fallbackDimensions.height,
          child: gridView,
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.custom(
      gridDelegate: gridDelegate,
      childrenDelegate: childrenDelegate,
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      scrollCacheExtent: scrollCacheExtent,
      semanticChildCount: semanticChildCount,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      hitTestBehavior: hitTestBehavior,
    );
  }
}

/// Internal helper for [EzGridView] layout diagnostics and fallback size calculation.
abstract final class _EzGridViewHelper {
  /// Calculates fallback dimensions when unbounded constraints are encountered.
  static Size calculateFallbackDimensions({
    required BuildContext context,
    required BoxConstraints constraints,
    required bool needsFixWidth,
    required bool needsFixHeight,
    required double? customFallbackWidth,
    required double? customFallbackHeight,
  }) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final view = View.maybeOf(context);

    final Size screenSize;
    if (mediaQuery != null) {
      screenSize = mediaQuery.size;
    } else if (view != null && view.devicePixelRatio > 0) {
      screenSize = view.physicalSize / view.devicePixelRatio;
    } else {
      screenSize = const Size(360.0, 640.0);
    }

    final double availableHeight = (screenSize.height -
            (mediaQuery?.padding.top ?? 0) -
            (mediaQuery?.padding.bottom ?? 0) -
            kToolbarHeight)
        .clamp(100.0, double.infinity);

    final double effectiveHeight;
    if (needsFixHeight) {
      if (constraints.maxHeight.isInfinite) {
        effectiveHeight = customFallbackHeight ?? (availableHeight * 0.5);
      } else {
        effectiveHeight = constraints.maxHeight;
      }
    } else {
      effectiveHeight = constraints.maxHeight;
    }

    final double effectiveWidth;
    if (needsFixWidth) {
      if (constraints.maxWidth.isInfinite) {
        effectiveWidth = customFallbackWidth ??
            (screenSize.width * 0.5).clamp(100.0, double.infinity);
      } else {
        effectiveWidth = constraints.maxWidth;
      }
    } else {
      effectiveWidth = constraints.maxWidth;
    }

    return Size(effectiveWidth, effectiveHeight);
  }

  /// Traverses ancestors to find the widget responsible for the unbounded constraint.
  static String findCulprit(BuildContext context) {
    String culprit = 'an unknown parent';
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is Flex ||
          widget is ScrollView ||
          widget is Wrap ||
          widget is UnconstrainedBox) {
        culprit = widget.runtimeType.toString();
        return false;
      }
      return true;
    });
    return culprit;
  }

  /// Reports a detailed error to [FlutterError] explaining the exact cause and resolution.
  static void reportUnboundedError({
    required bool needsFixWidth,
    required bool needsFixHeight,
    required Axis scrollDirection,
    required bool shrinkWrap,
    required String culprit,
  }) {
    final String problematicDimension;
    if (needsFixWidth && needsFixHeight) {
      problematicDimension = 'width and height';
    } else if (needsFixWidth) {
      problematicDimension = 'width';
    } else {
      problematicDimension = 'height';
    }

    final String axisName =
        scrollDirection == Axis.vertical ? 'vertical' : 'horizontal';

    FlutterError.reportError(
      FlutterErrorDetails(
        exception:
            'EzGridView: Unbounded $problematicDimension detected in $axisName scroll direction.',
        library: 'EzGridView',
        context: ErrorDescription('while building EzGridView'),
        informationCollector: () => [
          ErrorSummary(
              'EzGridView has applied an automatic layout fallback to prevent a crash.'),
          ErrorDescription(
            'This widget was placed inside a $culprit with infinite $problematicDimension. '
            'In standard Flutter, this causes a fatal "Vertical/Horizontal viewport was given unbounded height/width" exception.',
          ),
          ErrorHint(
            'ACTION REQUIRED: For a permanent fix, wrap EzGridView in an Expanded or Flexible (inside Flex/Column/Row), or a SizedBox with explicit dimensions.',
          ),
          if (!shrinkWrap &&
              ((scrollDirection == Axis.vertical && needsFixHeight) ||
                  (scrollDirection == Axis.horizontal && needsFixWidth)))
            ErrorHint(
              'Alternatively, if the grid is intended to be only as tall/wide as its children, set shrinkWrap: true.',
            ),
        ],
      ),
    );
  }
}
