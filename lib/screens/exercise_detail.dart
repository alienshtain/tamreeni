// شاشة تفاصيل التمرين: صور، فيديو داخل التطبيق، العضلات، الخطوات، النصائح.
import 'package:flutter/material.dart' hide Text;

import '../i18n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'exercises.dart';
import 'yt_player.dart';

const kMuscleAr = {
  'chest': 'الصدر',
  'lats': 'الظهر العريض',
  'upper_back': 'أعلى الظهر',
  'lower_back': 'أسفل الظهر',
  'traps': 'الترابيس (الرقبة والكتف)',
  'front_delts': 'الكتف الأمامي',
  'side_delts': 'الكتف الجانبي',
  'rear_delts': 'الكتف الخلفي',
  'biceps': 'البايسبس',
  'triceps': 'الترايسبس',
  'forearms': 'الساعد',
  'abs': 'البطن',
  'obliques': 'جانبي البطن',
  'quads': 'الفخذ الأمامي',
  'hamstrings': 'الفخذ الخلفي',
  'glutes': 'الأرداف',
  'calves': 'السمانة',
  'hip_flexors': 'مقدمة الحوض',
  'adductors': 'الفخذ الداخلي',
  'abductors': 'الفخذ الخارجي',
  'neck': 'الرقبة',
  'full_body': 'الجسم كاملاً',
};

const kMuscleEn = {
  'chest': 'Chest',
  'lats': 'Lats',
  'upper_back': 'Upper back',
  'lower_back': 'Lower back',
  'traps': 'Traps',
  'front_delts': 'Front delts',
  'side_delts': 'Side delts',
  'rear_delts': 'Rear delts',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'forearms': 'Forearms',
  'abs': 'Abs',
  'obliques': 'Obliques',
  'quads': 'Quads',
  'hamstrings': 'Hamstrings',
  'glutes': 'Glutes',
  'calves': 'Calves',
  'hip_flexors': 'Hip flexors',
  'adductors': 'Inner thighs',
  'abductors': 'Outer thighs',
  'neck': 'Neck',
  'full_body': 'Full body',
};

String muscleName(String key) {
  final m = isAr ? kMuscleAr : kMuscleEn;
  return m[key] ?? key.replaceAll('_', ' ');
}

const kLevelAr = {
  'beginner': 'مبتدئ',
  'intermediate': 'متوسط',
  'advanced': 'متقدم',
};

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise ex;

  /// نص زر الإجراء الرئيسي (مثل «إضافة إلى مكتبتي»). null = بلا زر.
  final String? actionLabel;

  /// يُستدعى عند الضغط؛ إن أعاد true تُغلق الشاشة وتعيد true.
  final bool Function(BuildContext)? onAction;

  /// عرض زر التعديل (للتمارين الموجودة في المكتبة).
  final bool editable;

  const ExerciseDetailScreen({
    super.key,
    required this.ex,
    this.actionLabel,
    this.onAction,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // إن كان التمرين من المكتبة اعرض أحدث نسخة منه بعد التعديل
        final cur = editable ? (store.ex(ex.id) ?? ex) : ex;
        return _build(context, cur);
      },
    );
  }

  Widget _build(BuildContext context, Exercise e) {
    final p = context.pal;
    final vid = youtubeId(e.youtube);
    final steps = e.steps;
    final tips = e.tips;
    Widget chip(String t, {Color? c}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: (c ?? p.surface2),
              borderRadius: BorderRadius.circular(20)),
          child: Text(t,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: p.text)),
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل التمرين'),
        actions: [
          if (editable)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: p.accent),
              onPressed: () => editExerciseSheet(context, e),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Row(children: [
            ExIcon(e, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(e.title,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: p.text)),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            chip(e.category),
            chip(kEquipLabels[e.equipment] ?? ''),
            chip(e.isTime ? 'وقتي' : 'بالعدات'),
            if (e.level.isNotEmpty && kLevelAr.containsKey(e.level))
              chip(kLevelAr[e.level]!),
            if (e.fromCatalog) chip('من الكتالوج', c: p.blue.withAlpha(40)),
          ]),
          const SizedBox(height: 14),
          if (vid != null) ...[
            YtPlayer(videoId: vid, originalUrl: e.youtube),
            const SizedBox(height: 8),
          ] else if (e.youtube.isNotEmpty) ...[
            PButton('شاهد الشرح', icon: Icons.play_circle_fill,
                style: BtnStyle.tonal,
                onTap: () => openExternal(context, e.youtube)),
            const SizedBox(height: 8),
          ],
          if (e.link.isNotEmpty) ...[
            PButton('افتح صفحة الشرح', icon: Icons.link, style: BtnStyle.tonal,
                onTap: () => openExternal(context, e.link)),
            const SizedBox(height: 8),
          ],
          if (vid == null && e.youtube.isEmpty && e.link.isEmpty)
            PButton('ابحث عن شرح في يوتيوب', icon: Icons.search,
                style: BtnStyle.tonal,
                onTap: () => openExternal(
                    context,
                    'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent('${e.nameEn.isNotEmpty ? e.nameEn : e.name} exercise proper form')}')),
          if (e.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: e.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  child: Image.network(
                    e.images[i],
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 190,
                        height: 190,
                        color: p.surface2,
                        child: Icon(Icons.image_not_supported_outlined,
                            color: p.dim)),
                  ),
                ),
              ),
            ),
          ],
          if (e.muscles.isNotEmpty || e.secondary.isNotEmpty) ...[
            const SectionTitle('العضلات المستهدفة'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final m in e.muscles)
                chip(muscleName(m), c: p.accent.withAlpha(40)),
              for (final m in e.secondary) chip(muscleName(m)),
            ]),
          ],
          if (steps.isNotEmpty) ...[
            const SectionTitle('طريقة الأداء'),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: p.accent, shape: BoxShape.circle),
                        child: m_text('${i + 1}', p.onAccent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(steps[i],
                              style: TextStyle(
                                  color: p.text, height: 1.5, fontSize: 14.5))),
                    ]),
                  ),
              ]),
            ),
          ],
          if (tips.isNotEmpty) ...[
            const SectionTitle('نصائح'),
            AppCard(
              color: p.amber.withAlpha(28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final t in tips)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('💡 $t',
                        style: TextStyle(color: p.text, height: 1.5, fontSize: 14)),
                  ),
              ]),
            ),
          ],
          if (e.notes.isNotEmpty) ...[
            const SectionTitle('ملاحظات'),
            Dim(e.notes),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            PButton(actionLabel!, icon: Icons.add, onTap: () {
              if (onAction!(context)) Navigator.pop(context, true);
            }),
          ],
        ],
      ),
    );
  }

  Widget m_text(String t, Color c) => Text(t,
      style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 13));
}

void openExerciseDetail(BuildContext context, Exercise e) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(ex: e, editable: store.ex(e.id) != null)));
}
