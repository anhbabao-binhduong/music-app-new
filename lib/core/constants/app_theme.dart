import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color _darkBg        = Color(0xFF0A0A0F);
  static const Color _darkSurface   = Color(0xFF13131A);
  static const Color _darkElevated  = Color(0xFF1E1E2E);
  static const Color _accent        = Color(0xFF7C5CFC);
  static const Color _accentLight   = Color(0xFFB09EFF);
  static const Color _onAccent      = Color(0xFFFFFFFF);
  static const Color _textPrimary   = Color(0xFFF0EEFF);
  static const Color _textSecondary = Color(0xFF8B8AA8);
  static const Color _textMuted     = Color(0xFF4A4966);
  static const Color _divider       = Color(0xFF1F1F30);
  static const Color _lightBg       = Color(0xFFF5F3FF);
  static const Color _lightSurface  = Color(0xFFFFFFFF);
  static const Color _lightElevated = Color(0xFFEDE9FE);

  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final primary   = isLight ? const Color(0xFF1A1730) : _textPrimary;
    final secondary = isLight ? const Color(0xFF6B5EA8) : _textSecondary;

    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 28, fontWeight: FontWeight.w800,
        color: primary, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: primary, letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: secondary, letterSpacing: 0.1,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14, color: primary,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBg,
    colorScheme: const ColorScheme.dark(
      surface:                  _darkSurface,
      onSurface:                _textPrimary,
      surfaceContainerHighest:  _darkElevated,
      primary:                  _accent,
      onPrimary:                _onAccent,
      secondary:                _accentLight,
      onSecondary:              _darkBg,
      outline:                  _divider,
      error:                    Color(0xFFFF6B6B),
    ),
    textTheme: _buildTextTheme(Brightness.dark),
    // ✅ CardThemeData với const (BorderRadius.all thay vì .circular để dùng const)
    cardTheme: const CardThemeData(
      color: _darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    iconTheme: const IconThemeData(color: _textSecondary, size: 24),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 17, fontWeight: FontWeight.w700,
        color: _textPrimary,
      ),
      iconTheme: const IconThemeData(color: _textPrimary),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor:   _accent,
      inactiveTrackColor: _textMuted,
      thumbColor:         _onAccent,
      // ✅ withValues() thay vì withOpacity()
      overlayColor: _accent.withValues(alpha: 0.2),
      trackHeight:  3.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:     _darkSurface,
      selectedItemColor:   _accent,
      unselectedItemColor: _textMuted,
      type:      BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: _divider,
    dividerTheme: const DividerThemeData(color: _divider, thickness: 1),
  );

  // ─── Light Theme ─────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBg,
    colorScheme: ColorScheme.light(
      surface:                  _lightSurface,
      onSurface:                const Color(0xFF1A1730),
      surfaceContainerHighest:  _lightElevated,
      primary:                  _accent,
      onPrimary:                _onAccent,
      secondary:                _accentLight,
      outline:                  Colors.grey.shade200,
    ),
    textTheme: _buildTextTheme(Brightness.light),
    cardTheme: CardThemeData(
      color: _lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 17, fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1730),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor:   _accent,
      inactiveTrackColor: Colors.grey.shade300,
      thumbColor:         _accent,
      trackHeight:        3.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
  );

  // ─── Gradient helpers ────────────────────────────────────
  static LinearGradient playerGradient(Color dominantColor) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          dominantColor.withValues(alpha: 0.6),
          dominantColor.withValues(alpha: 0.2),
          const Color(0xFF0A0A0F),
        ],
        stops: const [0.0, 0.4, 0.85],
      );
}