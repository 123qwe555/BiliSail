import 'dart:ui' show FlutterView, Size;

import 'package:flutter/foundation.dart';

abstract final class WindowSizePolicy {
  static const expandedWidth = 600.0;

  /// A phone held sideways is wide enough to clear [expandedWidth] while its
  /// height stays far below a desktop/tablet window. Width-only breakpoints
  /// therefore classify the same device as "expanded" the moment it rotates,
  /// producing desktop sidebars, wide paddings and a 9/16 player taller than
  /// the viewport. Upper bound is deliberately above the tallest common phone
  /// landscape (about 430dp on a 20:9 panel) and below small tablet windows.
  static const shortViewportHeight = 480.0;

  static bool isMobile(TargetPlatform platform) =>
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;

  static Size displaySize(FlutterView view) {
    final display = view.display;
    final size = _logicalSize(display.size, display.devicePixelRatio);
    if (!size.isEmpty) return size;
    // A cached Android engine can report -1 for both size and density before
    // its Activity publishes display metrics. Dividing those first yields 1dp.
    return _logicalSize(view.physicalSize, view.devicePixelRatio);
  }

  static Size _logicalSize(Size physicalSize, double density) {
    if (physicalSize.isEmpty ||
        !physicalSize.isFinite ||
        !density.isFinite ||
        density <= 0) {
      return Size.zero;
    }
    final size = physicalSize / density;
    return size.isFinite ? size : Size.zero;
  }

  static double availableWidth(FlutterView view) =>
      (view.physicalSize.width - view.padding.left - view.padding.right) /
      view.devicePixelRatio;

  static bool compactDisplay(Size size) => size.shortestSide < expandedWidth;

  /// Landscape *phone* viewport, as opposed to a landscape tablet or a small
  /// desktop window. Uses the current viewport (not the physical display) so a
  /// split-screen or a resized desktop window is judged by what it can show.
  /// Callers gate this with [isMobile] so desktop windows keep their existing
  /// width-only behaviour.
  static bool phoneLandscape(Size viewport) =>
      viewport.width > viewport.height &&
      viewport.width >= expandedWidth &&
      viewport.shortestSide < expandedWidth &&
      viewport.height <= shortViewportHeight &&
      viewport.isFinite;

  /// Compact treatment for a whole viewport.
  static bool compactViewport({required Size viewport, required bool mobile}) =>
      viewport.width < expandedWidth || (mobile && phoneLandscape(viewport));

  /// Compact treatment for a content [extent] measured by a LayoutBuilder.
  /// The viewport is still required: a phone in landscape gives its children
  /// ~800dp of width but only ~360dp of height, which cannot host the expanded
  /// two-column layouts those children would otherwise pick.
  static bool compactExtent({
    required double extent,
    required Size viewport,
    required bool mobile,
  }) => extent < expandedWidth || (mobile && phoneLandscape(viewport));

  static bool compactLayout({
    required bool mobile,
    required Size displaySize,
    required double availableWidth,
  }) =>
      availableWidth < expandedWidth || (mobile && compactDisplay(displaySize));
}
