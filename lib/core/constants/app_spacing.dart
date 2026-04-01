import 'package:flutter/material.dart';

/// Kingdom Come — Spacing system.
///
/// All spacing values are multiples of a 4 dp base unit.
/// Use these constants everywhere instead of raw numbers to keep the layout
/// grid consistent across the app.
abstract final class AppSpacing {
  // ── Base unit ─────────────────────────────────────────────────────────────

  /// Base unit: 4 dp.
  static const double unit = 4;

  // ── Named spacing values ──────────────────────────────────────────────────

  /// xs — 4 dp. Tight gaps between sibling elements.
  static const double xs = 4;

  /// sm — 8 dp. Small inset / gap.
  static const double sm = 8;

  /// md — 16 dp. Default content padding, standard gap.
  static const double md = 16;

  /// lg — 24 dp. Section spacing, generous padding.
  static const double lg = 24;

  /// xl — 32 dp. Large section dividers, hero padding.
  static const double xl = 32;

  /// xxl — 48 dp. Full-bleed hero sections.
  static const double xxl = 48;

  // ── Horizontal page padding ───────────────────────────────────────────────

  /// Standard horizontal page inset.
  static const double pageH = md; // 16

  /// Wide horizontal inset for tablets.
  static const double pageHWide = xl; // 32

  // ── Vertical page padding ─────────────────────────────────────────────────

  /// Top padding beneath the app bar.
  static const double pageTop = lg; // 24

  /// Bottom padding above the nav bar (+ safe area).
  static const double pageBottom = md; // 16

  // ── Common EdgeInsets presets ─────────────────────────────────────────────

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageH,
    vertical: pageTop,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(sm);

  static const EdgeInsets buttonPaddingH = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm + 4, // 12
  );

  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: sm + 4, // 12
    vertical: xs + 2, // 6
  );

  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: pageH,
    vertical: sm + 4, // 12
  );

  // ── Border radius ─────────────────────────────────────────────────────────

  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusCircle = 9999;

  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl =
      BorderRadius.all(Radius.circular(radiusXl));

  // ── Icon sizes ────────────────────────────────────────────────────────────

  static const double iconXs = 14;
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;

  // ── Avatar / Image sizes ──────────────────────────────────────────────────

  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 64;
  static const double avatarXl = 96;

  // ── SizedBox helpers ──────────────────────────────────────────────────────

  static const Widget gapXs = SizedBox(height: xs, width: xs);
  static const Widget gapSm = SizedBox(height: sm, width: sm);
  static const Widget gapMd = SizedBox(height: md, width: md);
  static const Widget gapLg = SizedBox(height: lg, width: lg);
  static const Widget gapXl = SizedBox(height: xl, width: xl);

  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
  static const Widget hGapXl = SizedBox(width: xl);

  static const Widget vGapXs = SizedBox(height: xs);
  static const Widget vGapSm = SizedBox(height: sm);
  static const Widget vGapMd = SizedBox(height: md);
  static const Widget vGapLg = SizedBox(height: lg);
  static const Widget vGapXl = SizedBox(height: xl);
  static const Widget vGapXxl = SizedBox(height: xxl);
}
