// برومبت تحليل الوجبة بالذكاء الاصطناعي + قراءة النتيجة.
import 'dart:convert';

import 'i18n.dart';
import 'models.dart';

class MealResult {
  final String name;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final String notes;
  const MealResult(this.name, this.kcal, this.protein, this.carbs, this.fat, this.notes);
}

String buildMealPrompt() {
  if (isAr) {
    return '''حلّل صورة الوجبة المرفقة وقدّر قيمها الغذائية للكمية الظاهرة في الصورة.
أجب بـ JSON فقط، بدون أي شرح وبدون علامات ```، وبهذا الشكل بالضبط:
{
  "format": "gym_meal_v1",
  "name": "اسم الوجبة (قصير)",
  "kcal": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "items": [{"name": "المكوّن", "grams": 0, "kcal": 0}],
  "notes": "ملاحظة قصيرة عن دقة التقدير"
}
القواعد:
- كل الأرقام أعداد صحيحة لكامل الوجبة الظاهرة: kcal سعرات حرارية، وprotein وcarbs وfat بالغرام.
- المفاتيح بالإنكليزية كما هي، واسم الوجبة بالعربية.
- إن لم تكن متأكداً من الكمية فخمّن تقديراً معقولاً واذكر ذلك في notes.
ملاحظاتي عن الوجبة (اختياري): ...''';
  }
  return '''Analyze the attached photo of my meal and estimate its nutrition for the portion shown.
Reply with JSON only, no explanation and no ``` fences, exactly in this shape:
{
  "format": "gym_meal_v1",
  "name": "short meal name",
  "kcal": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "items": [{"name": "ingredient", "grams": 0, "kcal": 0}],
  "notes": "one short note about how accurate the estimate is"
}
Rules:
- All numbers are whole numbers for the whole visible meal: kcal = calories, protein / carbs / fat in grams.
- Keep the keys in English exactly as shown.
- If unsure about the portion, make a reasonable estimate and say so in notes.
My notes about the meal (optional): ...''';
}

int _num(dynamic v) {
  if (v is num) return v.isFinite ? v.round() : 0;
  final m = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch('$v');
  if (m == null) return 0;
  return (double.tryParse(m.group(0)!.replaceAll(',', '.')) ?? 0).round();
}

String _pickKey(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    for (final e in m.entries) {
      if (e.key.toLowerCase() == k) return e.key;
    }
  }
  return '';
}

/// يقرأ رد الذكاء الاصطناعي (حتى لو أحاط JSON بنص أو علامات ```). يعيد null عند الفشل.
MealResult? parseMealText(String text) {
  var t = text.trim();
  if (t.isEmpty) return null;
  t = t.replaceAll('```json', '').replaceAll('```JSON', '').replaceAll('```', '');
  final a = t.indexOf('{');
  final b = t.lastIndexOf('}');
  if (a < 0 || b <= a) return null;
  dynamic j;
  try {
    j = jsonDecode(t.substring(a, b + 1));
  } catch (_) {
    return null;
  }
  if (j is! Map) return null;
  final m = Map<String, dynamic>.from(j);
  int get(List<String> keys) {
    final k = _pickKey(m, keys);
    return k.isEmpty ? 0 : _num(m[k]);
  }

  final kcal = get(['kcal', 'calories', 'cal', 'energy']);
  final protein = get(['protein', 'proteins']);
  final carbs = get(['carbs', 'carbohydrates', 'carbohydrate']);
  final fat = get(['fat', 'fats']);
  final nameKey = _pickKey(m, ['name', 'meal', 'title']);
  final notesKey = _pickKey(m, ['notes', 'note']);
  if (kcal <= 0 && protein <= 0 && carbs <= 0 && fat <= 0) return null;
  // إن غابت السعرات احسبها من الماكروز
  final k = kcal > 0 ? kcal : protein * 4 + carbs * 4 + fat * 9;
  return MealResult(
    nameKey.isEmpty ? '' : toS(m[nameKey]),
    k,
    protein,
    carbs,
    fat,
    notesKey.isEmpty ? '' : toS(m[notesKey]),
  );
}
