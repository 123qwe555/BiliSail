import 'dart:async';

import 'package:flutter/material.dart';

import 'apple_design.dart';
import 'apple_motion.dart';

/// Shows one transient notice above the app's routes without blocking input.
void showAppNotice(BuildContext context, String message) {
  final host = context.findAncestorStateOfType<_AppNoticeHostState>();
  if (host == null) {
    throw FlutterError('showAppNotice requires an AppNoticeHost ancestor.');
  }
  host.show(message);
}

/// Install through MaterialApp.builder so dialogs and fullscreen share a host.
class AppNoticeHost extends StatefulWidget {
  const AppNoticeHost({super.key, required this.child});

  final Widget child;

  static Widget builder(BuildContext context, Widget? child) =>
      AppNoticeHost(child: child ?? const SizedBox.shrink());

  @override
  State<AppNoticeHost> createState() => _AppNoticeHostState();
}

class _AppNoticeHostState extends State<AppNoticeHost> {
  Timer? _dismissTimer;
  String? _message;

  void show(String message) {
    _dismissTimer?.cancel();
    setState(() => _message = message);
    _dismissTimer = Timer(const Duration(milliseconds: 1500), () {
      setState(() => _message = null);
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (message != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: Align(
                    alignment: const Alignment(0, .35),
                    child: Semantics(
                      liveRegion: true,
                      child: AppleAppear(
                        fromScale: 0.92,
                        offsetY: 8,
                        duration: AppleMotion.quick,
                        child: Material(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xE62C2C2E)
                              : const Color(0xE61C1C1E),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          borderRadius: AppleRadius.controlBorder,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppleSpacing.xl,
                              vertical: AppleSpacing.m,
                            ),
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.35,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
