// معلومات الجسم: الملف الشخصي، الأهداف، القياسات، صور التقدم.
import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import 'package:image_picker/image_picker.dart';

import '../engine.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

const _activityLevels = [
  [1.2, 'خامل'],
  [1.375, 'خفيف'],
  [1.55, 'متوسط'],
  [1.725, 'عالٍ'],
  [1.9, 'شديد'],
];

class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('معلومات الجسم')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              _ProfileCard(),
              _TargetsCard(),
              _MeasureCard(),
              _PhotosCard(),
            ],
          ),
        );
      },
    );
  }
}

// ======================= الملف الشخصي =======================
class _ProfileCard extends StatelessWidget {
  const _ProfileCard();
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final pr = store.data.profile;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('بياناتي'),
        const Dim('الجنس'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          Pill('ذكر', selected: pr.gender == 'male', onTap: () {
            pr.gender = 'male';
            store.changed();
          }),
          Pill('أنثى', selected: pr.gender == 'female', onTap: () {
            pr.gender = 'female';
            store.changed();
          }),
        ]),
        const SizedBox(height: 8),
        LabeledRow(
            'العمر',
            NumStepper(
                value: pr.age.toDouble(),
                min: 0,
                max: 100,
                unit: 'سنة',
                onChanged: (v) {
                  pr.age = v.round();
                  store.changed();
                })),
        LabeledRow(
            'الطول',
            NumStepper(
                value: pr.heightCm,
                min: 0,
                max: 250,
                unit: 'سم',
                decimal: true,
                onChanged: (v) {
                  pr.heightCm = v;
                  store.changed();
                })),
        LabeledRow(
            'الوزن',
            NumStepper(
                value: pr.weightKg,
                min: 0,
                max: 300,
                step: 0.5,
                unit: 'كغ',
                decimal: true,
                onChanged: (v) {
                  pr.weightKg = v;
                  store.changed();
                })),
        const SizedBox(height: 8),
        const Dim('هدفي'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Pill('تضخيم عضلات', selected: pr.goal == 'bulk', onTap: () {
            pr.goal = 'bulk';
            store.changed();
          }),
          Pill('تنشيف', selected: pr.goal == 'cut', onTap: () {
            pr.goal = 'cut';
            store.changed();
          }),
          Pill('ثبات', selected: pr.goal == 'maintain', onTap: () {
            pr.goal = 'maintain';
            store.changed();
          }),
        ]),
        const SizedBox(height: 14),
        const Dim('مستوى نشاطي اليومي (خارج التمرين)'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final a in _activityLevels)
            Pill(a[1] as String,
                selected: (pr.activity - (a[0] as double)).abs() < 0.01,
                onTap: () {
                  pr.activity = a[0] as double;
                  store.changed();
                }),
        ]),
        if (!pr.complete) ...[
          const SizedBox(height: 12),
          Text('أدخل العمر والطول والوزن ليبدأ حساب أهدافك.',
              style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }
}

// ======================= الأهداف =======================
class _TargetsCard extends StatelessWidget {
  const _TargetsCard();
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final pr = store.data.profile;
    final t = computeTargets(pr, trainingDay: true);
    final rest = computeTargets(pr, trainingDay: false);

    Widget row(String label, String value, String sub, bool custom,
        VoidCallback edit, VoidCallback reset) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
              Dim(sub, size: 12),
            ]),
          ),
          GestureDetector(
            onTap: edit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: custom ? p.accent.withAlpha(30) : p.surface2,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: custom ? p.accent : p.text)),
                const SizedBox(width: 6),
                Icon(Icons.edit, size: 14, color: p.dim),
              ]),
            ),
          ),
          if (custom)
            IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.refresh, color: p.dim, size: 20),
                onPressed: reset),
        ]),
      );
    }

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('أهدافي اليومية'),
        Dim(pr.complete
            ? 'محسوبة تلقائياً من بياناتك، ويمكنك تعديل أي رقم يدوياً.'
            : 'أرقام تقريبية افتراضية حتى تُدخل بياناتك.'),
        const SizedBox(height: 6),
        row(
            'الماء 💧',
            '${fmtLiters(t.waterMl)} لتر',
            'يوم الراحة: ${fmtLiters(rest.waterMl)} لتر',
            pr.waterGoalL != null, () async {
          final v = await askNumber(context, 'هدف الماء (لتر)', t.waterMl / 1000,
              suffix: 'لتر');
          if (v != null && v > 0 && v < 15) {
            pr.waterGoalL = v;
            store.changed();
          }
        }, () {
          pr.waterGoalL = null;
          store.changed();
        }),
        row('السعرات 🍽️', '${t.kcal}', 'معدل الحرق الأساسي ${t.bmr.round()} • الكلي ${t.tdee.round()}',
            pr.kcalGoal != null, () async {
          final v = await askNumber(context, 'هدف السعرات', t.kcal.toDouble(),
              suffix: 'سعرة', decimal: false);
          if (v != null && v >= 800 && v < 10000) {
            pr.kcalGoal = v.round();
            store.changed();
          }
        }, () {
          pr.kcalGoal = null;
          store.changed();
        }),
        row('البروتين 🥩', '${t.protein} غ', 'حوالي 2 غ لكل كغ من وزنك للتضخيم',
            pr.proteinGoal != null, () async {
          final v = await askNumber(context, 'هدف البروتين (غ)', t.protein.toDouble(),
              suffix: 'غ', decimal: false);
          if (v != null && v >= 20 && v < 600) {
            pr.proteinGoal = v.round();
            store.changed();
          }
        }, () {
          pr.proteinGoal = null;
          store.changed();
        }),
        row('الكربوهيدرات 🍞', '${t.carbs} غ', 'الباقي من السعرات بعد البروتين و25% دهون',
            pr.carbsGoal != null, () async {
          final v = await askNumber(context, 'هدف الكربوهيدرات (غ)', t.carbs.toDouble(),
              suffix: 'غ', decimal: false);
          if (v != null && v >= 20 && v < 1200) {
            pr.carbsGoal = v.round();
            store.changed();
          }
        }, () {
          pr.carbsGoal = null;
          store.changed();
        }),
      ]),
    );
  }
}

