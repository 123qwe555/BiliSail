import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';

import '../platform/window_service.dart';
import '../platform/window_size_policy.dart';

class WindowOrientationHost extends StatefulWidget {
  const WindowOrientationHost({
    super.key,
    required this.window,
    required this.child,
    this.allowPhoneLandscape = false,
  });

  final WindowService window;

  /// When enabled, phones are no longer locked to portrait while browsing and
  /// orientation follows the system rotation preference. Fullscreen playback
  /// keeps its explicit orientation requests.
  final bool allowPhoneLandscape;

  final Widget child;

  @override
  State<WindowOrientationHost> createState() => _WindowOrientationHostState();
}

class _WindowOrientationHostState extends State<WindowOrientationHost>
    with WidgetsBindingObserver {
  FlutterView? _view;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _view = View.of(context);
    _applyPolicy();
  }

  @override
  void didChangeMetrics() => _applyPolicy();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _applyPolicy();
  }

  void _applyPolicy() {
    final view = _view;
    if (view == null) return;
    // Both calls are chained onto WindowService's orientation command queue,
    // so a settings change and a rotation arriving in the same frame settle
    // in a deterministic order.
    unawaited(
      widget.window.setBrowseLandscapeAllowed(widget.allowPhoneLandscape),
    );
    final size = WindowSizePolicy.displaySize(view);
    if (size.isEmpty || !size.isFinite) return;
    unawaited(widget.window.updateDisplaySize(size));
  }

  @override
  void didUpdateWidget(covariant WindowOrientationHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.window, widget.window)) {
      unawaited(oldWidget.window.clearDisplayOrientationPolicy());
    }
    _applyPolicy();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.window.clearDisplayOrientationPolicy());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
