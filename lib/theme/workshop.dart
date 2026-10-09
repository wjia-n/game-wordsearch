import 'package:flutter/material.dart';
import 'wordsearch_themes.dart';

/// Shared paper-and-wood text styles and button shapes, mirroring the
/// physical identity of the game: carved wood, kraft paper, ink lettering.
class Workshop {
  static TextStyle display(double size, {required WorkshopThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: theme.ink,
        letterSpacing: 1,
      );

  static TextStyle displayOnDeep(double size,
          {required WorkshopThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: theme.tile,
        letterSpacing: 1,
        shadows: const [
          Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle label(double size, {required WorkshopThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        color: theme.accentDark,
      );

  static TextStyle body(double size,
          {required WorkshopThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme.ink,
      );

  /// A wooden plaque button with bevel, shadow and pressed feedback.
  static Widget woodButton({
    required WorkshopThemeDef theme,
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    double fontSize = 17,
    bool locked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.tile.withValues(alpha: onTap == null ? 0.55 : 1.0),
              theme.soft.withValues(alpha: onTap == null ? 0.55 : 1.0),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.tileEdge, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.35),
              offset: const Offset(0, 1),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked) ...[
              Icon(Icons.lock, size: 16, color: theme.ink.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
            ],
            if (icon != null) ...[
              Icon(icon, size: 18, color: theme.ink),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: theme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A small icon-only round wooden button.
  static Widget woodIconButton({
    required WorkshopThemeDef theme,
    required IconData icon,
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.tile, theme.soft],
          ),
          border: Border.all(color: theme.tileEdge, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: theme.ink, size: 22),
      ),
    );
    return tooltip == null
        ? btn
        : Tooltip(message: tooltip, child: btn);
  }

  /// Section heading plaque.
  static Widget sectionTitle(String text, {required WorkshopThemeDef theme}) =>
      Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Row(
          children: [
            Expanded(child: Divider(color: theme.tileEdge, thickness: 1.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                text.toUpperCase(),
                style: Workshop.label(13, theme: theme),
              ),
            ),
            Expanded(child: Divider(color: theme.tileEdge, thickness: 1.5)),
          ],
        ),
      );
}
