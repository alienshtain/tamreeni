// الحالة المركزية للتطبيق + الحفظ في ملف JSON.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'catalog.dart';
import 'engine.dart';
import 'i18n.dart';
import 'models.dart';
import 'services.dart';
import 'templates.dart';

final AppStore store = AppStore();

class RunItem {
  final Exercise ex;
  final PlanItem item;
  final int sets;
  double weight;
  final int reps;
  final int seconds;
  final int rest;
  final bool deload;
  RunItem({
    required this.ex,
    required this.item,
    required this.sets,
    required this.weight,
    required this.reps,
    required this.seconds,
    required this.rest,
    required this.deload,
  });
  bool get isMain => item.role == 'main';
}

class Best {
  double weight = 0;
  int reps = 0;
  int seconds = 0;
}

class HistPoint {
  final String date;
  final double maxWeight;
  final int maxReps;
  final int maxSeconds;
  final double e1rm;
  final double volume;
  const HistPoint(this.date, this.maxWeight, this.maxReps, this.maxSeconds,
      this.e1rm, this.volume);
}

class SessionSummary {
  final int durationSec;
  final int sets;
  final double volume;
  final List<String> prs;
  final List<String> bumps;
  final int streak;
  const SessionSummary(
      this.durationSec, this.sets, this.volume, this.prs, this.bumps, this.streak);
}

class AppStore extends ChangeNotifier {
  AppData data = AppData();
  Directory? _dir;
  Timer? _saveTimer;
  bool loaded = false;

  // ---------- الحفظ والتحميل ----------
  Future<void> load() async {
    _dir = await getApplicationDocumentsDirectory();
    final f = File('${_dir!.path}/gym_data.json');
    if (await f.exists()) {
      try {
        final j = jsonDecode(await f.readAsString());
        data = AppData.fromJson(asMap(j));
      } catch (e) {
        debugPrint('load failed: $e');
        try {
          await f.copy('${_dir!.path}/gym_data.corrupt.json');
        } catch (_) {}
        data = AppData();
      }
    }
    try {
      final txt = await rootBundle.loadString('assets/catalog/exercises.json');
      catalog.setUrl(data.settings.catalogUrl);
      await catalog.init(txt, _dir!.path);
    } catch (e) {
      debugPrint('catalog init failed: $e');
    }
    if (data.exercises.isEmpty) data.exercises = defaultExercises();
    migrateLegacy();
    gLang = data.settings.lang == 'en' ? 'en' : 'ar';
    loaded = true;
  }

  void setLang(String l) {
    data.settings.lang = l == 'en' ? 'en' : 'ar';
    gLang = data.settings.lang;
    changed();
    Notifier.reschedule();
  }

  /// تمارين محفوظة من الإصدار القديم: تُربط بالكتالوج إن لم يعدّلها المستخدم.
  void migrateLegacy() {
    final legacy = {for (final e in legacyDefaults()) e.id: e};
    var any = false;
    for (var i = 0; i < data.exercises.length; i++) {
      final e = data.exercises[i];
      if (e.src != 'legacy') continue;
      any = true;
      final old = legacy[e.id];
      final cat = catalog.byId(e.id);
      final untouched = old != null &&
          e.name == old.name &&
          e.emoji == old.emoji &&
          e.youtube.isEmpty &&
          e.notes.isEmpty &&
          e.category == old.category &&
          e.type == old.type &&
          e.equipment == old.equipment;
      if (untouched && cat != null) {
        data.exercises[i] = cat;
      } else {
        e.src = 'custom';
        e.edited = true;
        if (e.emoji == '💪' && old == null) e.emoji = '';
      }
    }
    if (any) changed();
  }

  /// يضيف تمريناً من الكتالوج للمكتبة (إن لم يكن موجوداً) ويعيد نسخة المكتبة.
  Exercise addFromCatalog(Exercise c) {
    final have = ex(c.id);
    if (have != null) return have;
    data.exercises.add(c);
    changed();
    return c;
  }

