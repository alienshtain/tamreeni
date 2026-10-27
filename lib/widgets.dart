// مكونات واجهة مشتركة ورسومات (حلقة التقدم، كوب الماء، وعاء الأكل، شبكة الأيام).
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import 'engine.dart';
import 'i18n.dart';
import 'models.dart';
import 'theme.dart';
import 'tr_text.dart';

export 'tr_text.dart';

// ======================= بطاقات وعناوين =======================
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final box = Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return box;
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(children: [
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class Dim extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign? align;
  const Dim(this.text, {super.key, this.size = 13, this.align});
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: align,
      style: TextStyle(fontSize: size, color: context.pal.dim, height: 1.4));
}

// ======================= أزرار =======================
enum BtnStyle { filled, tonal, outline, danger, green }

class PButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final BtnStyle style;
  final bool big;
  final bool expand;
  const PButton(
    this.label, {
    super.key,
    this.icon,
    this.onTap,
    this.style = BtnStyle.filled,
    this.big = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Color bg;
    Color fg;
    Color? border;
    switch (style) {
      case BtnStyle.filled:
        bg = p.accent;
        fg = p.onAccent;
        break;
      case BtnStyle.green:
        bg = p.green;
        fg = Colors.white;
        break;
      case BtnStyle.danger:
        bg = p.red;
        fg = Colors.white;
        break;
      case BtnStyle.tonal:
        bg = p.surface2;
        fg = p.text;
        break;
      case BtnStyle.outline:
        bg = Colors.transparent;
        fg = p.text;
        border = p.line;
        break;
    }
    final enabled = onTap != null;
    final h = big ? 64.0 : 48.0;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: big ? 26 : 20, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: big ? 19 : 15,
                  fontWeight: FontWeight.w800,
                  color: fg)),
        ),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(big ? 22 : kRadiusSm + 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(big ? 22 : kRadiusSm + 2),
          onTap: onTap,
          child: Container(
            height: h,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: border == null
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(big ? 22 : kRadiusSm + 2),
                    border: Border.all(color: border, width: 1.5)),
            child: child,
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  const Pill(this.label, {super.key, this.selected = false, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final sel = color ?? p.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? sel : p.surface2,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? (color == null ? p.onAccent : Colors.white) : p.text)),
      ),
    );
  }
}

class RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? bg;
  final Color? fg;
  const RoundIconBtn(this.icon,
      {super.key, this.onTap, this.size = 44, this.bg, this.fg});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: bg ?? p.surface2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: size * 0.5, color: fg ?? p.text)),
        ),
      ),
    );
  }
}

// ======================= حقول =======================
class NumStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;
  final String? unit;
  final bool decimal;
  const NumStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = 9999,
    this.unit,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    void apply(double v) => onChanged(v.clamp(min, max).toDouble());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundIconBtn(Icons.remove, onTap: () => apply(value - step), size: 40),
        GestureDetector(
          onTap: () async {
            final v = await askNumber(context, 'أدخل القيمة', value,
                suffix: unit, decimal: decimal);
            if (v != null) apply(v);
          },
          child: Container(
            constraints: const BoxConstraints(minWidth: 72),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(decimal ? fmtNum(value) : value.round().toString(),
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: p.text)),
              if (unit != null) Dim(unit!, size: 11),
            ]),
          ),
        ),
        RoundIconBtn(Icons.add, onTap: () => apply(value + step), size: 40),
      ],
    );
  }
}

class LabeledRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final String? sub;
  const LabeledRow(this.label, this.trailing, {super.key, this.sub});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: p.text)),
            if (sub != null) Dim(sub!, size: 12),
          ]),
        ),
        trailing,
      ]),
    );
  }
}

// ======================= نوافذ =======================
Future<T?> showSheet<T>(BuildContext c, WidgetBuilder builder) {
  final p = c.pal;
  return showModalBottomSheet<T>(
    context: c,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: builder(ctx),
    ),
  );
}

