// الاستيراد والتصدير: Excel و JSON + برومبت للذكاء الاصطناعي + نسخ احتياطي.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'catalog.dart';
import 'engine.dart';
import 'i18n.dart';
import 'models.dart';
import 'services.dart';
import 'store.dart';
import 'templates.dart';

// ======================= نتيجة الاستيراد =======================
class ImportResult {
  Plan? plan;
  final List<Exercise> exercises = [];
  Profile? profile;
  int? workoutMinutes;
  final List<String> errors = [];
  final List<String> warnings = [];
  bool get ok => errors.isEmpty && plan != null;
}

// ======================= تطبيع القيم =======================
String _normType(String s) {
  final t = s.toLowerCase().trim();
  if (t == 'time' || t == 'timed' || t == 'وقتي' || t == 'وقت' || t == 'مؤقت') {
    return 'time';
  }
  return 'reps';
}

String _normEquip(String s) {
  final t = s.toLowerCase().trim();
  if (t == 'weights' || t == 'weight' || t == 'بأوزان' || t == 'اوزان' || t == 'أوزان') {
    return 'weights';
  }
  if (t == 'calisthenics' || t == 'كاليسثنكس' || t == 'كاليستانيكس') {
    return 'calisthenics';
  }
  return 'bodyweight';
}

String _normRole(String s) {
  final t = s.toLowerCase().trim();
  if (t == 'warmup' || t == 'warm-up' || t == 'إحماء' || t == 'احماء') return 'warmup';
  if (t == 'cooldown' || t == 'cool-down' || t == 'تمدد' || t == 'stretch') {
    return 'cooldown';
  }
  return 'main';
}

String _normKind(String s) {
  final t = s.toLowerCase().trim();
  if (t == 'rest' || t == 'راحة' || t == 'استراحة') return 'rest';
  return 'train';
}

String _normGender(String s) {
  final t = s.toLowerCase().trim();
  if (t == 'female' || t == 'أنثى' || t == 'انثى' || t == 'f') return 'female';
  return 'male';
}

String _normGoal(String s) {
  final t = s.toLowerCase().trim();
  if (t == 'cut' || t == 'تنشيف' || t == 'تخسيس') return 'cut';
  if (t == 'maintain' || t == 'ثبات' || t == 'محافظة') return 'maintain';
  return 'bulk';
}

int? _parseTime(String s) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final mi = int.parse(m.group(2)!);
  if (h > 23 || mi > 59) return null;
  return h * 60 + mi;
}

Exercise? _catalogByName(String ref) {
  final q = ref.trim().toLowerCase();
  if (q.isEmpty) return null;
  for (final c in catalog.items) {
    if (c.nameEn.toLowerCase() == q || c.nameAr == ref.trim()) return c;
  }
  return null;
}

/// ينسخ من base كل ما هو فارغ في ex (تفاصيل الشرح فقط).
void _fillMissing(Exercise ex, Exercise base) {
  if (ex.nameEn.isEmpty) ex.nameEn = base.nameEn;
  if (ex.nameAr.isEmpty) ex.nameAr = base.nameAr;
  if (ex.emoji.isEmpty) ex.emoji = base.emoji;
  if (ex.youtube.isEmpty) ex.youtube = base.youtube;
  if (ex.link.isEmpty) ex.link = base.link;
  if (ex.level.isEmpty) ex.level = base.level;
  if (ex.muscles.isEmpty) ex.muscles = List.of(base.muscles);
  if (ex.secondary.isEmpty) ex.secondary = List.of(base.secondary);
  if (ex.stepsEn.isEmpty) ex.stepsEn = List.of(base.stepsEn);
  if (ex.stepsAr.isEmpty) ex.stepsAr = List.of(base.stepsAr);
  if (ex.tipsEn.isEmpty) ex.tipsEn = List.of(base.tipsEn);
  if (ex.tipsAr.isEmpty) ex.tipsAr = List.of(base.tipsAr);
  if (ex.images.isEmpty) ex.images = List.of(base.images);
  if (ex.src == 'custom' && base.src == 'catalog' && ex.stepsEn.isNotEmpty) {
    ex.src = base.src;
    ex.rev = base.rev;
  }
}