// ======================= القياسات =======================
class _MeasureCard extends StatefulWidget {
  const _MeasureCard();
  @override
  State<_MeasureCard> createState() => _MeasureCardState();
}

class _MeasureCardState extends State<_MeasureCard> {
  String metric = 'weight';

  static const _metrics = {
    'weight': 'الوزن',
    'chest': 'الصدر',
    'arm': 'الذراع',
    'waist': 'الخصر',
    'thigh': 'الفخذ',
    'hips': 'الأرداف',
  };

  double _val(Measurement m) {
    switch (metric) {
      case 'chest':
        return m.chest;
      case 'arm':
        return m.arm;
      case 'waist':
        return m.waist;
      case 'thigh':
        return m.thigh;
      case 'hips':
        return m.hips;
      default:
        return m.weight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final all = store.data.measurements;
    final pts = all.where((m) => _val(m) > 0).toList();
    final vals = pts.map(_val).toList();
    final labels = pts.map((m) => fmtShortKey(m.date)).toList();
    String delta = '';
    if (vals.length >= 2) {
      final d = vals.last - vals.first;
      delta = '${d >= 0 ? '+' : ''}${fmtNum(double.parse(d.toStringAsFixed(1)))} منذ البداية';
    }
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle('القياسات',
            trailing: TextButton(
                onPressed: () => _add(context),
                child: Text('+ تسجيل',
                    style: TextStyle(color: p.accent, fontWeight: FontWeight.w800)))),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in _metrics.entries)
            Pill(e.value, selected: metric == e.key, onTap: () => setState(() => metric = e.key)),
        ]),
        const SizedBox(height: 12),
        LineChart(values: vals, labels: labels),
        if (delta.isNotEmpty) Center(child: Dim(delta)),
        const SizedBox(height: 8),
        for (final m in all.reversed.take(6))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Text(fmtShortKey(m.date),
                  style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
              const SizedBox(width: 10),
              Expanded(
                child: Dim(
                    [
                      if (m.weight > 0) 'وزن ${fmtNum(m.weight)}',
                      if (m.chest > 0) 'صدر ${fmtNum(m.chest)}',
                      if (m.arm > 0) 'ذراع ${fmtNum(m.arm)}',
                      if (m.waist > 0) 'خصر ${fmtNum(m.waist)}',
                      if (m.thigh > 0) 'فخذ ${fmtNum(m.thigh)}',
                      if (m.hips > 0) 'أرداف ${fmtNum(m.hips)}',
                    ].join(' • '),
                    size: 12),
              ),
              GestureDetector(
                onTap: () => store.removeMeasurement(m.date),
                child: Icon(Icons.close, size: 18, color: p.dim),
              ),
            ]),
          ),
      ]),
    );
  }

  Future<void> _add(BuildContext context) async {
    final last = store.data.measurements.isEmpty ? null : store.data.measurements.last;
    TextEditingController c(double v) =>
        TextEditingController(text: v > 0 ? fmtNum(v) : '');
    final w = c(last?.weight ?? store.data.profile.weightKg);
    final ch = c(last?.chest ?? 0);
    final ar = c(last?.arm ?? 0);
    final wa = c(last?.waist ?? 0);
    final th = c(last?.thigh ?? 0);
    final hi = c(last?.hips ?? 0);
    await showSheet<void>(context, (ctx) {
      final p = ctx.pal;
      Widget f(String l, TextEditingController t, String unit) => TextField(
            controller: t,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: deco(ctx, l, suffix: unit),
          );
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('قياسات اليوم',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: p.text)),
          const SizedBox(height: 4),
          const Dim('اترك الحقل فارغاً إذا لم تقِسه. يُفضّل القياس كل أسبوع في نفس الوقت.'),
          const SizedBox(height: 14),
          f('الوزن', w, 'كغ'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: f('الصدر', ch, 'سم')),
            const SizedBox(width: 10),
            Expanded(child: f('الذراع', ar, 'سم')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: f('الخصر', wa, 'سم')),
            const SizedBox(width: 10),
            Expanded(child: f('الفخذ', th, 'سم')),
          ]),
          const SizedBox(height: 10),
          f('الأرداف', hi, 'سم'),
          const SizedBox(height: 16),
          PButton('حفظ', onTap: () {
            double g(TextEditingController t) => toDnum(t.text) ?? 0;
            final m = Measurement(
              date: dateKey(store.today),
              weight: g(w),
              chest: g(ch),
              arm: g(ar),
              waist: g(wa),
              thigh: g(th),
              hips: g(hi),
            );
            if (m.weight + m.chest + m.arm + m.waist + m.thigh + m.hips <= 0) {
              toast(ctx, 'أدخل قياساً واحداً على الأقل');
              return;
            }
            store.addMeasurement(m);
            Navigator.pop(ctx);
          }),
        ]),
      );
    });
  }
}

