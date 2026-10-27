// منطق الجدول المتحرك + حسابات التغذية + أدوات التنسيق.
import 'dart:math' as math;
import 'i18n.dart';
import 'models.dart';

// ======================= حالة الخطة =======================

enum CellStatus { done, missed, rest, pending }

class DayCell {
  final CellStatus status;
  final DateTime? date;
  final int slot;
  final String typeId;
  final bool restType;
  final bool isToday;
  const DayCell({
    required this.status,
    required this.slot,
    required this.typeId,
    this.date,
    this.restType = false,
    this.isToday = false,
  });
}

class PlanState {
  final List<DayCell> cells;
  final int completed;
  final int total;
  final int missed;
  final int doneCount;
  final bool started;
  final bool finished;
  final bool todayDone;
  final bool restToday;
  final bool bonusToday;
  final int workoutSlot; // -1 إذا لا يوجد تمرين اليوم
  final DayType? todayType;
  final int consecutiveMissed;
  final int streak;
  final int dayNumber;
  final int startsInDays;

  const PlanState({
    required this.cells,
    required this.completed,
    required this.total,
    required this.missed,
    required this.doneCount,
    required this.started,
    required this.finished,
    required this.todayDone,
    required this.restToday,
    required this.bonusToday,
    required this.workoutSlot,
    required this.todayType,
    required this.consecutiveMissed,
    required this.streak,
    required this.dayNumber,
    required this.startsInDays,
  });

  double get progress =>
      total <= 0 ? 0 : (completed / total).clamp(0.0, 1.0).toDouble();
  int get totalCells => cells.length;
  bool get isTrainingToday =>
      started && !restToday && workoutSlot >= 0 && todayType != null;
}

/// كم خانة تُستهلك عند إكمال اليوم. إذا كان اليوم راحة وحُوِّل لتمرين
/// تُستهلك الراحة + أقرب يوم تمرين بعدها.
int consumeSlots(Plan plan, int p, bool bonus) {
  if (!bonus || p >= plan.totalDays || !plan.typeAt(p).isRest) return p + 1;
  var q = p;
  while (q < plan.totalDays && plan.typeAt(q).isRest) {
    q++;
  }
  return math.min(q + 1, plan.totalDays);
}

int nextTrainSlot(Plan plan, int from) {
  var q = from;
  while (q < plan.totalDays && plan.typeAt(q).isRest) {
    q++;
  }
  return q;
}

