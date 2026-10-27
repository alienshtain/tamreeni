// النماذج: كل البيانات تُحفظ كملف JSON واحد على الهاتف.
import 'i18n.dart';

int _idc = 0;
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_idc++).toRadixString(36)}';

// ---------- أدوات التاريخ والتحويل ----------
int clampI(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? tryParseKey(String? k) {
  if (k == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(k.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  return DateTime(y, mo, d);
}

DateTime parseKey(String k) => tryParseKey(k) ?? dateOnly(DateTime.now());

double toD(dynamic v, [double def = 0]) {
  if (v is num) return v.toDouble();
  if (v == null) return def;
  return double.tryParse('$v'.trim().replaceAll(',', '.')) ?? def;
}

int toI(dynamic v, [int def = 0]) {
  if (v is num) return v.isFinite ? v.round() : def;
  if (v == null) return def;
  final d = double.tryParse('$v'.trim().replaceAll(',', '.'));
  if (d == null || !d.isFinite) return def;
  return d.round();
}

String toS(dynamic v, [String def = '']) => v == null ? def : '$v'.trim();

bool toB(dynamic v, [bool def = false]) {
  if (v is bool) return v;
  if (v == null) return def;
  final s = '$v'.toLowerCase().trim();
  if (const ['true', 'yes', 'y', '1', 'نعم'].contains(s)) return true;
  if (const ['false', 'no', 'n', '0', 'لا'].contains(s)) return false;
  return def;
}

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<dynamic> asList(dynamic v) => v is List ? v : <dynamic>[];

// ---------- ثوابت ----------
const kCategories = [
  'صدر',
  'ظهر',
  'أكتاف',
  'ذراعين',
  'أرجل',
  'بطن',
  'كارديو',
  'إحماء',
  'تمدد',
  'أخرى'
];
const kCatKeyToAr = {
  'chest': 'صدر',
  'back': 'ظهر',
  'shoulders': 'أكتاف',
  'arms': 'ذراعين',
  'legs': 'أرجل',
  'abs': 'بطن',
  'cardio': 'كارديو',
  'warmup': 'إحماء',
  'stretch': 'تمدد',
  'other': 'أخرى',
};
const kEquipLabels = {
  'weights': 'بأوزان',
  'bodyweight': 'بدون أوزان',
  'calisthenics': 'كاليسثنكس',
};
const kRoleLabels = {
  'warmup': 'إحماء',
  'main': 'أساسي',
  'cooldown': 'تمدد',
};

// ---------- التمرين (مكتبة) ----------
List<String> _strList(dynamic v) =>
    asList(v).map((e) => toS(e)).where((e) => e.isNotEmpty).toList();

class Exercise {
  String id;
  String name; // الاسم الأساسي (قد يكون عربياً أو إنكليزياً)
  String nameEn;
  String nameAr;
  String emoji; // فارغ = تُعرض صورة توضيحية أو أيقونة القسم
  String category;
  String type; // reps | time
  String equipment; // weights | bodyweight | calisthenics
  String youtube; // رابط فيديو الشرح
  String link; // رابط صفحة شرح
  String notes;
  String level; // beginner | intermediate | advanced | ''
  List<String> muscles;
  List<String> secondary;
  List<String> stepsEn;
  List<String> stepsAr;
  List<String> tipsEn;
  List<String> tipsAr;
  List<String> images; // روابط كاملة
  String src; // catalog | custom
  bool edited; // عدّله المستخدم يدوياً (لا يُستبدل عند تحديث الكتالوج)
  int rev;

  Exercise({
    required this.id,
    required this.name,
    this.nameEn = '',
    this.nameAr = '',
    this.emoji = '',
    this.category = 'أخرى',
    this.type = 'reps',
    this.equipment = 'bodyweight',
    this.youtube = '',
    this.link = '',
    this.notes = '',
    this.level = '',
    List<String>? muscles,
    List<String>? secondary,
    List<String>? stepsEn,
    List<String>? stepsAr,
    List<String>? tipsEn,
    List<String>? tipsAr,
    List<String>? images,
    this.src = 'custom',
    this.edited = false,
    this.rev = 0,
  })  : muscles = muscles ?? [],
        secondary = secondary ?? [],
        stepsEn = stepsEn ?? [],
        stepsAr = stepsAr ?? [],
        tipsEn = tipsEn ?? [],
        tipsAr = tipsAr ?? [],
        images = images ?? [];

  bool get isTime => type == 'time';
  bool get usesWeight => equipment == 'weights';
  bool get fromCatalog => src == 'catalog';

  /// الاسم المعروض: بالعربية «الاسم العربي (English)» وبالإنكليزية الاسم الإنكليزي.
  String get title {
    if (isAr) {
      if (nameAr.isNotEmpty) {
        return nameEn.isNotEmpty && nameEn != nameAr ? '$nameAr ($nameEn)' : nameAr;
      }
      return name;
    }
    if (nameEn.isNotEmpty) return nameEn;
    return tr(name);
  }

  List<String> get steps {
    final a = isAr ? stepsAr : stepsEn;
    final b = isAr ? stepsEn : stepsAr;
    return a.isNotEmpty ? a : b;
  }

  List<String> get tips {
    final a = isAr ? tipsAr : tipsEn;
    final b = isAr ? tipsEn : tipsAr;
    return a.isNotEmpty ? a : b;
  }

  bool get hasDetails =>
      steps.isNotEmpty ||
      tips.isNotEmpty ||
      muscles.isNotEmpty ||
      youtube.isNotEmpty ||
      link.isNotEmpty ||
      images.isNotEmpty ||
      notes.isNotEmpty;

  Exercise copy() => Exercise.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'emoji': emoji,
        'category': category,
        'type': type,
        'equipment': equipment,
        'youtube': youtube,
        'link': link,
        'notes': notes,
        'level': level,
        'muscles': muscles,
        'secondary': secondary,
        'stepsEn': stepsEn,
        'stepsAr': stepsAr,
        'tipsEn': tipsEn,
        'tipsAr': tipsAr,
        'images': images,
        'src': src,
        'edited': edited,
        'rev': rev,
      };

  factory Exercise.fromJson(Map<String, dynamic> j) {
    final hasSrc = j.containsKey('src');
    return Exercise(
      id: toS(j['id'], newId()),
      name: toS(j['name'], toS(j['nameEn'], toS(j['nameAr'], 'تمرين'))),
      nameEn: toS(j['nameEn']),
      nameAr: toS(j['nameAr']),
      emoji: toS(j['emoji']),
      category: toS(j['category'], 'أخرى'),
      type: toS(j['type'], 'reps') == 'time' ? 'time' : 'reps',
      equipment: kEquipLabels.containsKey(toS(j['equipment']))
          ? toS(j['equipment'])
          : 'bodyweight',
      youtube: toS(j['youtube'] ?? j['video']),
      link: toS(j['link']),
      notes: toS(j['notes']),
      level: toS(j['level']),
      muscles: _strList(j['muscles']),
      secondary: _strList(j['secondary']),
      stepsEn: _strList(j['stepsEn']),
      stepsAr: _strList(j['stepsAr']),
      tipsEn: _strList(j['tipsEn']),
      tipsAr: _strList(j['tipsAr']),
      images: _strList(j['images']),
      // بيانات قديمة بلا src: تُعالج لاحقاً في الترحيل (store.migrateLegacy)
      src: hasSrc ? toS(j['src'], 'custom') : 'legacy',
      edited: toB(j['edited'], false),
      rev: toI(j['rev'], 0),
    );
  }
}

// ---------- عنصر داخل يوم تمرين ----------
class PlanItem {
  String exerciseId;
  String role; // warmup | main | cooldown
  int sets;
  int reps;
  int seconds;
  int restSeconds;
  double weight;
  double increment;

  PlanItem({
    required this.exerciseId,
    this.role = 'main',
    this.sets = 3,
    this.reps = 12,
    this.seconds = 0,
    this.restSeconds = 90,
    this.weight = 0,
    this.increment = 0,
  });

  PlanItem copy() => PlanItem(
        exerciseId: exerciseId,
        role: role,
        sets: sets,
        reps: reps,
        seconds: seconds,
        restSeconds: restSeconds,
        weight: weight,
        increment: increment,
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'role': role,
        'sets': sets,
        'reps': reps,
        'seconds': seconds,
        'restSeconds': restSeconds,
        'weight': weight,
        'increment': increment,
      };

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
        exerciseId: toS(j['exerciseId']),
        role: kRoleLabels.containsKey(toS(j['role'])) ? toS(j['role']) : 'main',
        sets: toI(j['sets'], 3),
        reps: toI(j['reps'], 12),
        seconds: toI(j['seconds'], 0),
        restSeconds: toI(j['restSeconds'], 90),
        weight: toD(j['weight'], 0),
        increment: toD(j['increment'], 0),
      );
}

// ---------- نوع يوم (علوي / سفلي / راحة ...) ----------
class DayType {
  String id;
  String name;
  String kind; // train | rest
  String emoji;
  List<PlanItem> items;

  DayType({
    required this.id,
    required this.name,
    this.kind = 'train',
    this.emoji = '💪',
    List<PlanItem>? items,
  }) : items = items ?? [];

  bool get isRest => kind == 'rest';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'emoji': emoji,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory DayType.fromJson(Map<String, dynamic> j) => DayType(
        id: toS(j['id'], newId()),
        name: toS(j['name'], 'يوم'),
        kind: toS(j['kind'], 'train') == 'rest' ? 'rest' : 'train',
        emoji: toS(j['emoji'], '💪'),
        items: asList(j['items'])
            .map((e) => PlanItem.fromJson(asMap(e)))
            .toList(),
      );
}

// ---------- الخطة ----------
class Plan {
  String id;
  String name;
  int totalDays;
  DateTime startDate;
  List<String> pattern;
  List<DayType> dayTypes;
  String equipment;
  bool shiftOnMiss;
  int deloadEvery; // بالأسابيع، 0 = معطل
  Map<String, bool> done; // تاريخ -> هل هو تمرين تعويضي (راحة حُوّلت إلى تمرين)
  Set<String> bonus;

  Plan({
    required this.id,
    required this.name,
    required this.totalDays,
    required this.startDate,
    required this.pattern,
    required this.dayTypes,
    this.equipment = 'weights',
    this.shiftOnMiss = true,
    this.deloadEvery = 0,
    Map<String, bool>? done,
    Set<String>? bonus,
  })  : done = done ?? {},
        bonus = bonus ?? {};

  DayType dayTypeById(String id) {
    for (final d in dayTypes) {
      if (d.id == id) return d;
    }
    return dayTypes.first;
  }

  DayType typeAt(int slot) {
    if (pattern.isEmpty) return dayTypes.first;
    return dayTypeById(pattern[slot % pattern.length]);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalDays': totalDays,
        'startDate': dateKey(startDate),
        'pattern': pattern,
        'dayTypes': dayTypes.map((e) => e.toJson()).toList(),
        'equipment': equipment,
        'shiftOnMiss': shiftOnMiss,
        'deloadEvery': deloadEvery,
        'done': done,
        'bonus': bonus.toList(),
      };

  factory Plan.fromJson(Map<String, dynamic> j) {
    var types = asList(j['dayTypes']).map((e) => DayType.fromJson(asMap(e))).toList();
    if (types.isEmpty) {
      types = [DayType(id: 'rest', name: 'راحة', kind: 'rest', emoji: '😴')];
    }
    var pattern = asList(j['pattern']).map((e) => toS(e)).toList();
    pattern.removeWhere((p) => !types.any((t) => t.id == p));
    if (pattern.isEmpty) pattern = [types.first.id];
    final doneRaw = asMap(j['done']);
    return Plan(
      id: toS(j['id'], newId()),
      name: toS(j['name'], 'خطتي'),
      totalDays: clampI(toI(j['totalDays'], 100), 1, 2000),
      startDate: tryParseKey(toS(j['startDate'])) ?? dateOnly(DateTime.now()),
      pattern: pattern,
      dayTypes: types,
      equipment: toS(j['equipment'], 'weights'),
      shiftOnMiss: toB(j['shiftOnMiss'], true),
      deloadEvery: toI(j['deloadEvery'], 0),
      done: doneRaw.map((k, v) => MapEntry(k, toB(v))),
      bonus: asList(j['bonus']).map((e) => toS(e)).toSet(),
    );
  }
}

// ---------- الإعدادات ----------
class Settings {
  int workoutMinutes; // وقت التمرين (دقائق من منتصف الليل)
  bool notifyWorkout;
  bool waterReminders;
  int waterEveryMin;
  int waterFrom;
  int waterTo;
  int defaultRest;
  int autoInterval;
  bool autoCount;
  bool sound;
  bool vibrate;
  bool keepAwake;
  bool autoProgression;
  bool askRpe;
  int askAfterMissed;
  String missedSnooze;
  String themeMode; // system | light | dark
  int bestStreak;
  int prCount;
  String lang; // '' = لم يُختر بعد | ar | en
  bool introSeen;
  int medFollowUpMin; // 0 = معطل
  bool streakNudge;
  int lateNudgeMin;
  String catalogUrl; // فارغ = الافتراضي

  Settings({
    this.workoutMinutes = 18 * 60,
    this.notifyWorkout = true,
    this.waterReminders = true,
    this.waterEveryMin = 120,
    this.waterFrom = 9 * 60,
    this.waterTo = 21 * 60,
    this.defaultRest = 90,
    this.autoInterval = 10,
    this.autoCount = false,
    this.sound = true,
    this.vibrate = true,
    this.keepAwake = true,
    this.autoProgression = true,
    this.askRpe = true,
    this.askAfterMissed = 3,
    this.missedSnooze = '',
    this.themeMode = 'system',
    this.bestStreak = 0,
    this.prCount = 0,
    this.lang = '',
    this.introSeen = false,
    this.medFollowUpMin = 0,
    this.streakNudge = true,
    this.lateNudgeMin = 30,
    this.catalogUrl = '',
  });

  Map<String, dynamic> toJson() => {
        'workoutMinutes': workoutMinutes,
        'notifyWorkout': notifyWorkout,
        'waterReminders': waterReminders,
        'waterEveryMin': waterEveryMin,
        'waterFrom': waterFrom,
        'waterTo': waterTo,
        'defaultRest': defaultRest,
        'autoInterval': autoInterval,
        'autoCount': autoCount,
        'sound': sound,
        'vibrate': vibrate,
        'keepAwake': keepAwake,
        'autoProgression': autoProgression,
        'askRpe': askRpe,
        'askAfterMissed': askAfterMissed,
        'missedSnooze': missedSnooze,
        'themeMode': themeMode,
        'bestStreak': bestStreak,
        'prCount': prCount,
        'lang': lang,
        'introSeen': introSeen,
        'medFollowUpMin': medFollowUpMin,
        'streakNudge': streakNudge,
        'lateNudgeMin': lateNudgeMin,
        'catalogUrl': catalogUrl,
      };

  factory Settings.fromJson(Map<String, dynamic> j) {
    final d = Settings();
    return Settings(
      workoutMinutes: toI(j['workoutMinutes'], d.workoutMinutes),
      notifyWorkout: toB(j['notifyWorkout'], d.notifyWorkout),
      waterReminders: toB(j['waterReminders'], d.waterReminders),
      waterEveryMin: clampI(toI(j['waterEveryMin'], d.waterEveryMin), 30, 600),
      waterFrom: toI(j['waterFrom'], d.waterFrom),
      waterTo: toI(j['waterTo'], d.waterTo),
      defaultRest: toI(j['defaultRest'], d.defaultRest),
      autoInterval: clampI(toI(j['autoInterval'], d.autoInterval), 1, 600),
      autoCount: toB(j['autoCount'], d.autoCount),
      sound: toB(j['sound'], d.sound),
      vibrate: toB(j['vibrate'], d.vibrate),
      keepAwake: toB(j['keepAwake'], d.keepAwake),
      autoProgression: toB(j['autoProgression'], d.autoProgression),
      askRpe: toB(j['askRpe'], d.askRpe),
      askAfterMissed: toI(j['askAfterMissed'], d.askAfterMissed),
      missedSnooze: toS(j['missedSnooze']),
      themeMode: toS(j['themeMode'], 'system'),
      bestStreak: toI(j['bestStreak'], 0),
      prCount: toI(j['prCount'], 0),
      lang: const ['ar', 'en'].contains(toS(j['lang'])) ? toS(j['lang']) : '',
      introSeen: toB(j['introSeen'], false),
      medFollowUpMin: clampI(toI(j['medFollowUpMin'], d.medFollowUpMin), 0, 120),
      streakNudge: toB(j['streakNudge'], d.streakNudge),
      lateNudgeMin: clampI(toI(j['lateNudgeMin'], d.lateNudgeMin), 5, 240),
      catalogUrl: toS(j['catalogUrl']),
    );
  }
}

// ---------- معلومات الجسم ----------
class Profile {
  int age;
  String gender; // male | female
  double heightCm;
  double weightKg;
  String goal; // bulk | cut | maintain
  double activity;
  double? waterGoalL;
  int? kcalGoal;
  int? proteinGoal;
  int? carbsGoal;

  Profile({
    this.age = 0,
    this.gender = 'male',
    this.heightCm = 0,
    this.weightKg = 0,
    this.goal = 'bulk',
    this.activity = 1.55,
    this.waterGoalL,
    this.kcalGoal,
    this.proteinGoal,
    this.carbsGoal,
  });

  bool get complete => age > 0 && heightCm > 0 && weightKg > 0;

  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goal': goal,
        'activity': activity,
        'waterGoalL': waterGoalL,
        'kcalGoal': kcalGoal,
        'proteinGoal': proteinGoal,
        'carbsGoal': carbsGoal,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        age: toI(j['age'], 0),
        gender: toS(j['gender'], 'male') == 'female' ? 'female' : 'male',
        heightCm: toD(j['heightCm'], 0),
        weightKg: toD(j['weightKg'], 0),
        goal: const ['bulk', 'cut', 'maintain'].contains(toS(j['goal']))
            ? toS(j['goal'])
            : 'bulk',
        activity: toD(j['activity'], 1.55),
        waterGoalL: j['waterGoalL'] == null ? null : toD(j['waterGoalL']),
        kcalGoal: j['kcalGoal'] == null ? null : toI(j['kcalGoal']),
        proteinGoal: j['proteinGoal'] == null ? null : toI(j['proteinGoal']),
        carbsGoal: j['carbsGoal'] == null ? null : toI(j['carbsGoal']),
      );
}

