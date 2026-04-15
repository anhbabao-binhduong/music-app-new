import 'package:flutter/material.dart';

// ── Colours ──────────────────────────────────────────────────────────────────
const kABg         = Color(0xFF0F0F13);
const kABgAlt      = Color(0xFF111118);
const kACard       = Color(0xFF1A1A2E);
const kACardAlt    = Color(0xFF16162A);
const kABorder     = Color(0xFF252540);
const kAAccent     = Color(0xFF7C3AED);
const kAAccentPink = Color(0xFFEC4899);
const kAMuted      = Color(0xFF6B6B8A);
const kASuccess    = Color(0xFF22C55E);
const kAWarning    = Color(0xFFF59E0B);
const kADanger     = Color(0xFFEF4444);
const kAInfo       = Color(0xFF06B6D4);
const kAWhite      = Colors.white;
const kAWhite70    = Color(0xFFB3B3CC);
const kAWhite30    = Color(0xFF4D4D6B);

// ── Gradients ─────────────────────────────────────────────────────────────────
const kAGradient = LinearGradient(
  colors: [kAAccent, kAAccentPink],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Text styles ───────────────────────────────────────────────────────────────
const kALabelStyle = TextStyle(fontSize: 11, color: kAMuted, letterSpacing: 0.5);
const kAStatStyle  = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kAWhite);
const kATitleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kAWhite);
const kABodyStyle  = TextStyle(fontSize: 13, color: kAWhite70);

// ── Decoration helpers ────────────────────────────────────────────────────────
BoxDecoration kACardDecor({Color? border, Color? bg}) => BoxDecoration(
      color: bg ?? kACard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border ?? kABorder),
    );

// ── Status helpers ────────────────────────────────────────────────────────────
Color statusColor(String status) => switch (status) {
      'approved' => kASuccess,
      'rejected' => kADanger,
      _ => kAWarning,
    };

String statusLabel(String status) => switch (status) {
      'approved' => 'Đã duyệt',
      'rejected' => 'Từ chối',
      _ => 'Chờ duyệt',
    };
