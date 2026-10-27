// مكتبة التمارين: عرض، بحث، إضافة، تعديل، واختيار من المكتبة أو الكتالوج.
import 'package:flutter/material.dart' hide Text;

import '../catalog.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'catalog_screen.dart';
import 'exercise_detail.dart';

const _emojiSuggest = [
  '💪', '🏋️', '🦵', '🦶', '🏃', '🤸', '🧘', '🥊', '🚴', '🏊', '⛰️', '🦾'
];

bool _matches(Exercise e, String query) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  return '${e.name} ${e.nameEn} ${e.nameAr}'.toLowerCase().contains(q);
}

/// نافذة إضافة/تعديل تمرين. تعيد التمرين المحفوظ أو null.
Future<Exercise?> editExerciseSheet(BuildContext context, Exercise? existing) {
  final nameEn = TextEditingController(text: existing?.nameEn.isNotEmpty == true ? existing!.nameEn : '');
  final nameAr = TextEditingController(text: existing?.nameAr ?? '');
  // تمرين قديم بلا اسمين: ضع اسمه في الخانة المناسبة
  if (existing != null && existing.nameEn.isEmpty && existing.nameAr.isEmpty) {
    if (hasArabicName(existing.name)) {
      nameAr.text = existing.name;
    } else {
      nameEn.text = existing.name;
    }
  }
  final emoji = TextEditingController(text: existing?.emoji ?? '');
  final yt = TextEditingController(text: existing?.youtube ?? '');
  final link = TextEditingController(text: existing?.link ?? '');
  final notes = TextEditingController(text: existing?.notes ?? '');
  final stepsEn = TextEditingController(text: (existing?.stepsEn ?? []).join('\n'));
  final stepsAr = TextEditingController(text: (existing?.stepsAr ?? []).join('\n'));
  final images = TextEditingController(text: (existing?.images ?? []).join('\n'));
  var category = existing?.category ?? 'صدر';
  var type = existing?.type ?? 'reps';
  var equip = existing?.equipment ?? 'bodyweight';

  List<String> lines(TextEditingController c) => c.text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  return showSheet<Exercise>(context, (ctx) {
    final p = ctx.pal;
    return StatefulBuilder(builder: (ctx, setS) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'تمرين جديد' : 'تعديل التمرين',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w900, color: p.text)),
              const SizedBox(height: 14),
              TextField(controller: nameAr, decoration: deco(ctx, 'الاسم بالعربية')),
              const SizedBox(height: 10),
              TextField(controller: nameEn, decoration: deco(ctx, 'الاسم بالإنكليزية')),
              const SizedBox(height: 12),
              const Dim('إيموجي مرتبط بالتمرين (اختياري — إن تركته فارغاً تظهر صورة توضيحية)'),
              const SizedBox(height: 6),
              Row(children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: emoji,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26),
                    decoration: deco(ctx, ''),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final e in _emojiSuggest)
                          GestureDetector(
                            onTap: () => setS(() => emoji.text = e),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Center(
                                  child: Text(e, style: const TextStyle(fontSize: 26))),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              const Dim('القسم'),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in kCategories)
                  Pill(c, selected: category == c, onTap: () => setS(() => category = c)),
              ]),
              const SizedBox(height: 14),
              const Dim('نوع التمرين'),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                Pill('بالعدات', selected: type == 'reps', onTap: () => setS(() => type = 'reps')),
                Pill('وقتي (مثل البلانك)',
                    selected: type == 'time', onTap: () => setS(() => type = 'time')),
              ]),
              const SizedBox(height: 14),
              const Dim('المعدات'),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final e in kEquipLabels.entries)
                  Pill(e.value, selected: equip == e.key, onTap: () => setS(() => equip = e.key)),
              ]),
              const SizedBox(height: 14),
              TextField(
                  controller: yt,
                  keyboardType: TextInputType.url,
                  decoration: deco(ctx, 'رابط فيديو يوتيوب للشرح (يعمل داخل التطبيق)')),
              const SizedBox(height: 10),
              TextField(
                  controller: link,
                  keyboardType: TextInputType.url,
                  decoration: deco(ctx, 'رابط صفحة شرح (اختياري)')),
              const SizedBox(height: 10),
              TextField(
                  controller: stepsAr,
                  maxLines: 4,
                  decoration: deco(ctx, 'خطوات الأداء بالعربية (خطوة في كل سطر)')),
              const SizedBox(height: 10),
              TextField(
                  controller: stepsEn,
                  maxLines: 4,
                  decoration: deco(ctx, 'خطوات الأداء بالإنكليزية (خطوة في كل سطر)')),
              const SizedBox(height: 10),
              TextField(
                  controller: images,
                  maxLines: 2,
                  keyboardType: TextInputType.url,
                  decoration: deco(ctx, 'روابط صور توضيحية (رابط في كل سطر)')),
              const SizedBox(height: 10),
              TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: deco(ctx, 'ملاحظات (اختياري)')),
              const SizedBox(height: 16),
              PButton('حفظ', onTap: () {
                final en = nameEn.text.trim();
                final ar = nameAr.text.trim();
                if (en.isEmpty && ar.isEmpty) {
                  toast(ctx, 'اكتب اسم التمرين');
                  return;
                }
                final e = Exercise(
                  id: existing?.id ?? newId(),
                  name: en.isNotEmpty ? en : ar,
                  nameEn: en,
                  nameAr: ar,
                  emoji: emoji.text.trim(),
                  category: category,
                  type: type,
                  equipment: equip,
                  youtube: yt.text.trim(),
                  link: link.text.trim(),
                  notes: notes.text.trim(),
                  level: existing?.level ?? '',
                  muscles: existing?.muscles,
                  secondary: existing?.secondary,
                  stepsEn: lines(stepsEn),
                  stepsAr: lines(stepsAr),
                  tipsEn: existing?.tipsEn,
                  tipsAr: existing?.tipsAr,
                  images: lines(images),
                  src: existing?.src == 'catalog' ? 'catalog' : 'custom',
                  edited: true,
                  rev: existing?.rev ?? 0,
                );
                store.upsertExercise(e);
                Navigator.pop(ctx, e);
              }),
              if (existing != null && existing.fromCatalog && existing.edited) ...[
                const SizedBox(height: 8),
                PButton('استعادة نسخة الكتالوج', style: BtnStyle.outline, onTap: () {
                  final c = catalog.byId(existing.id);
                  if (c == null) {
                    toast(ctx, 'غير موجود في الكتالوج');
                    return;
                  }
                  store.upsertExercise(c);
                  Navigator.pop(ctx, c);
                }),
              ],
            ]),
      );
    });
  });
}