// ---------- سجلات ----------
class SetLog {
  String date;
  String exerciseId;
  int setNo;
  int reps;
  int seconds;
  double weight;
  int rpe; // 0 = غير مسجل
  String note;
  int ts;

  SetLog({
    required this.date,
    required this.exerciseId,
    required this.setNo,
    this.reps = 0,
    this.seconds = 0,
    this.weight = 0,
    this.rpe = 0,
    this.note = '',
    int? ts,
  }) : ts = ts ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'date': date,
        'exerciseId': exerciseId,
        'setNo': setNo,
        'reps': reps,
        'seconds': seconds,
        'weight': weight,
        'rpe': rpe,
        'note': note,
        'ts': ts,
      };

  factory SetLog.fromJson(Map<String, dynamic> j) => SetLog(
        date: toS(j['date']),
        exerciseId: toS(j['exerciseId']),
        setNo: toI(j['setNo'], 1),
        reps: toI(j['reps']),
        seconds: toI(j['seconds']),
        weight: toD(j['weight']),
        rpe: toI(j['rpe']),
        note: toS(j['note']),
        ts: toI(j['ts'], 0),
      );
}

class SessionLog {
  String date;
  String dayName;
  int durationSec;
  double volume;
  int sets;

  SessionLog({
    required this.date,
    required this.dayName,
    this.durationSec = 0,
    this.volume = 0,
    this.sets = 0,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'dayName': dayName,
        'durationSec': durationSec,
        'volume': volume,
        'sets': sets,
      };

  factory SessionLog.fromJson(Map<String, dynamic> j) => SessionLog(
        date: toS(j['date']),
        dayName: toS(j['dayName']),
        durationSec: toI(j['durationSec']),
        volume: toD(j['volume']),
        sets: toI(j['sets']),
      );
}

class Measurement {
  String date;
  double weight;
  double chest;
  double arm;
  double waist;
  double thigh;
  double hips;