  /// بعد تحديث الكتالوج: تحديث التمارين المرتبطة به التي لم يعدّلها المستخدم.
  int syncLibraryFromCatalog() {
    var n = 0;
    for (var i = 0; i < data.exercises.length; i++) {
      final e = data.exercises[i];
      if (!e.fromCatalog || e.edited) continue;
      final c = catalog.byId(e.id);
      if (c == null) continue;
      if (jsonEncode(c.toJson()) != jsonEncode(e.toJson())) {
        data.exercises[i] = c;
        n++;
      }
    }
    if (n > 0) changed();
    return n;
  }

  Future<void> _save() async {
    final d = _dir;
    if (d == null) return;
    try {
      final tmp = File('${d.path}/gym_data.tmp');
      await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
      await tmp.rename('${d.path}/gym_data.json');
    } catch (e) {
      debugPrint('save failed: $e');
    }
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    await _save();
  }

  /// بعد أي تعديل: إعادة بناء الواجهة + حفظ مؤجل.
  void changed() {
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _save);
  }

  void touch() => notifyListeners();

  // ---------- أساسيات ----------
  DateTime get today => dateOnly(DateTime.now());
  Settings get settings => data.settings;

  ThemeMode get themeMode {
    switch (data.settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Plan? get plan {
    for (final p in data.plans) {
      if (p.id == data.activePlanId) return p;
    }
    return data.plans.isEmpty ? null : data.plans.first;
  }

  PlanState? get state {
    final p = plan;
    if (p == null) return null;
    return simulate(p, DateTime.now());
  }

  Exercise? ex(String id) {
    for (final e in data.exercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  bool exerciseUsed(String id) {
    for (final p in data.plans) {
      for (final d in p.dayTypes) {
        if (d.items.any((i) => i.exerciseId == id)) return true;
      }
    }
    return false;
  }

  // ---------- الماء والأكل ----------
  int waterMl(DateTime d) =>
      (data.water[dateKey(d)] ?? <int>[]).fold(0, (a, b) => a + b);

  void addWater(int ml) {
    (data.water[dateKey(today)] ??= <int>[]).add(ml);
    changed();
  }

  void undoWater() {
    final l = data.water[dateKey(today)];
    if (l != null && l.isNotEmpty) {
      l.removeLast();
      changed();
    }
  }

  List<FoodEntry> foodOf(DateTime d) => data.food[dateKey(d)] ?? <FoodEntry>[];
  int kcalOf(DateTime d) => foodOf(d).fold(0, (a, b) => a + b.kcal);
  int proteinOf(DateTime d) => foodOf(d).fold(0, (a, b) => a + b.protein);
  int carbsOf(DateTime d) => foodOf(d).fold(0, (a, b) => a + b.carbs);
  int fatOf(DateTime d) => foodOf(d).fold(0, (a, b) => a + b.fat);

  void addFood(FoodEntry e) {
    (data.food[dateKey(today)] ??= <FoodEntry>[]).add(e);
    changed();
  }

  void removeFood(int ts) {
    data.food[dateKey(today)]?.removeWhere((e) => e.ts == ts);
    changed();
  }

  // ---------- الوجبات المحفوظة ----------
  List<SavedMeal> get savedMealsSorted {
    final l = List<SavedMeal>.from(data.savedMeals);
    l.sort((a, b) {
      final c = b.lastUsed.compareTo(a.lastUsed);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return l;
  }

  SavedMeal saveMeal(FoodEntry e, {String photo = ''}) {
    final key = e.name.trim().toLowerCase();
    for (final m in data.savedMeals) {
      if (m.name.trim().toLowerCase() == key && key.isNotEmpty) {
        m.kcal = e.kcal;
        m.protein = e.protein;
        m.carbs = e.carbs;
        m.fat = e.fat;
        if (photo.isNotEmpty) m.photo = photo;
        changed();
        return m;
      }
    }
    final m = SavedMeal(
        id: newId(),
        name: e.name.isEmpty ? 'وجبة' : e.name,
        kcal: e.kcal,
        protein: e.protein,
        carbs: e.carbs,
        fat: e.fat,
        photo: photo);
    data.savedMeals.add(m);
    changed();
    return m;
  }

  void useMeal(SavedMeal m) {
    m.uses++;
    m.lastUsed = DateTime.now().millisecondsSinceEpoch;
    addFood(FoodEntry(
        name: m.name, kcal: m.kcal, protein: m.protein, carbs: m.carbs, fat: m.fat));
  }

  void deleteMeal(SavedMeal m) {
    data.savedMeals.removeWhere((x) => x.id == m.id);
    if (m.photo.isNotEmpty) {
      try {
        File(mealPhotoPath(m.photo)).deleteSync();
      } catch (_) {}
    }
    changed();
  }

  String mealPhotoPath(String file) => '${_dir?.path ?? ''}/meal_photos/$file';

  Future<String> saveMealPhoto(String srcPath) async {
    final d = _dir;
    if (d == null) return '';
    try {
      final dir = Directory('${d.path}/meal_photos');
      await dir.create(recursive: true);
      final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(srcPath).copy('${dir.path}/$name');
      return name;
    } catch (_) {
      return '';
    }
  }

  // ---------- الأدوية ----------
  List<Dose> dosesOn(DateTime d) {
    final key = dateKey(d);
    final out = <Dose>[];
    for (final m in data.meds) {
      if (!m.activeOn(d)) continue;
      for (final t in m.times) {
        var st = '';
        for (final l in data.medLogs) {
          if (l.date == key && l.medId == m.id && l.minutes == t) st = l.status;
        }
        out.add(Dose(m, dateOnly(d), t, st));
      }
    }
    out.sort((a, b) => a.minutes.compareTo(b.minutes));
    return out;
  }

  /// status: taken | skipped | '' (لمسح الحالة)
  void setDoseStatus(Dose d, String status) {
    final key = dateKey(d.date);
    data.medLogs.removeWhere(
        (l) => l.date == key && l.medId == d.med.id && l.minutes == d.minutes);
    if (status.isNotEmpty) {
      data.medLogs.add(MedLog(
          date: key, medId: d.med.id, minutes: d.minutes, status: status));
    }
    changed();
    Notifier.reschedule();
  }

  void upsertMed(Medication m) {
    final i = data.meds.indexWhere((x) => x.id == m.id);
    if (i >= 0) {
      data.meds[i] = m;
    } else {
      data.meds.add(m);
    }
    changed();
    Notifier.reschedule();
  }

  void deleteMed(String id) {
    data.meds.removeWhere((m) => m.id == id);
    data.medLogs.removeWhere((l) => l.medId == id);
    changed();
    Notifier.reschedule();
  }

  Medication? med(String id) {
    for (final m in data.meds) {
      if (m.id == id) return m;
    }
    return null;
  }

  Targets get targets {
    final st = state;
    return computeTargets(data.profile,
        trainingDay: st != null && st.isTrainingToday);
  }

  // ---------- الخطط ----------
  void addPlan(Plan p) {
    data.plans.add(p);
    data.activePlanId = p.id;
    changed();
    Notifier.reschedule();
  }

  void setActivePlan(String id) {
    data.activePlanId = id;
    changed();
    Notifier.reschedule();
  }

  void deletePlan(String id) {
    data.plans.removeWhere((p) => p.id == id);
    if (data.activePlanId == id) {
      data.activePlanId = data.plans.isEmpty ? '' : data.plans.first.id;
    }
    changed();
    Notifier.reschedule();
  }

  void replacePlan(Plan p) {
    final i = data.plans.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      data.plans[i] = p;
    } else {
      data.plans.add(p);
    }
    data.activePlanId = p.id;
    changed();
    Notifier.reschedule();
  }

  void restartPlan() {
    final p = plan;
    if (p == null) return;
    p.startDate = today;
    p.done.clear();
    p.bonus.clear();
    changed();
    Notifier.reschedule();
  }

  void startBonusToday() {
    final p = plan;
    if (p == null) return;
    p.bonus.add(dateKey(today));
    changed();
    Notifier.reschedule();
  }

  bool get showMissedPrompt {
    final st = state;
    if (st == null || !st.started || st.finished) return false;
    final n = data.settings.askAfterMissed;
    return n > 0 &&
        st.consecutiveMissed >= n &&
        data.settings.missedSnooze != dateKey(today);
  }

  void snoozeMissedPrompt() {
    data.settings.missedSnooze = dateKey(today);
    changed();
  }

  // ---------- التمرين الجاري ----------
  List<RunItem> buildRunItems() {
    final p = plan;
    final st = state;
    if (p == null || st == null || st.todayType == null) return [];
    final deload = isDeloadWeek(p, st.workoutSlot);
    final out = <RunItem>[];
    for (final it in st.todayType!.items) {
      final e = ex(it.exerciseId);
      if (e == null) continue;
      final main = it.role == 'main';
      out.add(RunItem(
        ex: e,
        item: it,
        sets: deload && main ? math.max(1, it.sets - 1) : it.sets,
        weight: deload && main ? roundToD(it.weight * 0.6, 0.5) : it.weight,
        reps: it.reps,
        seconds: it.seconds,
        rest: it.restSeconds,
        deload: deload && main,
      ));
    }
    return out;
  }

  List<SetLog> logsOn(String key) =>
      data.logs.where((l) => l.date == key).toList();

  void addLog(SetLog l) {
    data.logs.add(l);
    changed();
  }

  Map<String, Best> bestsBefore(int ts) {
    final m = <String, Best>{};
    for (final l in data.logs) {
      if (l.ts >= ts) continue;
      final b = m.putIfAbsent(l.exerciseId, () => Best());
      if (l.reps >= 1 && l.weight > b.weight) b.weight = l.weight;
      if (l.reps > b.reps) b.reps = l.reps;
      if (l.seconds > b.seconds) b.seconds = l.seconds;
    }
    return m;
  }

  List<HistPoint> exerciseHistory(String exId) {
    final logs = data.logs.where((l) => l.exerciseId == exId).toList()
      ..sort((a, b) => a.ts.compareTo(b.ts));
    final groups = <String, List<SetLog>>{};
    for (final l in logs) {
      groups.putIfAbsent(l.date, () => []).add(l);
    }
    final keys = groups.keys.toList()..sort();
    return keys.map((k) {
      final ls = groups[k]!;
      double mw = 0, e1 = 0, vol = 0;
      var mr = 0, ms = 0;
      for (final l in ls) {
        if (l.weight > mw) mw = l.weight;
        if (l.reps > mr) mr = l.reps;
        if (l.seconds > ms) ms = l.seconds;
        if (l.weight > 0) {
          final e = est1rm(l.weight, l.reps);
          if (e > e1) e1 = e;
          vol += l.weight * l.reps;
        }
      }
      return HistPoint(k, mw, mr, ms, e1, vol);
    }).toList();
  }

  /// يُستدعى عند انتهاء الجلسة: يعلّم اليوم مكتملاً ويطبق الحمل التدريجي.
  SessionSummary completeSession(
      List<RunItem> items, List<SetLog> logs, DateTime startedAt) {
    final p = plan!;
    final key = dateKey(today);
    final bests = bestsBefore(startedAt.millisecondsSinceEpoch);
    final prs = <String>[];
    final bumps = <String>[];
    final handled = <String>{};
    double volume = 0;

    for (final l in logs) {
      if (l.weight > 0) volume += l.weight * l.reps;
    }

    for (final it in items) {
      if (!it.isMain || handled.contains(it.ex.id)) continue;
      handled.add(it.ex.id);
      final ls = logs.where((l) => l.exerciseId == it.ex.id).toList();
      if (ls.isEmpty) continue;
      final best = bests[it.ex.id];

      // أرقام قياسية
      if (best != null) {
        if (it.ex.usesWeight) {
          final mw = ls.map((l) => l.weight).reduce(math.max);
          if (best.weight > 0 && mw > best.weight) {
            prs.add('${it.ex.title}: ${fmtNum(mw)} كغ');
          }
        } else if (it.ex.isTime) {
          final ms = ls.map((l) => l.seconds).reduce(math.max);
          if (best.seconds > 0 && ms > best.seconds) {
            prs.add('${it.ex.title}: $ms ثانية');
          }
        } else {
          final mr = ls.map((l) => l.reps).reduce(math.max);
          if (best.reps > 0 && mr > best.reps) {
            prs.add('${it.ex.title}: $mr عدة');
          }
        }
      }

      // الحمل التدريجي
      final planItem = it.item;
      if (it.deload) continue;
      if (it.ex.usesWeight) {
        final last = ls.last.weight;
        if (last > 0 && (last - planItem.weight).abs() > 0.001) {
          planItem.weight = last;
        }
      }
      if (!data.settings.autoProgression) continue;
      if (ls.length < it.sets) continue;
      if (ls.any((l) => l.rpe >= 10)) continue;
      if (it.ex.isTime) {
        if (ls.every((l) => l.seconds >= planItem.seconds) &&
            planItem.seconds < 600) {
          planItem.seconds += 5;
          bumps.add('${it.ex.title}: ${planItem.seconds} ثانية');
        }
      } else if (it.ex.usesWeight && planItem.weight > 0 && planItem.increment > 0) {
        if (ls.every((l) => l.reps >= planItem.reps)) {
          planItem.weight = roundToD(planItem.weight + planItem.increment, 0.25);
          bumps.add('${it.ex.title}: ${fmtNum(planItem.weight)} كغ');
        }
      } else if (!it.ex.usesWeight) {
        if (ls.every((l) => l.reps >= planItem.reps) && planItem.reps < 50) {
          planItem.reps += 1;
          bumps.add('${it.ex.title}: ${planItem.reps} عدة');
        }
      }
    }

    final dur = DateTime.now().difference(startedAt).inSeconds;
    final st0 = state;
    final dayName = st0?.todayType?.name ?? 'تمرين';
    p.done[key] = p.bonus.contains(key);
    data.sessions.removeWhere((s) => s.date == key);
    data.sessions.add(SessionLog(
        date: key,
        dayName: dayName,
        durationSec: dur,
        volume: volume,
        sets: logs.length));
    final streak = state?.streak ?? 0;
    if (streak > data.settings.bestStreak) data.settings.bestStreak = streak;
    data.settings.prCount += prs.length;
    changed();
    Notifier.reschedule();
    return SessionSummary(dur, logs.length, volume, prs, bumps, streak);
  }

  // ---------- المكتبة ----------
  void upsertExercise(Exercise e) {
    final i = data.exercises.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      data.exercises[i] = e;
    } else {
      data.exercises.add(e);
    }
    changed();
  }

  void deleteExercise(String id) {
    data.exercises.removeWhere((e) => e.id == id);
    changed();
  }

  // ---------- الجسم والصور ----------
  void addMeasurement(Measurement m) {
    data.measurements.removeWhere((x) => x.date == m.date);
    data.measurements.add(m);
    data.measurements.sort((a, b) => a.date.compareTo(b.date));
    if (m.weight > 0) data.profile.weightKg = m.weight;
    changed();
  }

  void removeMeasurement(String date) {
    data.measurements.removeWhere((x) => x.date == date);
    changed();
  }

  String photoPath(PhotoEntry p) => '${_dir?.path ?? ''}/photos/${p.file}';

  Future<void> addPhoto(String srcPath, String note) async {
    final d = _dir;
    if (d == null) return;
    final dir = Directory('${d.path}/photos');
    await dir.create(recursive: true);
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(srcPath).copy('${dir.path}/$name');
    data.photos.add(PhotoEntry(date: dateKey(today), file: name, note: note));
    changed();
  }

  Future<void> removePhoto(PhotoEntry p) async {
    try {
      await File(photoPath(p)).delete();
    } catch (_) {}
    data.photos.remove(p);
    changed();
  }

  // ---------- النسخ الاحتياطي ----------
  void restoreBackup(Map<String, dynamic> j) {
    final photos = data.photos;
    data = AppData.fromJson(j);
    if (data.exercises.isEmpty) data.exercises = defaultExercises();
    if (data.photos.isEmpty) data.photos = photos;
    changed();
    Notifier.reschedule();
  }

  // ---------- إحصاءات ----------
  int get completedWorkouts => data.sessions.length;
  double get totalVolume => data.sessions.fold(0.0, (a, b) => a + b.volume);
}