Future<bool> confirm(BuildContext c, String title, String msg,
    {String ok = 'نعم', String cancel = 'إلغاء', bool danger = false}) async {
  final p = c.pal;
  final r = await showDialog<bool>(
    context: c,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
      content: Text(msg, style: TextStyle(color: p.dim, height: 1.5)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancel, style: TextStyle(color: p.dim))),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ok,
                style: TextStyle(
                    color: danger ? p.red : p.accent,
                    fontWeight: FontWeight.w800))),
      ],
    ),
  );
  return r ?? false;
}

Future<double?> askNumber(BuildContext c, String title, double initial,
    {String? suffix, bool decimal = true}) async {
  final p = c.pal;
  final ctl = TextEditingController(
      text: initial == 0 ? '' : (decimal ? fmtNum(initial) : initial.round().toString()));
  final r = await showDialog<double>(
    context: c,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
      content: TextField(
        controller: ctl,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: deco(ctx, '', suffix: suffix),
        onSubmitted: (v) => Navigator.pop(ctx, toDnum(v)),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: p.dim))),
        TextButton(
            onPressed: () => Navigator.pop(ctx, toDnum(ctl.text)),
            child: Text('حفظ',
                style: TextStyle(color: p.accent, fontWeight: FontWeight.w800))),
      ],
    ),
  );
  return r;
}

double? toDnum(String s) {
  final t = s.trim().replaceAll(',', '.').replaceAll('٫', '.');
  final conv = t.split('').map((ch) {
    final i = '٠١٢٣٤٥٦٧٨٩'.indexOf(ch);
    return i >= 0 ? '$i' : ch;
  }).join();
  final v = double.tryParse(conv);
  if (v == null || !v.isFinite) return null;
  return v;
}

Future<String?> askText(BuildContext c, String title,
    {String initial = '', String? hint}) async {
  final p = c.pal;
  final ctl = TextEditingController(text: initial);
  return showDialog<String>(
    context: c,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
      content: TextField(
        controller: ctl,
        autofocus: true,
        decoration: deco(ctx, '', hint: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: p.dim))),
        TextButton(
            onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
            child: Text('حفظ',
                style: TextStyle(color: p.accent, fontWeight: FontWeight.w800))),
      ],
    ),
  );
}

// ======================= حلقة التقدم =======================
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;
  _RingPainter(this.progress, this.color, this.track, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(c, r, base);
    final pr = progress.clamp(0.0, 1.0).toDouble();
    if (pr <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
        2 * math.pi * pr, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.progress != progress || o.color != color || o.track != track || o.stroke != stroke;
}

class Ring extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;
  const Ring({
    super.key,
    required this.progress,
    this.size = 120,
    this.stroke = 10,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress, color ?? p.accent, p.surface2, stroke),
        child: Center(child: child),
      ),
    );
  }
}

// ======================= كوب الماء =======================
class _CupPainter extends CustomPainter {
  final double progress;
  final Color fill;
  final Color outline;
  final Color back;
  _CupPainter(this.progress, this.fill, this.outline, this.back);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final path = Path()
      ..moveTo(w * 0.10, h * 0.04)
      ..lineTo(w * 0.90, h * 0.04)
      ..lineTo(w * 0.76, h * 0.94)
      ..lineTo(w * 0.24, h * 0.94)
      ..close();
    canvas.drawPath(path, Paint()..color = back);
    canvas.save();
    canvas.clipPath(path);
    final pr = progress.clamp(0.0, 1.0).toDouble();
    final top = h * 0.94 - (h * 0.90) * pr;
    canvas.drawRect(Rect.fromLTRB(0, top, w, h), Paint()..color = fill);
    canvas.restore();
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round
          ..color = outline);
  }

  @override
  bool shouldRepaint(_CupPainter o) =>
      o.progress != progress || o.fill != fill || o.outline != outline || o.back != back;
}

class WaterCup extends StatelessWidget {
  final double progress;
  final double width;
  final double height;
  final Widget? child;
  const WaterCup(
      {super.key, required this.progress, this.width = 110, this.height = 130, this.child});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CupPainter(progress, p.blue, p.blue, p.surface2),
        child: Center(child: child),
      ),
    );
  }
}

