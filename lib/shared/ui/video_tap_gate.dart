import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Suppresses repeat taps that would open a second video page while the first
/// one is still resolving.
///
/// Every opened video allocates its own playback session — a native player plus
/// its own stream — and a page keeps that session alive while it stays in the
/// workspace. Tapping through a grid faster than a video can resolve its media
/// URL therefore stacks several sessions at once; they compete for bandwidth
/// and the newest video looks stuck even though nothing is actually broken.
///
/// Disabled while running widget tests: they tap several cards in a row within
/// a few milliseconds of wall-clock time, which is indistinguishable from the
/// double tap this gate exists to swallow. The gate's own behaviour is covered
/// by a dedicated unit test that enables it explicitly.
abstract final class VideoTapGate {
  /// Long enough to swallow a double tap, short enough that a deliberate
  /// "open another video" stays responsive.
  static const Duration window = Duration(milliseconds: 400);

  @visibleForTesting
  static bool enabled = !_isFlutterTest;

  static bool get _isFlutterTest =>
      Platform.environment['FLUTTER_TEST'] == 'true';

  static int? _lastOpenMs;

  /// True when this tap should actually open a video.
  static bool shouldOpen() {
    if (!enabled) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastOpenMs;
    if (last != null && now >= last && now - last < window.inMilliseconds) {
      return false;
    }
    _lastOpenMs = now;
    return true;
  }

  @visibleForTesting
  static void reset() => _lastOpenMs = null;
}