bool hasArabicName(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);

/// منتقي تمرين: من «مكتبتي» أو من «الكتالوج» مع إمكانية إنشاء تمرين جديد.
Future<Exercise?> pickExercise(BuildContext context) {
  var query = '';
  var cat = '';
  var fromCatalog = false;
  return showSheet<Exercise>(context, (ctx) {
    final p = ctx.pal;
    return StatefulBuilder(builder: (ctx, setS) {
      final source = fromCatalog ? catalog.items : store.data.exercises;
      final list = source.where((e) {
        if (cat.isNotEmpty && e.category != cat) return false;
        return _matches(e, query);
      }).toList();
      return SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.88,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Text('اختر تمريناً',
                    style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w900, color: p.text)),
              ),
              TextButton.icon(
                onPressed: () async {
                  final e = await editExerciseSheet(ctx, null);
                  if (e != null && ctx.mounted) Navigator.pop(ctx, e);
                },
                icon: Icon(Icons.add, color: p.accent),
                label: Text('جديد',
                    style: TextStyle(color: p.accent, fontWeight: FontWeight.w800)),
              ),
            ]),
            Row(children: [
              Pill('مكتبتي',
                  selected: !fromCatalog, onTap: () => setS(() => fromCatalog = false)),
              const SizedBox(width: 8),
              Pill('الكتالوج (${catalog.items.length})',
                  selected: fromCatalog, onTap: () => setS(() => fromCatalog = true)),
            ]),
            const SizedBox(height: 10),
            TextField(
              decoration: deco(ctx, 'بحث'),
              onChanged: (v) => setS(() => query = v.trim()),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Pill('الكل', selected: cat.isEmpty, onTap: () => setS(() => cat = ''))),
                for (final c in kCategories)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Pill(c, selected: cat == c, onTap: () => setS(() => cat = c)),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Dim('لا توجد نتائج'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ExIcon(e, size: 26),
                          title: Text(e.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, color: p.text)),
                          subtitle: Dim(
                              '${e.category} • ${kEquipLabels[e.equipment] ?? ''} • ${e.isTime ? 'وقتي' : 'عدات'}',
                              size: 12),
                          trailing: IconButton(
                            icon: Icon(Icons.info_outline, color: p.dim),
                            onPressed: () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                    builder: (_) => ExerciseDetailScreen(
                                          ex: e,
                                          actionLabel: 'اختيار هذا التمرين',
                                          onAction: (c) {
                                            return true;
                                          },
                                        ))).then((chosen) {
                              if (chosen == true && ctx.mounted) {
                                Navigator.pop(ctx, fromCatalog ? store.addFromCatalog(e) : e);
                              }
                            }),
                          ),
                          onTap: () => Navigator.pop(
                              ctx, fromCatalog ? store.addFromCatalog(e) : e),
                        );
                      },
                    ),
            ),
          ]),
        ),
      );
    });
  });
}

// ======================= شاشة المكتبة =======================
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});
  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String query = '';
  String cat = '';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.data.exercises.where((e) {
          if (cat.isNotEmpty && e.category != cat) return false;
          return _matches(e, query);
        }).toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('مكتبة التمارين'),
            actions: [
              IconButton(
                  tooltip: 'الكتالوج',
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CatalogScreen())),
                  icon: Icon(Icons.cloud_download_outlined, color: p.accent)),
              IconButton(
                  onPressed: () => editExerciseSheet(context, null),
                  icon: Icon(Icons.add_circle, color: p.accent, size: 30)),
            ],
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                decoration: deco(context, 'بحث'),
                onChanged: (v) => setState(() => query = v.trim()),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Pill('الكل',
                            selected: cat.isEmpty, onTap: () => setState(() => cat = ''))),
                    for (final c in kCategories)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Pill(c,
                            selected: cat == c, onTap: () => setState(() => cat = c)),
                      ),
                  ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final e = list[i];
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    onTap: () => openExerciseDetail(context, e),
                    child: Row(children: [
                      ExIcon(e, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: p.text, fontSize: 15)),
                          Dim('${e.category} • ${kEquipLabels[e.equipment] ?? ''} • ${e.isTime ? 'وقتي' : 'عدات'}'
                              '${e.youtube.isNotEmpty ? ' • ▶︎' : ''}',
                              size: 12),
                        ]),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: p.dim),
                        onPressed: () async {
                          if (store.exerciseUsed(e.id)) {
                            toast(context, 'هذا التمرين مستخدم في خطة. احذفه منها أولاً.');
                            return;
                          }
                          final ok = await confirm(
                              context, 'حذف التمرين', 'هل تريد حذف «${e.title}»؟',
                              ok: 'حذف', danger: true);
                          if (ok) store.deleteExercise(e.id);
                        },
                      ),
                    ]),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }
}