// ======================= وعاء الأكل =======================
class _BowlPainter extends CustomPainter {
  final double progress;
  final Color fill;
  final Color outline;
  final Color back;
  _BowlPainter(this.progress, this.fill, this.outline, this.back);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final topY = h * 0.34;
    final bowl = Path()
      ..moveTo(w * 0.04, topY)
      ..arcTo(
          Rect.fromCenter(
              center: Offset(w * 0.5, topY), width: w * 0.92, height: h * 1.1),
          math.pi,
          -math.pi,
          false)
      ..close();
    canvas.drawPath(bowl, Paint()..color = back);
    canvas.save();
    canvas.clipPath(bowl);
    final bottom = topY + h * 0.55;
    final pr = progress.clamp(0.0, 1.0).toDouble();
    final top = bottom - (bottom - topY) * pr;
    canvas.drawRect(Rect.fromLTRB(0, top, w, h), Paint()..color = fill);
    canvas.restore();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = outline;
    canvas.drawPath(bowl, line);
    // قاعدة صغيرة
    canvas.drawLine(Offset(w * 0.34, h * 0.93), Offset(w * 0.66, h * 0.93), line);
    // بخار
    final steam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = outline.withAlpha(120);
    for (final x in [0.36, 0.5, 0.64]) {
      final p = Path()
        ..moveTo(w * x, h * 0.24)
        ..quadraticBezierTo(w * (x + 0.04), h * 0.16, w * x, h * 0.09);
      canvas.drawPath(p, steam);
    }
  }

  @override
  bool shouldRepaint(_BowlPainter o) =>
      o.progress != progress || o.fill != fill || o.outline != outline || o.back != back;
}

class FoodBowl extends StatelessWidget {
  final double progress;
  final double width;
  final double height;
  final Widget? child;
  const FoodBowl(
      {super.key, required this.progress, this.width = 110, this.height = 130, this.child});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _BowlPainter(progress, p.amber, p.amber, p.surface2),
        child: Padding(
          padding: EdgeInsets.only(top: height * 0.3),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ======================= شبكة الأيام =======================
class DayGrid extends StatelessWidget {
  final PlanState state;
  const DayGrid({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final cells = state.cells;
    final n = cells.length;
    return LayoutBuilder(builder: (ctx, cons) {
      final w = cons.maxWidth;
      final gap = n > 300 ? 4.0 : 6.0;
      final target = n > 300 ? 28.0 : 36.0;
      final cols = math.max(1, ((w + gap) / (target + gap)).floor());
      final size = (w - gap * (cols - 1)) / cols;
      final fs = size < 30 ? 10.0 : 12.5;
      final children = <Widget>[];
      for (var i = 0; i < n; i++) {
        final c = cells[i];
        Color bg;
        Color fg = Colors.white;
        switch (c.status) {
          case CellStatus.done:
            bg = p.green;
            break;
          case CellStatus.missed:
            bg = p.red;
            break;
          case CellStatus.rest:
            bg = p.blue;
            break;
          case CellStatus.pending:
            if (c.restType) {
              bg = p.blue.withAlpha(70);
              fg = p.text;
            } else {
              bg = p.surface2;
              fg = p.dim;
            }
            break;
        }
        children.add(Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(size * 0.3),
            border: c.isToday ? Border.all(color: p.accent, width: 3) : null,
          ),
          child: Text('${i + 1}',
              style: TextStyle(
                  color: fg, fontSize: fs, fontWeight: FontWeight.w800)),
        ));
      }
      return Wrap(spacing: gap, runSpacing: gap, children: children);
    });
  }
}

class GridLegend extends StatelessWidget {
  const GridLegend({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget dot(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 14,
              height: 14,
              decoration:
                  BoxDecoration(color: c, borderRadius: BorderRadius.circular(5))),
          const SizedBox(width: 6),
          Text(t, style: TextStyle(fontSize: 12, color: p.dim)),
        ]);
    return Wrap(spacing: 14, runSpacing: 6, children: [
      dot(p.green, 'تمرنت'),
      dot(p.red, 'فائت'),
      dot(p.blue, 'راحة'),
      dot(p.surface2, 'قادم'),
    ]);
  }
}