  Measurement({
    required this.date,
    this.weight = 0,
    this.chest = 0,
    this.arm = 0,
    this.waist = 0,
    this.thigh = 0,
    this.hips = 0,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'weight': weight,
        'chest': chest,
        'arm': arm,
        'waist': waist,
        'thigh': thigh,
        'hips': hips,
      };

  factory Measurement.fromJson(Map<String, dynamic> j) => Measurement(
        date: toS(j['date']),
        weight: toD(j['weight']),
        chest: toD(j['chest']),
        arm: toD(j['arm']),
        waist: toD(j['waist']),
        thigh: toD(j['thigh']),
        hips: toD(j['hips']),
      );
}

class PhotoEntry {
  String date;
  String file;
  String note;
  PhotoEntry({required this.date, required this.file, this.note = ''});

  Map<String, dynamic> toJson() => {'date': date, 'file': file, 'note': note};
  factory PhotoEntry.fromJson(Map<String, dynamic> j) => PhotoEntry(
      date: toS(j['date']), file: toS(j['file']), note: toS(j['note']));
}

class FoodEntry {
  String name;
  int kcal;
  int protein;
  int carbs;
  int fat;
  int ts;
  FoodEntry(
      {this.name = '',
      required this.kcal,
      this.protein = 0,
      this.carbs = 0,
      this.fat = 0,
      int? ts})
      : ts = ts ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'name': name,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'ts': ts
      };
  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
        name: toS(j['name']),
        kcal: toI(j['kcal']),
        protein: toI(j['protein']),
        carbs: toI(j['carbs']),
        fat: toI(j['fat']),
        ts: toI(j['ts'], 0),
      );
}