// ======================= الخطة -> Map (صيغة JSON) =======================
Map<String, dynamic> planToMap(Plan plan, List<Exercise> library,
    {bool includeProfile = true, bool includeSettings = true}) {
  final used = <String>{};
  for (final d in plan.dayTypes) {
    for (final it in d.items) {
      used.add(it.exerciseId);
    }
  }
  final exList = library.where((e) => used.contains(e.id)).toList();
  final wm = store.settings.workoutMinutes;
  return {
    'format': 'gym_plan_v1',
    'plan': {
      'name': plan.name,
      'totalDays': plan.totalDays,
      'startDate': dateKey(plan.startDate),
      'shiftOnMiss': plan.shiftOnMiss,
      'equipment': plan.equipment,
      'deloadEvery': plan.deloadEvery,
      'pattern': plan.pattern,
    },
    'dayTypes': plan.dayTypes
        .map((d) => {
              'id': d.id,
              'name': d.name,
              'kind': d.kind,
              'emoji': d.emoji,
              'items': d.items
                  .map((it) => {
                        'exercise': it.exerciseId,
                        'role': it.role,
                        'sets': it.sets,
                        'reps': it.reps,
                        'seconds': it.seconds,
                        'restSeconds': it.restSeconds,
                        'weight': it.weight,
                        'increment': it.increment,
                      })
                  .toList(),
            })
        .toList(),
    'exercises': exList.map((e) => e.toJson()).toList(),
    if (includeProfile) 'profile': store.data.profile.toJson(),
    if (includeSettings)
      'settings': {
        'workoutTime':
            '${(wm ~/ 60).toString().padLeft(2, '0')}:${(wm % 60).toString().padLeft(2, '0')}'
      },
  };
}

Map<String, dynamic> exampleMap() {
  final lib = defaultExercises();
  final plan = buildPlanFromTemplate(
    kTemplates.first,
    equipment: 'weights',
    totalDays: 100,
    startDate: store.today,
    warmup: false,
    stretch: false,
    shiftOnMiss: true,
    library: lib,
  );
  return planToMap(plan, lib, includeProfile: false, includeSettings: false)
    ..['profile'] = Profile(
            age: 25, gender: 'male', heightCm: 175, weightKg: 70, goal: 'bulk')
        .toJson()
    ..['settings'] = {'workoutTime': '18:00'};
}

