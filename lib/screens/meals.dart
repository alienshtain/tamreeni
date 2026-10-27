// إضافة وجبة: وجبات محفوظة، تحليل صورة بالذكاء الاصطناعي، إدخال يدوي، اختيارات سريعة.
import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../i18n.dart';
import '../meal_ai.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

const _presets = [
  ['🥚 بيضة', 78, 6, 1, 5],
  ['🍗 صدر دجاج 100غ', 165, 31, 0, 4],
  ['🍚 كوب رز', 200, 4, 44, 0],
  ['🍌 موزة', 105, 1, 27, 0],
  ['🥛 كوب حليب', 150, 8, 12, 8],
  ['🍞 شريحة خبز', 80, 3, 14, 1],
  ['🐟 علبة تونة', 120, 26, 0, 1],
  ['🥜 حفنة مكسرات', 170, 6, 6, 15],
];

String macroLine(int kcal, int protein, int carbs, int fat) {
  final b = StringBuffer('$kcal ${tr('سعرة')}');
  if (protein > 0) b.write(' • ${protein}${tr('غ')} ${tr('بروتين')}');
  if (carbs > 0) b.write(' • ${carbs}${tr('غ')} ${tr('كربوهيدرات')}');
  if (fat > 0) b.write(' • ${fat}${tr('غ')} ${tr('دهون')}');
  return b.toString();
}

