import 'package:flutter/material.dart';

/// Neutral surface palette shared by the light and dark variants.
///
/// These are the iOS system colors expressed as plain constants so widgets that
/// are built outside a [BuildContext] (custom painters, const constructors)
/// can still stay on the same visual contract.
abstract final class ApplePalette {
  /// iOS systemBlue / systemBlue(dark).
  static const Color lightTint = Color(0xFF007AFF);
  static const Color darkTint = Color(0xFF0A84FF);

  /// systemGroupedBackground.
  static const Color lightGrouped = Color(0xFFF2F2F7);
  static const Color darkGrouped = Color(0xFF000000);

  /// secondarySystemGroupedBackground (the grouped card / row surface).
  static const Color lightCard = Colors.white;
  static const Color darkCard = Color(0xFF1C1C1E);

  /// systemFill / secondarySystemFill (segmented controls, search fields).
  static const Color lightFill = Color(0xFFE9E9ED);
  static const Color darkFill = Color(0xFF2C2C2E);

  static const Color lightSeparator = Color(0xFFE5E5EA);
  static const Color darkSeparator = Color(0xFF38383A);

  static const Color lightLabel = Color(0xFF1C1C1E);
  static const Color darkLabel = Color(0xFFF2F2F7);
  static const Color lightSecondaryLabel = Color(0xFF8E8E93);
  static const Color darkSecondaryLabel = Color(0xFF98989F);
}

/// Continuous-corner radius scale. Apple uses larger radii than Material 3 and
/// keeps neighbouring surfaces on the same scale so nested corners nest.
abstract final class AppleRadius {
  static const double control = 12;
  static const double card = 16;
  static const double panel = 20;
  static const double sheet = 28;
  static const double pill = 999;

  static BorderRadius get controlBorder => BorderRadius.circular(control);
  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get panelBorder => BorderRadius.circular(panel);
  static BorderRadius get sheetBorder =>
      const BorderRadius.vertical(top: Radius.circular(sheet));
  static BorderRadius get pillBorder => BorderRadius.circular(pill);
}

abstract final class AppleSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

/// Runtime tokens that follow the active brightness.
///
/// Exposed as a [ThemeExtension] so any widget can read the current grouped
/// background, separator or tint with `AppleDesign.of(context)` without
/// duplicating a brightness check.
@immutable
final class AppleDesign extends ThemeExtension<AppleDesign> {
  const AppleDesign({
    required this.groupedBackground,
    required this.card,
    required this.fill,
    required this.separator,
    required this.label,
    required this.secondaryLabel,
    required this.tint,
  });

  final Color groupedBackground;
  final Color card;
  final Color fill;
  final Color separator;
  final Color label;
  final Color secondaryLabel;
  final Color tint;

  static const light = AppleDesign(
    groupedBackground: ApplePalette.lightGrouped,
    card: ApplePalette.lightCard,
    fill: ApplePalette.lightFill,
    separator: ApplePalette.lightSeparator,
    label: ApplePalette.lightLabel,
    secondaryLabel: ApplePalette.lightSecondaryLabel,
    tint: ApplePalette.lightTint,
  );

  static const dark = AppleDesign(
    groupedBackground: ApplePalette.darkGrouped,
    card: ApplePalette.darkCard,
    fill: ApplePalette.darkFill,
    separator: ApplePalette.darkSeparator,
    label: ApplePalette.darkLabel,
    secondaryLabel: ApplePalette.darkSecondaryLabel,
    tint: ApplePalette.darkTint,
  );

  static AppleDesign of(BuildContext context) =>
      Theme.of(context).extension<AppleDesign>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  AppleDesign copyWith({
    Color? groupedBackground,
    Color? card,
    Color? fill,
    Color? separator,
    Color? label,
    Color? secondaryLabel,
    Color? tint,
  }) => AppleDesign(
    groupedBackground: groupedBackground ?? this.groupedBackground,
    card: card ?? this.card,
    fill: fill ?? this.fill,
    separator: separator ?? this.separator,
    label: label ?? this.label,
    secondaryLabel: secondaryLabel ?? this.secondaryLabel,
    tint: tint ?? this.tint,
  );

  @override
  AppleDesign lerp(covariant ThemeExtension<AppleDesign>? other, double t) {
    if (other is! AppleDesign) return this;
    return AppleDesign(
      groupedBackground:
          Color.lerp(groupedBackground, other.groupedBackground, t) ??
          groupedBackground,
      card: Color.lerp(card, other.card, t) ?? card,
      fill: Color.lerp(fill, other.fill, t) ?? fill,
      separator: Color.lerp(separator, other.separator, t) ?? separator,
      label: Color.lerp(label, other.label, t) ?? label,
      secondaryLabel:
          Color.lerp(secondaryLabel, other.secondaryLabel, t) ?? secondaryLabel,
      tint: Color.lerp(tint, other.tint, t) ?? tint,
    );
  }
}