PlanState simulate(Plan plan, DateTime now) {
  final start = dateOnly(plan.startDate);
  final t = dateOnly(now);
  final total = plan.totalDays;
  final cells = <DayCell>[];
  var missed = 0;
  var doneN = 0;
  final started = !t.isBefore(start);
  final pastDays = started ? daysBetween(start, t) : 0;
  var p = 0;

  if (started) {
    for (var i = 0; i < pastDays; i++) {
      final d = addDays(start, i);
      final key = dateKey(d);
      final slot = plan.shiftOnMiss ? p : i;
      if (slot >= total) break;
      final type = plan.typeAt(slot);
      if (plan.done.containsKey(key)) {
        final bonus = plan.done[key] ?? false;
        var shownType = type;
        if (bonus && type.isRest) {
          final q = nextTrainSlot(plan, slot);
          if (q < total) shownType = plan.typeAt(q);
        }
        cells.add(DayCell(
            status: CellStatus.done,
            date: d,
            slot: slot,
            typeId: shownType.id,
            restType: shownType.isRest));
        doneN++;
        if (plan.shiftOnMiss) p = consumeSlots(plan, p, bonus);
      } else if (type.isRest) {
        cells.add(DayCell(
            status: CellStatus.rest,
            date: d,
            slot: slot,
            typeId: type.id,
            restType: true));
        if (plan.shiftOnMiss) p++;
      } else {
        cells.add(DayCell(
            status: CellStatus.missed,
            date: d,
            slot: slot,
            typeId: type.id));
        missed++;
      }
    }
    if (!plan.shiftOnMiss) p = math.min(pastDays, total);
  }

  // الأيام الفائتة المتتالية + السلسلة (ننظر للخلف من آخر خلية)
  var consecMissed = 0;
  for (var i = cells.length - 1; i >= 0; i--) {
    if (cells[i].status == CellStatus.missed) {
      consecMissed++;
    } else {
      break;
    }
  }
  var streak = 0;
  for (var i = cells.length - 1; i >= 0; i--) {
    if (cells[i].status == CellStatus.missed) break;
    streak++;
  }

  final todayKey = dateKey(t);
  final todayDone = started && plan.done.containsKey(todayKey);
  final bonusFlag =
      plan.bonus.contains(todayKey) || (plan.done[todayKey] ?? false);

  var completed = p;
  var finished = false;
  var workoutSlot = -1;
  var restToday = false;
  DayType? todayType;

  if (started) {
    if (p >= total) {
      finished = true;
    } else {
      final type = plan.typeAt(p);
      workoutSlot = p;
      if (type.isRest && bonusFlag) {
        final q = nextTrainSlot(plan, p);
        if (q < total) workoutSlot = q;
      }
      restToday = type.isRest && workoutSlot == p;
      todayType = plan.typeAt(workoutSlot);
      if (todayDone) {
        completed = plan.shiftOnMiss
            ? consumeSlots(plan, p, plan.done[todayKey] ?? false)
            : p + 1;
        streak++;
      }
      if (completed >= total) finished = true;

      cells.add(DayCell(
        status: todayDone
            ? CellStatus.done
            : (restToday ? CellStatus.rest : CellStatus.pending),
        date: t,
        slot: workoutSlot,
        typeId: todayType.id,
        restType: todayType.isRest,
        isToday: true,
      ));
      var next = p + 1;
      if (plan.shiftOnMiss) {
        if (todayDone) {
          next = completed;
        } else if (workoutSlot > p) {
          next = workoutSlot + 1;
        }
      }
      for (var s = next; s < total; s++) {
        final ty = plan.typeAt(s);
        cells.add(DayCell(
            status: CellStatus.pending,
            slot: s,
            typeId: ty.id,
            restType: ty.isRest));
      }
    }
  } else {
    for (var s = 0; s < total; s++) {
      final ty = plan.typeAt(s);
      cells.add(DayCell(
          status: CellStatus.pending,
          slot: s,
          typeId: ty.id,
          restType: ty.isRest));
    }
  }

  return PlanState(
    cells: cells,
    completed: math.min(completed, total),
    total: total,
    missed: missed,
    doneCount: doneN + (todayDone ? 1 : 0),
    started: started,
    finished: finished,
    todayDone: todayDone,
    restToday: restToday,
    bonusToday: bonusFlag && !restToday,
    workoutSlot: workoutSlot,
    todayType: todayType,
    consecutiveMissed: consecMissed,
    streak: streak,
    dayNumber: started ? pastDays + 1 : 0,
    startsInDays: started ? 0 : daysBetween(t, start),
  );
}

bool isDeloadWeek(Plan plan, int slot) {
  if (plan.deloadEvery <= 0 || slot < 0) return false;
  final week = slot ~/ 7 + 1;
  return week % plan.deloadEvery == 0;
}

// ======================= التقديرات =======================

int estSetSeconds(Exercise ex, PlanItem it) =>
    ex.isTime ? math.max(10, it.seconds) : math.max(1, it.reps) * 5 + 15;

int estItemSeconds(Exercise ex, PlanItem it, {int? sets}) {
  final s = math.max(1, sets ?? it.sets);
  return s * estSetSeconds(ex, it) + math.max(0, s - 1) * it.restSeconds + 30;
}

double est1rm(double w, int reps) => reps <= 1 ? w : w * (1 + reps / 30.0);

int roundTo(double v, int step) => ((v / step).round() * step);
double roundToD(double v, double step) => (v / step).round() * step;

// ======================= التغذية =======================

class Targets {
  final int waterMl;
  final int kcal;
  final int protein;
  final double bmr;
  final double tdee;
  final bool complete;
  final int carbs;
  const Targets(this.waterMl, this.kcal, this.protein, this.bmr, this.tdee,
      this.complete, this.carbs);
}