/// وجبة محفوظة يمكن اختيارها مجدداً.
class SavedMeal {
  String id;
  String name;
  int kcal;
  int protein;
  int carbs;
  int fat;
  String photo; // اسم ملف داخل مجلد meal_photos (اختياري)
  int uses;
  int lastUsed;

  SavedMeal({
    required this.id,
    required this.name,
    required this.kcal,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.photo = '',
    this.uses = 0,
    this.lastUsed = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'photo': photo,
        'uses': uses,
        'lastUsed': lastUsed,
      };

  factory SavedMeal.fromJson(Map<String, dynamic> j) => SavedMeal(
        id: toS(j['id'], newId()),
        name: toS(j['name'], 'وجبة'),
        kcal: toI(j['kcal']),
        protein: toI(j['protein']),
        carbs: toI(j['carbs']),
        fat: toI(j['fat']),
        photo: toS(j['photo']),
        uses: toI(j['uses']),
        lastUsed: toI(j['lastUsed']),
      );
}

// ---------- الأدوية والعلاجات ----------
const kMedForms = {
  'pill': ['حبة / قرص', '💊'],
  'capsule': ['كبسولة', '💊'],
  'syrup': ['شراب', '🧴'],
  'injection': ['حقنة', '💉'],
  'drops': ['قطرة', '💧'],
  'cream': ['مرهم / كريم', '🧴'],
  'inhaler': ['بخاخ', '🌬️'],
  'other': ['أخرى', '🩺'],
};

const kMedInstr = {
  '': 'بدون تعليمات',
  'before_meal': 'قبل الأكل',
  'after_meal': 'بعد الأكل',
  'with_meal': 'مع الأكل',
  'empty': 'على معدة فارغة',
};

class Medication {
  String id;
  String name;
  String dose; // نص حر: «حبة واحدة»، «5 مل»...
  String form;
  List<int> times; // دقائق من منتصف الليل
  List<int> weekdays; // 1=الاثنين ... 7=الأحد، فارغ = كل يوم
  DateTime startDate;
  DateTime? endDate; // null = مستمر
  String instructions;
  String notes;
  bool reminder;
  bool active;