// ======================= مخطط خطي =======================
class _LinePainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final Color grid;
  final Color text;
  _LinePainter(this.values, this.labels, this.color, this.grid, this.text);

  void _label(Canvas c, String s, Offset o, {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: text, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center ? Offset(o.dx - tp.width / 2, o.dy) : o);
  }

  @override
  void paint(Canvas canvas, Size s) {
    if (values.isEmpty) return;
    const padL = 34.0, padR = 10.0, padT = 10.0, padB = 22.0;
    final cw = s.width - padL - padR;
    final ch = s.height - padT - padB;
    var mn = values.reduce(math.min);
    var mx = values.reduce(math.max);
    if ((mx - mn).abs() < 1e-9) {
      mn -= 1;
      mx += 1;
    }
    final span = mx - mn;
    mn -= span * 0.1;
    mx += span * 0.1;
    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = padT + ch * i / 2;
      canvas.drawLine(Offset(padL, y), Offset(s.width - padR, y), gp);
      final v = mx - (mx - mn) * i / 2;
      _label(canvas, fmtNum(double.parse(v.toStringAsFixed(1))), Offset(0, y - 6));
    }
    Offset pt(int i) {
      final x = values.length == 1
          ? padL + cw / 2
          : padL + cw * i / (values.length - 1);
      final y = padT + ch * (1 - (values[i] - mn) / (mx - mn));
      return Offset(x, y);
    }

    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final o = pt(i);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(pt(i), 4, dot);
    }
    if (labels.isNotEmpty) {
      _label(canvas, labels.first, Offset(padL, s.height - 14));
      if (labels.length > 1) {
        final tp = TextPainter(
            text: TextSpan(text: labels.last, style: const TextStyle(fontSize: 10)),
            textDirection: TextDirection.ltr)
          ..layout();
        _label(canvas, labels.last, Offset(s.width - padR - tp.width, s.height - 14));
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) =>
      o.values != values || o.labels != labels || o.color != color;
}

class LineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final Color? color;
  const LineChart(
      {super.key,
      required this.values,
      this.labels = const [],
      this.height = 160,
      this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (values.isEmpty) {
      return SizedBox(
          height: height,
          child: Center(child: Dim('لا توجد بيانات بعد')));
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LinePainter(values, labels, color ?? p.accent, p.line, p.dim),
        ),
      ),
    );
  }
}

// ======================= شريط تقدم أفقي مدور =======================
class BarProgress extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  const BarProgress(
      {super.key, required this.value, this.color, this.height = 16});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(children: [
        Container(height: height, color: p.surface2),
        FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0).toDouble(),
          child: Container(height: height, color: color ?? p.accent),
        ),
      ]),
    );
  }
}


// ======================= أيقونة التمرين =======================
/// إيموجي مرتبط بالتمرين إن وُجد، وإلا الصورة التوضيحية، وإلا أيقونة عامة.
class ExIcon extends StatelessWidget {
  final Exercise ex;
  final double size;
  const ExIcon(this.ex, {super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final box = size * 1.25;
    Widget generic() => Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
              color: p.accent.withAlpha(30),
              borderRadius: BorderRadius.circular(box * 0.3)),
          child: Icon(Icons.fitness_center, size: size * 0.75, color: p.accent),
        );
    if (ex.emoji.isNotEmpty) {
      return SizedBox(
        width: box,
        height: box,
        child: Center(
            child: Text(ex.emoji, style: TextStyle(fontSize: size))),
      );
    }
    if (ex.images.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(box * 0.3),
        child: Image.network(
          ex.images.first,
          width: box,
          height: box,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => generic(),
          loadingBuilder: (c, child, prog) => prog == null
              ? child
              : Container(
                  width: box,
                  height: box,
                  color: p.surface2,
                ),
        ),
      );
    }
    return generic();
  }
}

/// أيقونة «التالي/الدخول» حسب اتجاه اللغة.
IconData fwdIcon() => isAr ? Icons.chevron_left : Icons.chevron_right;
