import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_layout.dart';

/// Lets the workspace place its navigation control in a page-owned toolbar.
class PageToolbarLeading extends InheritedWidget {
  const PageToolbarLeading({
    super.key,
    required this.leading,
    required super.child,
  });

  final Widget? leading;

  static Widget? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageToolbarLeading>()?.leading;

  @override
  bool updateShouldNotify(PageToolbarLeading oldWidget) =>
      leading != oldWidget.leading;
}

/// A page title and actions that keep their touch targets at narrow widths.
class PageToolbar extends StatelessWidget {
  const PageToolbar({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final leading = PageToolbarLeading.maybeOf(context);
    // Landscape phones have ~360dp of height. A 48dp control plus 16dp of
    // padding costs too much of the scrollable area there, so tighten both
    // while staying above the 40dp touch target minimum.
    final short = AppLayout.shortOf(context);
    final controlSize = short ? 40.0 : 48.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        leading == null ? 20 : 8,
        short ? 2 : 12,
        8,
        short ? 0 : 4,
      ),
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: Size.square(controlSize),
            visualDensity: VisualDensity.standard,
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Below the width of the controls themselves, allow scrolling
            // instead of shrinking or overlapping their touch targets.
            final controlsWidth =
                (actions.length + (leading == null ? 0 : 1)) * controlSize;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(constraints.maxWidth, controlsWidth),
                child: Row(
                  children: [
                    ?leading,
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