// ======================= صور التقدم =======================
class _PhotosCard extends StatelessWidget {
  const _PhotosCard();
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final photos = store.data.photos;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle('صور التقدم 📸',
            trailing: TextButton(
                onPressed: () => _add(context),
                child: Text('+ صورة',
                    style: TextStyle(color: p.accent, fontWeight: FontWeight.w800)))),
        if (photos.isEmpty)
          const Dim('صوّر نفسك كل أسبوعين من نفس الزاوية لترى الفرق. الصور تبقى على هاتفك فقط.')
        else ...[
          if (photos.length >= 2) _Compare(first: photos.first, last: photos.last),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final ph in photos.reversed)
                GestureDetector(
                  onTap: () => _view(context, ph),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(left: 8),
                    child: Column(children: [
                      Expanded(child: _Thumb(photo: ph, radius: 14)),
                      const SizedBox(height: 4),
                      Dim(fmtShortKey(ph.date), size: 11),
                    ]),
                  ),
                ),
            ]),
          ),
        ],
      ]),
    );
  }

  Future<void> _add(BuildContext context) async {
    final src = await showSheet<ImageSource>(context, (ctx) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          PButton('التقاط صورة', icon: Icons.photo_camera,
              onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          const SizedBox(height: 10),
          PButton('اختيار من المعرض', icon: Icons.photo_library, style: BtnStyle.tonal,
              onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ]),
      );
    });
    if (src == null) return;
    try {
      final x = await ImagePicker()
          .pickImage(source: src, imageQuality: 85, maxWidth: 1600);
      if (x == null) return;
      await store.addPhoto(x.path, '');
    } catch (e) {
      if (context.mounted) toast(context, 'تعذر الحصول على الصورة');
    }
  }

  void _view(BuildContext context, PhotoEntry ph) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ctx.pal.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(store.photoPath(ph)),
                    errorBuilder: (_, __, ___) => const Dim('الصورة غير متوفرة')),
              ),
            ),
            const SizedBox(height: 8),
            Dim(fmtDate(parseKey(ph.date))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: PButton('حذف', style: BtnStyle.danger, onTap: () async {
                await store.removePhoto(ph);
                if (ctx.mounted) Navigator.pop(ctx);
              })),
              const SizedBox(width: 10),
              Expanded(
                  child: PButton('إغلاق',
                      style: BtnStyle.tonal, onTap: () => Navigator.pop(ctx))),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final PhotoEntry photo;
  final double radius;
  const _Thumb({required this.photo, this.radius = 16});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.expand(
        child: Image.file(
          File(store.photoPath(photo)),
          fit: BoxFit.cover,
          cacheWidth: 400,
          errorBuilder: (_, __, ___) => Container(color: p.surface2),
        ),
      ),
    );
  }
}

class _Compare extends StatelessWidget {
  final PhotoEntry first;
  final PhotoEntry last;
  const _Compare({required this.first, required this.last});
  @override
  Widget build(BuildContext context) {
    Widget side(String l, PhotoEntry ph) => Expanded(
          child: Column(children: [
            AspectRatio(aspectRatio: 0.8, child: _Thumb(photo: ph)),
            const SizedBox(height: 6),
            Dim('$l • ${fmtShortKey(ph.date)}', size: 12),
          ]),
        );
    return Row(children: [
      side('قبل', first),
      const SizedBox(width: 10),
      side('الآن', last),
    ]);
  }
}