// ======================= Map -> ImportResult =======================
ImportResult parsePlanMap(Map<String, dynamic> m) {
  final r = ImportResult();
  final planM = asMap(m['plan']);
  final dayList = asList(m['dayTypes'] ?? m['days']);
  final exList = asList(m['exercises']);

  // --- التمارين ---
  final lib = store.data.exercises;
  final fileEx = <String, Exercise>{};
  for (var i = 0; i < exList.length; i++) {
    final e = asMap(exList[i]);
    var name = toS(e['name']);
    if (name.isEmpty) name = toS(e['nameEn']);
    if (name.isEmpty) name = toS(e['nameAr']);
    if (name.isEmpty) {
      r.errors.add('التمرين رقم ${i + 1} في ورقة التمارين بلا اسم.');
      continue;
    }
    var id = toS(e['id']);
    if (id.isEmpty) {
      final found = lib.where((x) => x.name == name).toList();
      id = found.isNotEmpty ? found.first.id : newId();
    }
    final cat = toS(e['category']);
    final ex = Exercise.fromJson({
      ...e,
      'id': id,
      'name': name,
      'type': _normType(toS(e['type'])),
      'equipment': _normEquip(toS(e['equipment'])),
      'category': cat.isEmpty ? 'أخرى' : (kCatKeyToAr[cat.toLowerCase()] ?? cat),
    });
    if (ex.src == 'legacy') ex.src = 'custom';
    // ملف لا يحمل تفاصيل التمرين: أكمل الناقص من المكتبة أو الكتالوج
    final base = lib.where((x) => x.id == id).isNotEmpty
        ? lib.firstWhere((x) => x.id == id)
        : catalog.byId(id);
    if (base != null) _fillMissing(ex, base);
    if (fileEx.containsKey(id)) {
      r.warnings.add('المعرّف «$id» مكرر في ورقة التمارين، سيُستخدم الأخير.');
    }
    fileEx[id] = ex;
  }
  final byId = <String, Exercise>{for (final e in lib) e.id: e}..addAll(fileEx);
  final byName = <String, Exercise>{};
  for (final e in byId.values) {
    byName.putIfAbsent(e.name, () => e);
  }
  final catEx = <String, Exercise>{};
  Exercise? resolve(String ref) {
    final a = byId[ref] ?? byName[ref];
    if (a != null) return a;
    final c = catalog.byId(ref) ?? _catalogByName(ref);
    if (c != null) {
      catEx[c.id] = c;
      byId[c.id] = c;
      return c;
    }
    return null;
  }

  // --- أنواع الأيام ---
  if (dayList.isEmpty) {
    r.errors.add('لا توجد أنواع أيام (dayTypes / ورقة days).');
  }
  final types = <DayType>[];
  final usedEx = <String>{};
  for (var i = 0; i < dayList.length; i++) {
    final d = asMap(dayList[i]);
    final name = toS(d['name']);
    var id = toS(d['id']);
    if (id.isEmpty) id = name;
    if (id.isEmpty) {
      r.errors.add('نوع اليوم رقم ${i + 1} بلا id ولا اسم.');
      continue;
    }
    if (types.any((t) => t.id == id)) {
      r.errors.add('معرّف نوع اليوم «$id» مكرر.');
      continue;
    }
    final kind = _normKind(toS(d['kind']));
    final dt = DayType(
      id: id,
      name: name.isEmpty ? id : name,
      kind: kind,
      emoji: toS(d['emoji']).isEmpty ? (kind == 'rest' ? '😴' : '💪') : toS(d['emoji']),
    );
    final its = asList(d['items']);
    for (var j = 0; j < its.length; j++) {
      final it = asMap(its[j]);
      final ref = toS(it['exercise'] ?? it['exerciseId'] ?? it['name']);
      final where = 'اليوم «${dt.name}» العنصر ${j + 1}';
      if (ref.isEmpty) {
        r.errors.add('$where: لم يُحدَّد التمرين.');
        continue;
      }
      final ex = resolve(ref);
      if (ex == null) {
        r.errors.add('$where: التمرين «$ref» غير معرّف في ورقة التمارين ولا في مكتبتك.');
        continue;
      }
      usedEx.add(ex.id);
      final role = _normRole(toS(it['role']));
      var sets = toI(it['sets'], 3);
      if (sets < 1 || sets > 30) {
        r.warnings.add('$where: عدد المجموعات $sets غير منطقي، استُخدم 3.');
        sets = 3;
      }
      var reps = toI(it['reps'], 0);
      var secs = toI(it['seconds'], 0);
      if (ex.isTime) {
        if (secs <= 0) {
          secs = 30;
          r.warnings.add('$where («${ex.name}» وقتي): لم تُحدَّد المدة، استُخدم 30 ثانية.');
        }
        reps = 0;
      } else {
        if (reps <= 0) {
          reps = 10;
          r.warnings.add('$where («${ex.name}»): لم تُحدَّد العدات، استُخدم 10.');
        }
        secs = 0;
      }
      final restDefault = role == 'main' ? 90 : 10;
      final rest = toI(it['restSeconds'] ?? it['rest'], restDefault);
      dt.items.add(PlanItem(
        exerciseId: ex.id,
        role: role,
        sets: sets,
        reps: reps,
        seconds: secs,
        restSeconds: clampI(rest, 0, 900),
        weight: ex.usesWeight ? toD(it['weight'], 0).clamp(0, 1000).toDouble() : 0,
        increment: ex.usesWeight ? toD(it['increment'], 0).clamp(0, 50).toDouble() : 0,
      ));
    }
    types.add(dt);
  }

  // --- النمط ---
  List<String> rawPattern;
  final pv = planM['pattern'];
  if (pv is List) {
    rawPattern = pv.map((e) => toS(e)).toList();
  } else {
    rawPattern =
        toS(pv).split(RegExp(r'[,،;؛\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  final pattern = <String>[];
  for (final ref in rawPattern) {
    DayType? f;
    for (final t in types) {
      if (t.id == ref) f = t;
    }
    if (f == null) {
      for (final t in types) {
        if (t.name == ref) f = t;
      }
    }
    if (f == null) {
      r.errors.add('النمط يحتوي «$ref» وهو غير موجود في أنواع الأيام.');
    } else {
      pattern.add(f.id);
    }
  }
  if (rawPattern.isEmpty) r.errors.add('نمط الأسبوع (pattern) فارغ.');
  if (pattern.isNotEmpty &&
      !pattern.any((id) => !types.firstWhere((t) => t.id == id).isRest)) {
    r.errors.add('النمط لا يحتوي أي يوم تمرين.');
  }
  for (final id in pattern.toSet()) {
    final t = types.firstWhere((x) => x.id == id);
    if (!t.isRest && t.items.isEmpty) {
      r.warnings.add('يوم «${t.name}» بلا تمارين.');
    }
  }

  // --- الخطة ---
  var total = toI(planM['totalDays'], 100);
  if (total < 1 || total > 2000) {
    r.warnings.add('مدة الخطة $total خارج المدى (1–2000)، استُخدم 100.');
    total = 100;
  }
  DateTime start = store.today;
  final sd = toS(planM['startDate']);
  if (sd.isNotEmpty) {
    final parsed = tryParseKey(sd);
    if (parsed == null) {
      r.warnings.add('تاريخ البداية «$sd» غير مفهوم (استخدم yyyy-mm-dd)، استُخدم تاريخ اليوم.');
    } else {
      start = parsed;
    }
  }
  if (r.errors.isEmpty && types.isNotEmpty && pattern.isNotEmpty) {
    r.plan = Plan(
      id: newId(),
      name: toS(planM['name'], 'خطة مستوردة'),
      totalDays: total,
      startDate: dateOnly(start),
      pattern: pattern,
      dayTypes: types,
      equipment: _normEquip(toS(planM['equipment'], 'weights')),
      shiftOnMiss: toB(planM['shiftOnMiss'], true),
      deloadEvery: clampI(toI(planM['deloadEvery'], 0), 0, 12),
    );
  }
  // التمارين التي تُضاف/تُحدَّث في المكتبة
  for (final id in usedEx) {
    final e = fileEx[id] ?? catEx[id];
    if (e != null) r.exercises.add(e);
  }
  for (final e in fileEx.values) {
    if (!usedEx.contains(e.id)) r.exercises.add(e);
  }

  // --- الجسم والإعدادات ---
  final pm = m['profile'];
  if (pm is Map) {
    final pj = asMap(pm);
    final pr = Profile(
      age: toI(pj['age'], 0),
      gender: _normGender(toS(pj['gender'])),
      heightCm: toD(pj['heightCm'] ?? pj['height'], 0),
      weightKg: toD(pj['weightKg'] ?? pj['weight'], 0),
      goal: _normGoal(toS(pj['goal'])),
      activity: toD(pj['activity'], 1.55),
      waterGoalL: pj['waterGoalL'] == null || toS(pj['waterGoalL']).isEmpty
          ? null
          : toD(pj['waterGoalL']),
      kcalGoal: pj['kcalGoal'] == null || toS(pj['kcalGoal']).isEmpty
          ? null
          : toI(pj['kcalGoal']),
      proteinGoal: pj['proteinGoal'] == null || toS(pj['proteinGoal']).isEmpty
          ? null
          : toI(pj['proteinGoal']),
    );
    if (pr.age > 0 || pr.heightCm > 0 || pr.weightKg > 0) {
      if (pr.age < 10 || pr.age > 100) {
        r.warnings.add('العمر ${pr.age} غير منطقي، تجاهلنا معلومات الجسم.');
      } else if (pr.heightCm < 100 || pr.heightCm > 250) {
        r.warnings.add('الطول ${fmtNum(pr.heightCm)} غير منطقي، تجاهلنا معلومات الجسم.');
      } else if (pr.weightKg < 30 || pr.weightKg > 300) {
        r.warnings.add('الوزن ${fmtNum(pr.weightKg)} غير منطقي، تجاهلنا معلومات الجسم.');
      } else {
        r.profile = pr;
      }
    }
  }
  final sm = m['settings'];
  if (sm is Map) {
    final t = _parseTime(toS(asMap(sm)['workoutTime']));
    if (t != null) r.workoutMinutes = t;
  }
  return r;
}

void applyImport(ImportResult r) {
  if (!r.ok) return;
  for (final e in r.exercises) {
    store.upsertExercise(e);
  }
  if (r.profile != null) {
    final old = store.data.profile;
    final n = r.profile!;
    if (n.age > 0) old.age = n.age;
    old.gender = n.gender;
    if (n.heightCm > 0) old.heightCm = n.heightCm;
    if (n.weightKg > 0) old.weightKg = n.weightKg;
    old.goal = n.goal;
    old.activity = n.activity;
    old.waterGoalL = n.waterGoalL;
    old.kcalGoal = n.kcalGoal;
    old.proteinGoal = n.proteinGoal;
  }
  if (r.workoutMinutes != null) store.settings.workoutMinutes = r.workoutMinutes!;
  store.addPlan(r.plan!);
}

// ======================= قراءة نص الذكاء الاصطناعي =======================
ImportResult parseImportText(String text) {
  var t = text.trim();
  t = t.replaceAll('```json', '').replaceAll('```JSON', '').replaceAll('```', '');
  final a = t.indexOf('{');
  final b = t.lastIndexOf('}');
  final r = ImportResult();
  if (a < 0 || b <= a) {
    r.errors.add('لم أجد JSON في النص. انسخ رد الذكاء الاصطناعي كاملاً.');
    return r;
  }
  try {
    final j = jsonDecode(t.substring(a, b + 1));
    if (j is! Map) {
      r.errors.add('الرد ليس كائن JSON صالحاً.');
      return r;
    }
    return parsePlanMap(Map<String, dynamic>.from(j));
  } catch (e) {
    r.errors.add('تعذرت قراءة JSON: $e');
    return r;
  }
}

// ======================= قراءة الملفات =======================
Future<ImportResult> parseImportBytes(Uint8List bytes, String fileName) async {
  final lower = fileName.toLowerCase();
  try {
    if (lower.endsWith('.json')) {
      final j = jsonDecode(utf8.decode(bytes));
      if (j is! Map) {
        final r = ImportResult();
        r.errors.add('ملف JSON يجب أن يكون كائناً {...} وليس قائمة.');
        return r;
      }
      return parsePlanMap(Map<String, dynamic>.from(j));
    }
    if (lower.endsWith('.xlsx')) {
      final x = Excel.decodeBytes(bytes);
      return parsePlanMap(_excelToMap(x));
    }
  } catch (e) {
    final r = ImportResult();
    r.errors.add('تعذرت قراءة الملف: $e');
    return r;
  }
  final r = ImportResult();
  r.errors.add('صيغة غير مدعومة. استخدم ملف .xlsx أو .json');
  return r;
}

String _cellText(Data? d) {
  final v = d?.value;
  if (v == null) return '';
  if (v is IntCellValue) return '${v.value}';
  if (v is DoubleCellValue) {
    final x = v.value;
    return x == x.roundToDouble() ? '${x.toInt()}' : '$x';
  }
  if (v is BoolCellValue) return '${v.value}';
  if (v is TextCellValue) {
    final dynamic t = v.value;
    if (t is String) return t.trim();
    try {
      return (t.toPlainText() as String).trim();
    } catch (_) {
      return '$t'.trim();
    }
  }
  return v.toString().trim();
}

Sheet? _sheet(Excel x, String name) {
  for (final k in x.tables.keys) {
    if (k.trim().toLowerCase() == name) return x.tables[k];
  }
  return null;
}

List<Map<String, String>> _table(Excel x, String name) {
  final s = _sheet(x, name);
  if (s == null) return [];
  final rows = s.rows;
  if (rows.isEmpty) return [];
  final header = rows.first.map((c) => _cellText(c).toLowerCase()).toList();
  final out = <Map<String, String>>[];
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final m = <String, String>{};
    var any = false;
    for (var c = 0; c < header.length; c++) {
      if (header[c].isEmpty) continue;
      final v = c < row.length ? _cellText(row[c]) : '';
      if (v.isNotEmpty) any = true;
      m[header[c]] = v;
    }
    if (any) out.add(m);
  }
  return out;
}

Map<String, String> _kv(Excel x, String name) {
  final s = _sheet(x, name);
  final out = <String, String>{};
  if (s == null) return out;
  for (final row in s.rows) {
    if (row.length < 2) continue;
    final k = _cellText(row[0]);
    if (k.isEmpty || k.toLowerCase() == 'key') continue;
    out[k] = _cellText(row[1]);
  }
  return out;
}

Map<String, dynamic> _excelToMap(Excel x) {
  final plan = _kv(x, 'plan');
  final prof = _kv(x, 'profile');
  final days = _table(x, 'days');
  final exs = _table(x, 'exercises');
  final sched = _table(x, 'schedule');

  final dayMaps = <Map<String, dynamic>>[];
  for (final d in days) {
    dayMaps.add({
      'id': d['id'] ?? '',
      'name': d['name'] ?? '',
      'kind': d['kind'] ?? '',
      'emoji': d['emoji'] ?? '',
      'items': <Map<String, dynamic>>[],
    });
  }
  for (final s in sched) {
    final key = s['day'] ?? '';
    Map<String, dynamic>? target;
    for (final d in dayMaps) {
      if (d['id'] == key || d['name'] == key) target = d;
    }
    if (target == null) {
      // يوم غير معرّف: ننشئه تلقائياً كي يظهر الخطأ بوضوح بدل التجاهل الصامت
      target = {'id': key, 'name': key, 'kind': 'train', 'emoji': '', 'items': <Map<String, dynamic>>[]};
      dayMaps.add(target);
    }
    (target['items'] as List).add({
      'exercise': s['exercise'] ?? '',
      'role': s['role'] ?? '',
      'sets': s['sets'] ?? '',
      'reps': s['reps'] ?? '',
      'seconds': s['seconds'] ?? '',
      'restSeconds': s['restseconds'] ?? s['rest'] ?? '',
      'weight': s['weight'] ?? '',
      'increment': s['increment'] ?? '',
    });
  }
  return {
    'plan': {
      'name': plan['name'] ?? '',
      'totalDays': plan['totalDays'] ?? plan['totaldays'] ?? '',
      'startDate': plan['startDate'] ?? plan['startdate'] ?? '',
      'shiftOnMiss': plan['shiftOnMiss'] ?? plan['shiftonmiss'] ?? '',
      'equipment': plan['equipment'] ?? '',
      'deloadEvery': plan['deloadEvery'] ?? plan['deloadevery'] ?? '',
      'pattern': plan['pattern'] ?? '',
    },
    'dayTypes': dayMaps,
    'exercises': exs,
    'profile': {
      'age': prof['age'],
      'gender': prof['gender'],
      'heightCm': prof['heightCm'] ?? prof['heightcm'],
      'weightKg': prof['weightKg'] ?? prof['weightkg'],
      'goal': prof['goal'],
      'activity': prof['activity'],
      'waterGoalL': prof['waterGoalL'] ?? prof['watergoall'],
      'kcalGoal': prof['kcalGoal'] ?? prof['kcalgoal'],
      'proteinGoal': prof['proteinGoal'] ?? prof['proteingoal'],
    },
    'settings': {'workoutTime': plan['workoutTime'] ?? plan['workouttime'] ?? ''},
  };
}

// ======================= كتابة Excel =======================
CellValue? _cv(dynamic v) {
  if (v == null) return null;
  if (v is int) return IntCellValue(v);
  if (v is double) return DoubleCellValue(v);
  if (v is bool) return TextCellValue(v ? 'true' : 'false');
  return TextCellValue('$v');
}

List<int> mapToExcelBytes(Map<String, dynamic> m) {
  final x = Excel.createExcel();
  void put(String name, List<List<dynamic>> rows) {
    final s = x[name];
    for (final r in rows) {
      s.appendRow(r.map(_cv).toList());
    }
  }

  put('README', _readmeRows());

  final plan = asMap(m['plan']);
  final wt = toS(asMap(m['settings'])['workoutTime']);
  put('plan', [
    ['key', 'value'],
    ['name', plan['name']],
    ['totalDays', plan['totalDays']],
    ['startDate', plan['startDate']],
    ['shiftOnMiss', plan['shiftOnMiss'] == true ? 'true' : 'false'],
    ['equipment', plan['equipment']],
    ['deloadEvery', plan['deloadEvery']],
    ['pattern', asList(plan['pattern']).map((e) => '$e').join(',')],
    ['workoutTime', wt],
  ]);

  final days = asList(m['dayTypes']).map((e) => asMap(e)).toList();
  put('days', [
    ['id', 'name', 'kind', 'emoji'],
    for (final d in days) [d['id'], d['name'], d['kind'], d['emoji']],
  ]);

  final exs = asList(m['exercises']).map((e) => asMap(e)).toList();
  put('exercises', [
    ['id', 'name', 'emoji', 'category', 'type', 'equipment', 'youtube', 'notes'],
    for (final e in exs)
      [e['id'], e['name'], e['emoji'], e['category'], e['type'], e['equipment'], e['youtube'], e['notes']],
  ]);

  final sched = <List<dynamic>>[
    ['day', 'exercise', 'role', 'sets', 'reps', 'seconds', 'restSeconds', 'weight', 'increment'],
  ];
  for (final d in days) {
    for (final it in asList(d['items']).map((e) => asMap(e))) {
      sched.add([
        d['id'],
        it['exercise'],
        it['role'],
        it['sets'],
        it['reps'],
        it['seconds'],
        it['restSeconds'],
        it['weight'],
        it['increment'],
      ]);
    }
  }
  put('schedule', sched);

  final pr = asMap(m['profile']);
  put('profile', [
    ['key', 'value'],
    ['age', pr['age']],
    ['gender', pr['gender']],
    ['heightCm', pr['heightCm']],
    ['weightKg', pr['weightKg']],
    ['goal', pr['goal']],
    ['activity', pr['activity']],
    ['waterGoalL', pr['waterGoalL']],
    ['kcalGoal', pr['kcalGoal']],
    ['proteinGoal', pr['proteinGoal']],
  ]);

  if (x.tables.containsKey('Sheet1')) x.delete('Sheet1');
  return x.encode() ?? <int>[];
}

List<List<dynamic>> _readmeRows() => [
      ['تعليمات تعبئة ملف الخطة'],
      [''],
      ['الأوراق: plan (إعدادات الخطة) • days (أنواع الأيام) • exercises (التمارين) • schedule (تمارين كل يوم) • profile (معلومات الجسم)'],
      ['لا تغيّر أسماء الأوراق ولا عناوين الأعمدة (الصف الأول). عبّئ القيم فقط.'],
      [''],
      ['plan: pattern = أرقام/معرّفات أنواع الأيام مفصولة بفاصلة وتتكرر طوال الخطة. مثال: upper,rest,lower,rest'],
      ['plan: startDate بصيغة 2026-10-12 (اكتبها كنص). shiftOnMiss = true أو false. workoutTime مثل 18:00'],
      ['days: kind = train أو rest. id معرّف قصير بالإنجليزية بدون مسافات (مثل upper).'],
      ['exercises: type = reps (عدات) أو time (وقتي مثل البلانك). equipment = weights أو bodyweight أو calisthenics'],
      ['exercises: category مثل: صدر، ظهر، أكتاف، ذراعين، أرجل، بطن، كارديو، إحماء، تمدد. youtube رابط اختياري.'],
      ['schedule: day = id اليوم. exercise = id التمرين. role = warmup أو main أو cooldown.'],
      ['schedule: للتمرين بالعدات املأ reps، وللوقتي املأ seconds. weight/increment للتمارين بأوزان فقط.'],
      ['profile: gender = male أو female. goal = bulk (تضخيم) أو cut (تنشيف) أو maintain. activity بين 1.2 و 1.9'],
      ['يمكنك إرسال هذا الملف لذكاء اصطناعي أو مدرب ليعبئه، ثم تستورده من التطبيق.'],
    ];

// ======================= برومبت الذكاء الاصطناعي =======================
String _catalogListing() {
  final b = StringBuffer();
  final raw = catalog.data?.raw ?? const <Map<String, dynamic>>[];
  for (final e in raw) {
    b.writeln(
        '${toS(e['id'])} = ${toS(e['nameEn'])} [${toS(e['category'])}, ${toS(e['equipment'])}, ${toS(e['type'])}, ${toS(e['level'])}]');
  }
  final catIds = {for (final e in raw) toS(e['id'])};
  for (final e in store.data.exercises) {
    if (catIds.contains(e.id)) continue;
    b.writeln(
        '${e.id} = ${e.nameEn.isNotEmpty ? e.nameEn : e.name} [${e.category}, ${e.equipment}, ${e.type}] (my own exercise)');
  }
  return b.toString().trimRight();
}

/// request: وصف المستخدم لما يريده (أيام، أهداف، معدات، إصابات...).
String buildAiPrompt({String request = ''}) {
  final lib = _catalogListing();
  final req = request.trim().isEmpty
      ? t2('(اكتب هنا: عمري، وزني، هدفي، المعدات المتوفرة، عدد أيام التمرين في الأسبوع، أي إصابات...)',
          '(write here: my age, weight, goal, available equipment, training days per week, any injuries...)')
      : request.trim();
  final example = const JsonEncoder.withIndent('  ').convert(_aiExample);
  if (isAr) {
    return '''أنت مدرب لياقة محترف. صمّم لي خطة تمارين لبناء العضلات واختر التمارين من «كتالوج التطبيق» أدناه فقط، وأعد الخطة بصيغة JSON فقط (بدون أي شرح خارج الـJSON وبدون علامات ```).

طلبي:
$req

القواعد:
1) المفاتيح بالإنكليزية بالضبط كما في المثال. القيم النصية مثل اسم الخطة يمكن أن تكون بالعربية.
2) استخدم في كل item معرّف التمرين (id) من الكتالوج في الحقل "exercise". لا تخترع معرّفات. اترك "exercises" قائمة فارغة إلا إذا اضطررت لتمرين غير موجود، فعرّفه فيها بالحقول: id, nameEn, nameAr, category, type, equipment, emoji (اختياري), video (رابط يوتيوب اختياري).
3) plan.pattern قائمة معرّفات أنواع الأيام وتتكرر طوال مدة الخطة، وكل نوع يوم تعرّفه في dayTypes.
4) type = "reps" للتمارين بالعدات (املأ reps) أو "time" للوقتية (املأ seconds). weight/increment بالكيلوغرام للتمارين بأوزان فقط وإلا 0.
5) role: "warmup" إحماء، "main" أساسي، "cooldown" تمدد. يوم الراحة: "kind": "rest" و"items": [].
6) اجعل الأوزان والعدات واقعية للمبتدئ ثم تتدرج، وضع increment صغيراً مناسباً. ابدأ كل يوم تمرين بإحماء وأنهِه بتمدد.
7) totalDays عدد أيام الخطة، startDate بصيغة yyyy-mm-dd، وworkoutTime مثل 18:00.

كتالوج التمارين المتاح (id = الاسم [القسم، المعدات، النوع، المستوى]):
$lib

صيغة المثال:
$example
''';
  }
  return '''You are a professional fitness coach. Design a muscle-building workout plan for me, choosing exercises ONLY from the app catalog below, and reply with JSON only (no text outside the JSON and no ``` fences).

My request:
$req

Rules:
1) Keys are in English exactly as in the example. Text values such as the plan name may be in any language.
2) In every item, put the catalog exercise id in the "exercise" field. Do not invent ids. Leave "exercises" as an empty list unless you really need an exercise that is not in the catalog; then define it there with: id, nameEn, nameAr, category, type, equipment, emoji (optional), video (optional YouTube link).
3) plan.pattern is a list of day-type ids that repeats for the whole plan; define each day type in dayTypes.
4) type = "reps" for rep-based exercises (fill reps) or "time" for timed ones (fill seconds). weight/increment are in kg for weighted exercises only, otherwise 0.
5) role: "warmup", "main" or "cooldown". A rest day is "kind": "rest" with "items": [].
6) Keep weights and reps realistic for a beginner, then progress; use a small sensible increment. Start every training day with a warm-up and end with a stretch.
7) totalDays is the plan length, startDate is yyyy-mm-dd, workoutTime like 18:00.

Available exercise catalog (id = name [category, equipment, type, level]):
$lib

Example format:
$example
''';
}

const Map<String, dynamic> _aiExample = {
  'format': 'gym_plan_v1',
  'plan': {
    'name': 'Plan name',
    'totalDays': 100,
    'startDate': '2026-10-12',
    'shiftOnMiss': true,
    'equipment': 'weights',
    'deloadEvery': 0,
    'pattern': ['upper', 'rest', 'lower', 'rest'],
  },
  'dayTypes': [
    {
      'id': 'upper',
      'name': 'Upper',
      'kind': 'train',
      'emoji': '💪',
      'items': [
        {
          'exercise': 'wu_arm',
          'role': 'warmup',
          'sets': 1,
          'reps': 0,
          'seconds': 30,
          'restSeconds': 10,
          'weight': 0,
          'increment': 0
        },
        {
          'exercise': 'db_bench',
          'role': 'main',
          'sets': 4,
          'reps': 10,
          'seconds': 0,
          'restSeconds': 90,
          'weight': 14,
          'increment': 2
        },
        {
          'exercise': 'plank',
          'role': 'main',
          'sets': 3,
          'reps': 0,
          'seconds': 45,
          'restSeconds': 45,
          'weight': 0,
          'increment': 0
        },
        {
          'exercise': 'st_chest',
          'role': 'cooldown',
          'sets': 1,
          'reps': 0,
          'seconds': 30,
          'restSeconds': 10,
          'weight': 0,
          'increment': 0
        }
      ]
    },
    {'id': 'lower', 'name': 'Lower', 'kind': 'train', 'emoji': '🦵', 'items': []},
    {'id': 'rest', 'name': 'Rest', 'kind': 'rest', 'emoji': '😴', 'items': []}
  ],
  'exercises': [],
  'profile': {
    'age': 25,
    'gender': 'male',
    'heightCm': 175,
    'weightKg': 70,
    'goal': 'bulk',
    'activity': 1.55
  },
  'settings': {'workoutTime': '18:00'}
};

// ======================= مشاركة الملفات =======================
Future<void> _shareBytes(List<int> bytes, String name, String mime, String subject) async {
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$name');
  await f.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles([XFile(f.path, mimeType: mime)], subject: subject);
}

const _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

Future<void> exportPlanExcel(Plan plan) async {
  final bytes = mapToExcelBytes(planToMap(plan, store.data.exercises));
  await _shareBytes(bytes, 'plan_${dateKey(store.today)}.xlsx', _xlsxMime, 'خطة التمارين');
}

Future<void> exportPlanJson(Plan plan) async {
  final txt = const JsonEncoder.withIndent('  ')
      .convert(planToMap(plan, store.data.exercises));
  await _shareBytes(utf8.encode(txt), 'plan_${dateKey(store.today)}.json',
      'application/json', 'خطة التمارين');
}

Future<void> exportTemplateExcel() async {
  final bytes = mapToExcelBytes(exampleMap());
  await _shareBytes(bytes, 'plan_template.xlsx', _xlsxMime, 'قالب خطة تمارين');
}

Future<void> exportBackup() async {
  await store.flush();
  final txt = jsonEncode(store.data.toJson());
  await _shareBytes(utf8.encode(txt), 'gym_backup_${dateKey(store.today)}.json',
      'application/json', 'نسخة احتياطية - تمريني');
}

/// يعيد رسالة نجاح/فشل.
String restoreBackupFromBytes(Uint8List bytes) {
  try {
    final j = jsonDecode(utf8.decode(bytes));
    if (j is! Map || toS(j['kind']) != 'gym_backup') {
      return 'هذا ليس ملف نسخة احتياطية من التطبيق.';
    }
    store.restoreBackup(Map<String, dynamic>.from(j));
    return 'تمت استعادة النسخة الاحتياطية.';
  } catch (e) {
    return 'تعذرت قراءة النسخة: $e';
  }
}

Future<void> afterImportRefresh() async {
  await Notifier.reschedule();
}
