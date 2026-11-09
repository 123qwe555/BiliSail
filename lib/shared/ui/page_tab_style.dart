import 'package:flutter/material.dart';

import 'apple_design.dart';

abstract final class PageTabStyle {
  static const barHeight = 58.0;
  static const iconSize = 16.0;

  static ButtonStyle buttonStyle(BuildContext context) => TextButton.styleFrom(
    minimumSize: const Size(48, 42),
    padding: const EdgeInsets.symmetric(horizontal: AppleSpacing.s),
    shape: RoundedRectangleBorder(borderRadius: AppleRadius.controlBorder),
    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.1,
    ),
  );

  static Widget label(String text, {IconData? icon}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: iconSize),
        const SizedBox(width: 5),
      ],
      Text(text),
    ],
  );
}
