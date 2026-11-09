import 'package:flutter/material.dart';

/// Typography from the official desktop client's comment components.
final class CommentTextStyles {
  CommentTextStyles(ThemeData theme)
    : _base = theme.textTheme.bodyMedium ?? const TextStyle(),
      _onSurface = theme.colorScheme.onSurface,
      _dark = theme.brightness == Brightness.dark;

  final TextStyle _base;
  final Color _onSurface;
  final bool _dark;

  // Follow the global scheme instead of a separate hard-coded palette so the
  // comment column stays consistent in both appearances.
  Color get _text => _onSurface;
  Color get _secondary => _onSurface.withValues(alpha: _dark ? .68 : .62);
  Color get _muted => _onSurface.withValues(alpha: _dark ? .5 : .45);

  TextStyle get body => _style(15, 25, _text);
  TextStyle get previewBody => _style(14, 20, _text);
  TextStyle get author => _style(13, 16.25, _secondary);
  TextStyle get previewAuthor => _style(14, 20, _secondary);
  TextStyle get metadata => _style(12, 15, _muted);
  TextStyle get action => _style(13, 16, _muted);
  TextStyle get sort => _style(12, 15, _text);

  TextStyle _style(double size, double lineHeight, Color color) =>
      _base.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: lineHeight / size,
        letterSpacing: -0.1,
        color: color,
      );
}
