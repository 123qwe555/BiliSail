import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../features/settings/domain/app_settings.dart';
import '../shared/ui/apple_design.dart';

/// Global visual contract: an iOS/macOS inspired neutral palette with a single
/// system-blue tint, grouped backgrounds and continuous corner radii.
///
/// Colour consumers should keep reading `Theme.of(context).colorScheme`; the
/// [AppleDesign] extension carries the few tokens that do not map onto a
/// Material colour role.
abstract final class BiliTheme {
  /// Kept as a stable name because widgets and tests reference it directly.
  static const accent = ApplePalette.lightTint;
  static const canvas = ApplePalette.lightCard;
  static const ink = ApplePalette.lightLabel;

  static ThemeData light({
    AppFontPreference font = AppFontPreference.harmonyOsSans,
    String systemFontFamily = '',
  }) => _build(Brightness.light, font.resolveFamily(systemFontFamily));

  static ThemeData dark({
    AppFontPreference font = AppFontPreference.harmonyOsSans,
    String systemFontFamily = '',
  }) => _build(Brightness.dark, font.resolveFamily(systemFontFamily));

  static ThemeData _build(Brightness brightness, String? fontFamily) {
    final dark = brightness == Brightness.dark;
    final design = dark ? AppleDesign.dark : AppleDesign.light;

    final surface = design.card;
    final foreground = design.label;
    final muted = design.secondaryLabel;
    final border = design.separator;
    final panel = design.fill;
    final primary = design.tint;

    // Material 3 derives a purple-ish tertiary/container palette from a seed.
    // Neutralise every role so no warm tint leaks into the Apple look.
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: dark
              ? const Color(0xFF123A63)
              : const Color(0xFFE5F1FF),
          onPrimaryContainer: dark
              ? const Color(0xFFD6E9FF)
              : const Color(0xFF0058B8),
          secondary: primary,
          onSecondary: Colors.white,
          secondaryContainer: dark
              ? const Color(0xFF123A63)
              : const Color(0xFFE5F1FF),
          onSecondaryContainer: dark
              ? const Color(0xFFD6E9FF)
              : const Color(0xFF0058B8),
          tertiary: primary,
          onTertiary: Colors.white,
          surface: surface,
          onSurface: foreground,
          onSurfaceVariant: muted,
          surfaceContainerLowest: dark
              ? const Color(0xFF161618)
              : const Color(0xFFFAFAFC),
          surfaceContainerLow: dark
              ? const Color(0xFF1C1C1E)
              : const Color(0xFFF7F7FA),
          surfaceContainer: panel,
          surfaceContainerHigh: dark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFF2F2F7),
          surfaceContainerHighest: dark
              ? const Color(0xFF3A3A3C)
              : const Color(0xFFE9E9ED),
          outline: muted,
          outlineVariant: border,
          error: dark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30),
          onError: Colors.white,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      dividerColor: border,
      hoverColor: primary.withValues(alpha: 0.05),
      focusColor: primary.withValues(alpha: 0.08),
      splashColor: primary.withValues(alpha: 0.06),
      highlightColor: primary.withValues(alpha: 0.04),
      // iOS-style horizontal push for every platform so navigation feels the
      // same as the dialogs, sheets and controls.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          for (final platform in TargetPlatform.values)
            platform: const CupertinoPageTransitionsBuilder(),
        },
      ),
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: AppleRadius.controlBorder,
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[design],
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary, size: 22),
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          fontFamily: fontFamily,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: TextStyle(
          color: primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: muted, fontSize: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: AppleRadius.pillBorder,
        ),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppleRadius.cardBorder),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.6, space: 0.6),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppleRadius.control,
          vertical: 11,
        ),
        // iOS search fields are filled rounded rects, never outlined boxes.
        border: OutlineInputBorder(
          borderRadius: AppleRadius.controlBorder,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppleRadius.controlBorder,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppleRadius.controlBorder,
          borderSide: BorderSide(color: primary.withValues(alpha: 0.5)),
        ),
        hintStyle: TextStyle(color: muted, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: controlShape,
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: controlShape,
          elevation: 0,
          side: BorderSide(color: primary.withValues(alpha: 0.45)),
          foregroundColor: primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: controlShape,
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primary,
          highlightColor: primary.withValues(alpha: 0.08),
          overlayColor: primary.withValues(alpha: 0.06),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: controlShape,
        backgroundColor: panel,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: foreground, fontSize: 13),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppleRadius.cardBorder),
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        contentTextStyle: TextStyle(
          color: foreground,
          fontSize: 13,
          height: 1.4,
        ),
        barrierColor: Colors.black.withValues(alpha: 0.32),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppleRadius.sheetBorder),
        showDragHandle: false,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppleRadius.controlBorder),
        textStyle: TextStyle(color: foreground, fontSize: 14),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: panel,
        thumbColor: Colors.white,
        overlayColor: primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : panel,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: muted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : muted,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: foreground,
        minVerticalPadding: 10,
        shape: RoundedRectangleBorder(borderRadius: AppleRadius.controlBorder),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: muted,
        indicatorColor: primary,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? const Color(0xF22C2C2E) : const Color(0xF21C1C1E),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFF1C1C1E),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: AppleRadius.controlBorder),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: panel,
        circularTrackColor: panel,
      ),
      textTheme: _textTheme(base.textTheme, foreground, muted, fontFamily),
    );
  }

  static TextTheme _textTheme(
    TextTheme base,
    Color foreground,
    Color muted,
    String? fontFamily,
  ) {
    TextStyle? style(
      TextStyle? source,
      double size,
      FontWeight weight,
      double tracking, [
      Color? color,
    ]) => source?.copyWith(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: tracking,
      color: color ?? foreground,
      fontFamily: fontFamily,
    );

    // Keep the established type scale and weights: layout tests and dense
    // information rows depend on them. Tighter tracking alone gives the
    // neutral, SF-like texture without changing any measured box.
    return base.copyWith(
      headlineMedium: style(base.headlineMedium, 24, FontWeight.w500, -0.5),
      titleLarge: style(base.titleLarge, 20, FontWeight.w500, -0.4),
      titleMedium: style(base.titleMedium, 16, FontWeight.w500, -0.25),
      titleSmall: style(base.titleSmall, 14, FontWeight.w500, -0.15),
      bodyMedium: style(base.bodyMedium, 14, FontWeight.w400, -0.1),
      bodySmall: style(base.bodySmall, 12, FontWeight.w400, -0.05, muted),
    );
  }
}