  Medication({
    required this.id,
    required this.name,
    this.dose = '',
    this.form = 'pill',
    List<int>? times,
    List<int>? weekdays,
    required this.startDate,
    this.endDate,
    this.instructions = '',
    this.notes = '',
    this.reminder = true,
    this.active = true,
  })  : times = times ?? [8 * 60],
        weekdays = weekdays ?? [];

  String get emoji => (kMedForms[form] ?? kMedForms['other']!)[1];

  bool activeOn(DateTime d) {
    if (!active) return false;
    final day = dateOnly(d);
    if (day.isBefore(dateOnly(startDate))) return false;
    if (endDate != null && day.isAfter(dateOnly(endDate!))) return false;
    if (weekdays.isNotEmpty && !weekdays.contains(day.weekday)) return false;
    return true;
  }

  /// رقم يوم العلاج (1 = أول يوم) أو 0 إن لم يبدأ.
  int courseDay(DateTime d) {
    final n = daysBetween(startDate, d) + 1;
    return n < 1 ? 0 : n;
  }

  int? get courseLength =>
      endDate == null ? null : daysBetween(startDate, endDate!) + 1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dose': dose,
        'form': form,
        'times': times,
        'weekdays': weekdays,
        'startDate': dateKey(startDate),
        'endDate': endDate == null ? '' : dateKey(endDate!),
        'instructions': instructions,
        'notes': notes,
        'reminder': reminder,
        'active': active,
      };

