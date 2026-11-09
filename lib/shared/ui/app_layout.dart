import 'package:flutter/material.dart';

import '../../core/platform/window_size_policy.dart';

/// Single source of truth for "does this widget need the compact layout?".
///
/// Before phone-landscape support, layouts scattered `width < 600` checks
/// around. Those checks are correct for a portrait phone and for a desktop
/// window, but wrong for a phone turned sideways: its content is ~800dp wide
/// and only ~360dp tall. Every call site that used to read a raw width goes
/// through [compactOf] instead, so the short-landscape rule stays in one place.
///
/// These helpers depend on MediaQuery/Theme, so they already rebuild when the
/// device rotates, the window resizes or the user changes text scaling. No
/// extra inherited scope or observer is needed.
abstract final class AppLayout {
  static const double expandedWidth = WindowSizePolicy.expandedWidth;

  /// Width at which playback normally moves the info column beside the player.
  static const double playbackSideBySideWidth = 1000.0;

  /// The full logical viewport, including areas behind system bars.
  static Size viewportOf(BuildContext context) => MediaQuery.sizeOf(context);

  static bool mobileOf(BuildContext context) =>
      WindowSizePolicy.isMobile(Theme.of(context).platform);

  /// True only for a phone-class display currently held in landscape.
  static bool phoneLandscapeOf(BuildContext context) =>
      mobileOf(context) && WindowSizePolicy.phoneLandscape(viewportOf(context));

  /// Compact treatment for an optional content [extent] (LayoutBuilder's
  /// `maxWidth`). Omit [extent] to classify the whole viewport.
  static bool compactOf(BuildContext context, {double? extent}) {
    final viewport = viewportOf(context);
    return WindowSizePolicy.compactExtent(
      extent: extent ?? viewport.width,
      viewport: viewport,
      mobile: mobileOf(context),
    );
  }

  /// Very little vertical room, regardless of orientation. Toolbars, headers
  /// and navigation rails use this to shed optional rows in short windows.
  static bool shortOf(BuildContext context) =>
      viewportOf(context).height <= WindowSizePolicy.shortViewportHeight;

  /// Playback uses a full-height player with the info column beside it. On a
  /// phone or tablet held sideways the stacked portrait layout cannot fit the
  /// player and the info tabs in the short vertical space, so the side-by-side
  /// form starts as soon as the mobile viewport is rotated into landscape and
  /// has at least [expandedWidth] of horizontal room. Desktop keeps the wider
  /// [playbackSideBySideWidth] gate because its narrow windows are not phones.
  static bool playbackSideBySideOf(
    BuildContext context, {
    required double extent,
  }) {
    if (extent >= playbackSideBySideWidth) return true;
    final viewport = viewportOf(context);
    final landscape = viewport.width > viewport.height;
    return mobileOf(context) && landscape && extent >= expandedWidth;
  }

  /// Bottom navigation sits in the vertical axis, which is scarce in
  /// landscape. Icon-only destinations keep the bar usable at ~44dp.
  static bool compactNavigationOf(BuildContext context) =>
      phoneLandscapeOf(context);
}
