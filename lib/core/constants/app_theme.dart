import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Color Palette ───────────────────────────────────────
  static const Color _darkBg        = Color(0xFF0A0A0F);   // near-black
  static const Color _darkSurface   = Color(0xFF13131A);   // card bg
  static const Color _darkElevated  = Color(0xFF1E1E2E);   // elevated surfaces
  static const Color _accent        = Color(0xFF7C5CFC);   // violet accent
  static const Color _accentLight   = Color(0xFFB09EFF);   // light violet
  static const Color _onAccent      = Color(0xFFFFFFFF);
  static const Color _textPrimary   = Color(0xFFF0EEFF);
  static const Color _textSecondary = Color(0xFF8B8AA8);
  static const Color _textMuted     = Color(0xFF4A4966);
  static const Color _divider       = Color(0xFF1F1F30);

  static const Color _lightBg       = Color(0xFFF5F3FF);
  static const Color _lightSurface  = Color(0xFFFFFFFF);
  static const Color _lightElevated = Color(0xFFEDE9FE);

  // ─── Typography ──────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final primary   = isLight ? const Color(0xFF1A1730) : _textPrimary;
    final secondary = isLight ? const Color(0xFF6B5EA8) : _textSecondary;

    return TextTheme(
      // Song title — bold, display font
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 28, fontWeight: FontWeight.w800,
        color: primary, letterSpacing: -0.5,
      ),
      // Album / playlist title
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: primary, letterSpacing: -0.3,
      ),
      // Song name in list
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: primary,
      ),
      // Artist name
      titleMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: secondary, letterSpacing: 0.1,
      ),
      // Captions, timestamps
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: secondary,
      ),
      // Body text
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
      background:       _darkBg,
      surface:          _darkSurface,
      primary:          _accent,
      onPrimary:        _onAccent,
      secondary:        _accentLight,
      onSecondary:      _darkBg,
      onBackground:     _textPrimary,
      onSurface:        _textPrimary,
      surfaceVariant:   _darkElevated,
      outline:          _divider,
      error:            Color(0xFFFF6B6B),
    ),
    textTheme: _buildTextTheme(Brightness.dark),
    // Card
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    // Icon
    iconTheme: const IconThemeData(color: _textSecondary, size: 24),
    // AppBar
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
    // Slider (progress bar)
    sliderTheme: SliderThemeData(
      activeTrackColor: _accent,
      inactiveTrackColor: _textMuted,
      thumbColor: _onAccent,
      overlayColor: _accent.withOpacity(0.2),
      trackHeight: 3.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    // BottomNav
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkSurface,
      selectedItemColor: _accent,
      unselectedItemColor: _textMuted,
      type: BottomNavigationBarType.fixed,
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
      background:     _lightBg,
      surface:        _lightSurface,
      primary:        _accent,
      onPrimary:      _onAccent,
      secondary:      _accentLight,
      onBackground:   const Color(0xFF1A1730),
      onSurface:      const Color(0xFF1A1730),
      surfaceVariant: _lightElevated,
      outline:        Colors.grey.shade200,
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
      activeTrackColor: _accent,
      inactiveTrackColor: Colors.grey.shade300,
      thumbColor: _accent,
      trackHeight: 3.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
  );

  // ─── Gradient helpers ────────────────────────────────────
  static LinearGradient playerGradient(Color dominantColor) =>
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        dominantColor.withOpacity(0.6),
        dominantColor.withOpacity(0.2),
        const Color(0xFF0A0A0F),
      ],
      stops: const [0.0, 0.4, 0.85],
    );
}