  factory Medication.fromJson(Map<String, dynamic> j) {
    final t = asList(j['times']).map((e) => clampI(toI(e), 0, 1439)).toList()
      ..sort();
    return Medication(
      id: toS(j['id'], newId()),
      name: toS(j['name'], 'دواء'),
      dose: toS(j['dose']),
      form: kMedForms.containsKey(toS(j['form'])) ? toS(j['form']) : 'pill',
      times: t.isEmpty ? [8 * 60] : t,
      weekdays: asList(j['weekdays'])
          .map((e) => toI(e))
          .where((e) => e >= 1 && e <= 7)
          .toList(),
      startDate: tryParseKey(toS(j['startDate'])) ?? dateOnly(DateTime.now()),
      endDate: tryParseKey(toS(j['endDate'])),
      instructions: kMedInstr.containsKey(toS(j['instructions']))
          ? toS(j['instructions'])
          : '',
      notes: toS(j['notes']),
      reminder: toB(j['reminder'], true),
      active: toB(j['active'], true),
    );
  }
}

class MedLog {
  String date;
  String medId;
  int minutes;
  String status; // taken | skipped
  int ts;
  MedLog(
      {required this.date,
      required this.medId,
      required this.minutes,
      this.status = 'taken',
      int? ts})
      : ts = ts ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'date': date,
        'medId': medId,
        'minutes': minutes,
        'status': status,
        'ts': ts,
      };
  factory MedLog.fromJson(Map<String, dynamic> j) => MedLog(
        date: toS(j['date']),
        medId: toS(j['medId']),
        minutes: toI(j['minutes']),
        status: toS(j['status']) == 'skipped' ? 'skipped' : 'taken',
        ts: toI(j['ts'], 0),
      );
}