Future<void> showAddMealSheet(BuildContext context) async {
  final name = TextEditingController();
  final kcal = TextEditingController();
  final prot = TextEditingController();
  final carbs = TextEditingController();
  final fat = TextEditingController();
  var saveForLater = true;
  var photoPath = '';

  void fill(MealResult r) {
    if (r.name.isNotEmpty) name.text = r.name;
    kcal.text = '${r.kcal}';
    prot.text = '${r.protein}';
    carbs.text = '${r.carbs}';
    fat.text = '${r.fat}';
  }

  await showSheet<void>(context, (ctx) {
    final p = ctx.pal;
    return StatefulBuilder(builder: (ctx, setS) {
      final saved = store.savedMealsSorted;

      Future<void> pasteResult() async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final r = parseMealText(data?.text ?? '');
        if (r == null) {
          if (ctx.mounted) {
            toast(ctx, 'لم أجد نتيجة صالحة في الحافظة. انسخ رد الذكاء الاصطناعي أولاً.');
          }
          return;
        }
        setS(() => fill(r));
        if (ctx.mounted) toast(ctx, 'تمت قراءة النتيجة. راجعها ثم احفظ.');
      }

      Future<void> sharePhoto() async {
        final src = await showSheet<ImageSource>(ctx, (c2) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                PButton('التقاط صورة', icon: Icons.photo_camera,
                    onTap: () => Navigator.pop(c2, ImageSource.camera)),
                const SizedBox(height: 10),
                PButton('من المعرض', icon: Icons.photo_library,
                    style: BtnStyle.tonal,
                    onTap: () => Navigator.pop(c2, ImageSource.gallery)),
              ]),
            ));
        if (src == null) return;
        try {
          final x = await ImagePicker()
              .pickImage(source: src, imageQuality: 85, maxWidth: 1400);
          if (x == null) return;
          photoPath = x.path;
          await Share.shareXFiles([XFile(x.path)], text: buildMealPrompt());
          if (ctx.mounted) {
            setS(() {});
            toast(ctx, 'بعد أن يرد الذكاء الاصطناعي انسخ رده ثم اضغط «لصق النتيجة».');
          }
        } catch (e) {
          if (ctx.mounted) toast(ctx, 'تعذر فتح الصورة أو المشاركة');
        }
      }

      Future<void> saveManual() async {
        final k = toDnum(kcal.text)?.round() ?? 0;
        if (k <= 0) {
          toast(ctx, 'أدخل عدد السعرات');
          return;
        }
        final e = FoodEntry(
            name: name.text.trim(),
            kcal: k,
            protein: toDnum(prot.text)?.round() ?? 0,
            carbs: toDnum(carbs.text)?.round() ?? 0,
            fat: toDnum(fat.text)?.round() ?? 0);
        store.addFood(e);
        if (saveForLater && e.name.isNotEmpty) {
          var photo = '';
          if (photoPath.isNotEmpty) photo = await store.saveMealPhoto(photoPath);
          store.saveMeal(e, photo: photo);
        }
        if (ctx.mounted) Navigator.pop(ctx);
      }

      Widget numField(TextEditingController c, String label) => Expanded(
            child: TextField(
                controller: c,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: deco(ctx, label)),
          );

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إضافة وجبة',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: p.text)),
              if (saved.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Dim('وجباتي المحفوظة (اضغط للإضافة):'),
                const SizedBox(height: 8),
                for (final m in saved)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(kRadiusSm),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(kRadiusSm),
                        onTap: () {
                          store.useMeal(m);
                          Navigator.pop(ctx);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(children: [
                            if (m.photo.isNotEmpty &&
                                File(store.mealPhotoPath(m.photo)).existsSync())
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(File(store.mealPhotoPath(m.photo)),
                                    width: 42, height: 42, fit: BoxFit.cover),
                              )
                            else
                              const Text('🍽️', style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800, color: p.text)),
                                    Dim(macroLine(m.kcal, m.protein, m.carbs, m.fat),
                                        size: 12),
                                  ]),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: p.dim, size: 20),
                              onPressed: () async {
                                final ok = await confirm(ctx, 'حذف الوجبة',
                                    'هل تريد حذف «${m.name}» من المحفوظات؟',
                                    ok: 'حذف', danger: true);
                                if (ok) {
                                  store.deleteMeal(m);
                                  setS(() {});
                                }
                              },
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 14),
              AppCard(
                margin: EdgeInsets.zero,
                color: p.accent.withAlpha(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('🤖 تحليل الوجبة بالذكاء الاصطناعي',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15, color: p.text)),
                  const SizedBox(height: 4),
                  const Dim(
                      'صوّر الوجبة وأرسلها مع البرومبت لأي ذكاء اصطناعي (ChatGPT، Gemini، Claude...). '
                      'ثم انسخ رده والصقه هنا لتُسجَّل السعرات والبروتين والكربوهيدرات تلقائياً.',
                      size: 12.5),
                  const SizedBox(height: 10),
                  PButton('صورة الوجبة + البرومبت (مشاركة)', icon: Icons.photo_camera,
                      onTap: sharePhoto),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: PButton('نسخ البرومبت', icon: Icons.copy,
                          style: BtnStyle.tonal, onTap: () async {
                        await Clipboard.setData(ClipboardData(text: buildMealPrompt()));
                        if (ctx.mounted) toast(ctx, 'تم نسخ البرومبت');
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PButton('لصق النتيجة', icon: Icons.content_paste,
                          style: BtnStyle.tonal, onTap: pasteResult),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              const Dim('اختر سريعاً:'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final pr in _presets)
                  Pill(pr[0] as String, onTap: () {
                    store.addFood(FoodEntry(
                        name: tr(pr[0] as String),
                        kcal: pr[1] as int,
                        protein: pr[2] as int,
                        carbs: pr[3] as int,
                        fat: pr[4] as int));
                    Navigator.pop(ctx);
                  }),
              ]),
              const SizedBox(height: 16),
              const Dim('أو أدخل يدوياً:'),
              const SizedBox(height: 8),
              TextField(controller: name, decoration: deco(ctx, 'اسم الوجبة')),
              const SizedBox(height: 10),
              Row(children: [
                numField(kcal, 'سعرات'),
                const SizedBox(width: 10),
                numField(prot, 'بروتين (غ)'),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                numField(carbs, 'كربوهيدرات (غ)'),
                const SizedBox(width: 10),
                numField(fat, 'دهون (غ)'),
              ]),
              LabeledRow('حفظ الوجبة لاستخدامها لاحقاً',
                  Switch(value: saveForLater, onChanged: (v) => setS(() => saveForLater = v))),
              const SizedBox(height: 6),
              PButton('حفظ', onTap: saveManual),
            ]),
      );
    });
  });
}
