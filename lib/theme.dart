// الثيم: ألوان مسطحة بدون تدرجات، قاعدة 60/30/10، حواف دائرية بأسلوب iOS.
import 'package:flutter/material.dart' hide Text;

import 'i18n.dart';
import 'tr_text.dart';

class Pal {
  final Brightness brightness;
  final Color bg; // 60% الخلفية
  final Color surface; // 30% البطاقات
  final Color surface2;
  final Color text;
  final Color dim;
  final Color line;
  final Color accent; // 10% لون التمييز
  final Color onAccent;
  final Color green;
  final Color red;
  final Color blue;
  final Color amber;
  const Pal({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.dim,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.green,
    required this.red,
    required this.blue,
    required this.amber,
  });

  static const light = Pal(
    brightness: Brightness.light,
    bg: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE9E9EF),
    text: Color(0xFF1C1C1E),
    dim: Color(0xFF6B6B76),
    line: Color(0xFFDCDCE3),
    accent: Color(0xFFFF6B2C),
    onAccent: Color(0xFFFFFFFF),
    green: Color(0xFF30B35A),
    red: Color(0xFFE5484D),
    blue: Color(0xFF2F7DF6),
    amber: Color(0xFFF5A623),
  );

  static const dark = Pal(
    brightness: Brightness.dark,
    bg: Color(0xFF0E0E10),
    surface: Color(0xFF1B1B1F),
    surface2: Color(0xFF28282E),
    text: Color(0xFFF2F2F5),
    dim: Color(0xFF9A9AA5),
    line: Color(0xFF34343B),
    accent: Color(0xFFFF8247),
    onAccent: Color(0xFF1A0E08),
    green: Color(0xFF3DD070),
    red: Color(0xFFFF6368),
    blue: Color(0xFF5B9BFF),
    amber: Color(0xFFFFB84D),
  );
}

extension PalCtx on BuildContext {
  Pal get pal => Theme.of(this).brightness == Brightness.dark ? Pal.dark : Pal.light;
}

const double kRadius = 22;
const double kRadiusSm = 14;

ThemeData buildTheme(Pal p) {
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.blue,
    onSecondary: Colors.white,
    error: p.red,
    onError: Colors.white,
    surface: p.surface,
    onSurface: p.text,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    dividerColor: p.line,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle:
          TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.accent.withAlpha(40),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected) ? p.accent : p.dim,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? p.accent : p.dim,
          )),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: p.accent),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.green : p.surface2),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.text,
      contentTextStyle: TextStyle(color: p.bg, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

// ---------- مساعدات حقول الإدخال ----------
InputDecoration deco(BuildContext c, String label, {String? hint, String? suffix}) {
  final p = c.pal;
  OutlineInputBorder b(Color col) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
        borderSide: BorderSide(color: col, width: 1.4),
      );
  return InputDecoration(
    labelText: label.isEmpty ? null : tr(label),
    hintText: hint == null ? null : tr(hint),
    suffixText: suffix == null ? null : tr(suffix),
    filled: true,
    fillColor: p.surface2,
    labelStyle: TextStyle(color: p.dim),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: b(Colors.transparent),
    enabledBorder: b(Colors.transparent),
    focusedBorder: b(p.accent),
  );
}

void toast(BuildContext c, String msg) {
  final m = ScaffoldMessenger.maybeOf(c);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(content: Text(msg, textAlign: TextAlign.center)));
}