/// جرعة مجدولة ليوم معيّن.
class Dose {
  final Medication med;
  final DateTime date;
  final int minutes;
  final String status; // '' | taken | skipped
  const Dose(this.med, this.date, this.minutes, this.status);
  bool get taken => status == 'taken';
  bool get skipped => status == 'skipped';
  DateTime get when => DateTime(date.year, date.month, date.day)
      .add(Duration(minutes: minutes));
}

// ---------- كل البيانات ----------
class AppData {
  bool onboarded = false;
  Settings settings = Settings();
  Profile profile = Profile();
  List<Exercise> exercises = [];
  List<Plan> plans = [];
  String activePlanId = '';
  List<SetLog> logs = [];
  List<SessionLog> sessions = [];
  List<Measurement> measurements = [];
  List<PhotoEntry> photos = [];
  Map<String, List<int>> water = {};
  Map<String, List<FoodEntry>> food = {};
  List<SavedMeal> savedMeals = [];
  List<Medication> meds = [];
  List<MedLog> medLogs = [];

  Map<String, dynamic> toJson() => {
        'kind': 'gym_backup',
        'version': 1,
        'onboarded': onboarded,
        'settings': settings.toJson(),
        'profile': profile.toJson(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'plans': plans.map((e) => e.toJson()).toList(),
        'activePlanId': activePlanId,
        'logs': logs.map((e) => e.toJson()).toList(),
        'sessions': sessions.map((e) => e.toJson()).toList(),
        'measurements': measurements.map((e) => e.toJson()).toList(),
        'photos': photos.map((e) => e.toJson()).toList(),
        'water': water,
        'food': food.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
        'savedMeals': savedMeals.map((e) => e.toJson()).toList(),
        'meds': meds.map((e) => e.toJson()).toList(),
        'medLogs': medLogs.map((e) => e.toJson()).toList(),
      };

  static AppData fromJson(Map<String, dynamic> j) {
    final d = AppData();
    d.onboarded = toB(j['onboarded'], false);
    d.settings = Settings.fromJson(asMap(j['settings']));
    d.profile = Profile.fromJson(asMap(j['profile']));
    d.exercises =
        asList(j['exercises']).map((e) => Exercise.fromJson(asMap(e))).toList();
    d.plans = asList(j['plans']).map((e) => Plan.fromJson(asMap(e))).toList();
    d.activePlanId = toS(j['activePlanId']);
    d.logs = asList(j['logs']).map((e) => SetLog.fromJson(asMap(e))).toList();
    d.sessions =
        asList(j['sessions']).map((e) => SessionLog.fromJson(asMap(e))).toList();
    d.measurements = asList(j['measurements'])
        .map((e) => Measurement.fromJson(asMap(e)))
        .toList();
    d.photos =
        asList(j['photos']).map((e) => PhotoEntry.fromJson(asMap(e))).toList();
    d.water = asMap(j['water'])
        .map((k, v) => MapEntry(k, asList(v).map((e) => toI(e)).toList()));
    d.food = asMap(j['food']).map((k, v) =>
        MapEntry(k, asList(v).map((e) => FoodEntry.fromJson(asMap(e))).toList()));
    d.savedMeals = asList(j['savedMeals'])
        .map((e) => SavedMeal.fromJson(asMap(e)))
        .toList();
    d.meds = asList(j['meds']).map((e) => Medication.fromJson(asMap(e))).toList();
    d.medLogs =
        asList(j['medLogs']).map((e) => MedLog.fromJson(asMap(e))).toList();
    return d;
  }
}