Targets computeTargets(Profile p, {required bool trainingDay}) {
  final w = p.weightKg > 0 ? p.weightKg : 70.0;
  final h = p.heightCm > 0 ? p.heightCm : 170.0;
  final a = p.age > 0 ? p.age : 25;
  final bmr = 10 * w + 6.25 * h - 5 * a + (p.gender == 'male' ? 5 : -161);
  final tdee = bmr * p.activity;
  final adj = p.goal == 'bulk' ? 300 : (p.goal == 'cut' ? -400 : 0);
  final perKg = p.goal == 'bulk' ? 2.0 : (p.goal == 'cut' ? 2.2 : 1.8);
  final kcal = p.kcalGoal ?? roundTo(tdee + adj, 50);
  final protein = p.proteinGoal ?? (w * perKg).round();
  final water = p.waterGoalL != null
      ? (p.waterGoalL! * 1000).round()
      : roundTo(w * 35 + (trainingDay ? 500 : 0), 100);
  // الكربوهيدرات: ما تبقى بعد البروتين و25% دهون من السعرات
  final carbsAuto = math.max(0, ((kcal - protein * 4 - kcal * 0.25) / 4).round());
  final carbs = p.carbsGoal ?? roundTo(carbsAuto.toDouble(), 5);
  return Targets(water, kcal, protein, bmr, tdee, p.complete, carbs);
}

// ======================= الإنجازات =======================

class BadgeInfo {
  final String emoji;
  final String title;
  final String desc;
  final bool unlocked;
  const BadgeInfo(this.emoji, this.title, this.desc, this.unlocked);
}

List<BadgeInfo> computeBadges({
  required int workouts,
  required int bestStreak,
  required double volume,
  required bool planDone,
  required int photos,
  required int prCount,
}) {
  return [
    BadgeInfo('🏁', 'البداية', 'أول تمرين مكتمل', workouts >= 1),
    BadgeInfo('🔥', 'أسبوع كامل', 'سلسلة 7 أيام', bestStreak >= 7),
    BadgeInfo('⚡', 'شهر من الالتزام', 'سلسلة 30 يوماً', bestStreak >= 30),
    BadgeInfo('👑', 'المئة', 'سلسلة 100 يوم', bestStreak >= 100),
    BadgeInfo('💪', '10 تمارين', 'أكملت 10 تمارين', workouts >= 10),
    BadgeInfo('🏋️', '50 تمريناً', 'أكملت 50 تمريناً', workouts >= 50),
    BadgeInfo('🦾', '100 تمرين', 'أكملت 100 تمرين', workouts >= 100),
    BadgeInfo('🏔️', '10 أطنان', 'حجم تدريب 10,000 كغ', volume >= 10000),
    BadgeInfo('🏆', 'رقم قياسي', 'حطمت رقمك الشخصي', prCount >= 1),
    BadgeInfo('📸', 'قبل وبعد', '3 صور تقدم', photos >= 3),
    BadgeInfo('🎉', 'أكملت الخطة', 'وصلت لنهاية الخطة', planDone),
  ];
}

// ======================= التنسيق =======================

const arMonths = [
  'كانون الثاني',
  'شباط',
  'آذار',
  'نيسان',
  'أيار',
  'حزيران',
  'تموز',
  'آب',
  'أيلول',
  'تشرين الأول',
  'تشرين الثاني',
  'كانون الأول'
];
const arDays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد'
];

const enMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String dayName(int weekday) => isAr ? arDays[weekday - 1] : enDays[weekday - 1];

String fmtDate(DateTime d) => isAr
    ? '${arDays[d.weekday - 1]} ${d.day} ${arMonths[d.month - 1]}'
    : '${enDays[d.weekday - 1]}, ${enMonths[d.month - 1]} ${d.day}';
String fmtShort(DateTime d) => '${d.day}/${d.month}';
String fmtShortKey(String k) {
  final d = tryParseKey(k);
  return d == null ? k : fmtShort(d);
}

String fmtTime(int minutes) {
  final m = ((minutes % 1440) + 1440) % 1440;
  final h = m ~/ 60;
  final mm = m % 60;
  final ap = isAr ? (h >= 12 ? 'م' : 'ص') : (h >= 12 ? 'PM' : 'AM');
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${mm.toString().padLeft(2, '0')} $ap';
}

String fmtClock(int sec) {
  final s = math.max(0, sec);
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

String fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(1);
}

String fmtLiters(int ml) {
  if (ml % 1000 == 0) return '${ml ~/ 1000}';
  if (ml % 100 == 0) return (ml / 1000).toStringAsFixed(1);
  return (ml / 1000).toStringAsFixed(2);
}
