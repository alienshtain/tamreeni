// الإشعارات + الأصوات + الاهتزاز.
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'engine.dart';
import 'i18n.dart';
import 'models.dart';
import 'store.dart';

// ======================= الأصوات والاهتزاز =======================
class Sfx {
  static final Map<String, AudioPlayer> _players = {};

  static Future<void> play(String name) async {
    if (!store.data.settings.sound) return;
    try {
      final p = _players.putIfAbsent(name, () => AudioPlayer());
      await p.stop();
      await p.play(AssetSource('sounds/$name.wav'));
    } catch (e) {
      debugPrint('sfx error: $e');
    }
  }

  static void tick() {
    play('tick');
    if (store.data.settings.vibrate) HapticFeedback.selectionClick();
  }

  static void setDone() {
    play('beep');
    if (store.data.settings.vibrate) HapticFeedback.heavyImpact();
  }

  static void restEnd() {
    play('rest_end');
    if (store.data.settings.vibrate) {
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 300), HapticFeedback.vibrate);
    }
  }

  static void finished() {
    play('done');
    if (store.data.settings.vibrate) HapticFeedback.vibrate();
  }

  static void light() {
    if (store.data.settings.vibrate) HapticFeedback.lightImpact();
  }
}

// ======================= الإشعارات =======================
class _Planned {
  final DateTime date;
  final DayType type;
  final bool missedStyle;
  _Planned(this.date, this.type, this.missedStyle);
}

// رسائل تحفيزية عشوائية: [عربي، إنكليزي، تحتاج رقم السلسلة؟]
const List<List<Object>> _motivation = [
  ['🔥 سلسلتك {n} يوم... لا تكسرها! ابدأ تمرين اليوم.', '🔥 Your streak is {n} days... don\'t break it! Start today\'s workout.', true],
  ['💪 دقائق قليلة تفصلك عن إنجاز اليوم. هيا!', '💪 Just a few minutes away from today\'s win. Let\'s go!', false],
  ['الجسم الذي تريده يُبنى بالتكرار. تمرينك بانتظارك.', 'The body you want is built by repetition. Your workout is waiting.', false],
  ['⏰ تأخرت قليلاً لكن ما زال الوقت مناسباً. ابدأ الآن!', '⏰ A little late, but there is still time. Start now!', false],
  ['أصعب خطوة هي البداية. افتح التطبيق وابدأ أول مجموعة.', 'The hardest step is the first one. Open the app and start your first set.', false],
  ['لا تؤجل! كل يوم تفوّته يؤخر هدفك يوماً.', 'Don\'t postpone! Every skipped day delays your goal by a day.', false],
  ['🏆 الأبطال يتمرنون حتى عندما لا يرغبون. أنت منهم.', '🏆 Champions train even when they don\'t feel like it. You are one of them.', false],
  ['مجموعة واحدة فقط... وستكمل الباقي. جرّب!', 'Just one set... and you\'ll finish the rest. Try it!', false],
  ['🌟 التزامك اليوم هو فخرك غداً.', '🌟 Today\'s discipline is tomorrow\'s pride.', false],
  ['سلسلة {n} يوم تستحق الحماية 🔥 تمرين سريع الآن؟', 'A {n}-day streak is worth protecting 🔥 Quick workout now?', true],
  ['😴 الأريكة ستبقى مكانها، أما سلسلتك فلا! قم وتمرن.', '😴 The couch will wait, your streak won\'t! Get up and train.', false],
  ['🚀 أنت أقرب إلى هدفك مما تظن. تمرين اليوم يقرّبك أكثر.', '🚀 You are closer to your goal than you think. Today\'s workout gets you closer.', false],
];

String randomMotivation(int streak, math.Random rnd) {
  final pool = _motivation.where((m) => m[2] == false || streak > 0).toList();
  final m = pool[rnd.nextInt(pool.length)];
  final text = isAr ? m[0] as String : m[1] as String;
  return text.replaceAll('{n}', '$streak');
}

class Notifier {
  static final FlutterLocalNotificationsPlugin _p =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const NotificationDetails _workoutDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'workout_channel',
      'Workout reminders / تذكير التمرين',
      channelDescription: 'Alert at your workout time',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  static const NotificationDetails _medDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'med_channel',
      'Medication reminders / تذكير الأدوية',
      channelDescription: 'Reminders to take your medication',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  static const NotificationDetails _nudgeDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'nudge_channel',
      'Motivation / تحفيز',
      channelDescription: 'Motivational nudges when you are late for your workout',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static const NotificationDetails _waterDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'water_channel',
      'Water reminders / تذكير الماء',
      channelDescription: 'Reminders to drink water',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _p.initialize(settings);
      _ready = true;
    } catch (e) {
      debugPrint('notification init failed: $e');
    }
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android => _p
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  static Future<bool> requestPermission() async {
    try {
      final ok = await _android?.requestNotificationsPermission();
      return ok ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> showTest() async {
    if (!_ready) return;
    await _p.show(
        1,
        t2('تمريني 💪', 'Tamreeni 💪'),
        t2('الإشعارات تعمل بشكل صحيح ✅', 'Notifications are working ✅'),
        _workoutDetails);
  }

  /// أيام التمرين القادمة حسب الجدول المتحرك.
  static List<_Planned> _project(Plan plan, DateTime now, int days) {
    final st = simulate(plan, now);
    final today = dateOnly(now);
    final out = <_Planned>[];
    if (st.finished) return out;
    final total = plan.totalDays;
    final start = dateOnly(plan.startDate);

    if (!st.started || !plan.shiftOnMiss) {
      for (var i = 0; i < days; i++) {
        final date = addDays(today, i);
        final slot = daysBetween(start, date);
        if (slot < 0) continue;
        if (slot >= total) break;
        if (i == 0 && st.todayDone) continue;
        final type = plan.typeAt(slot);
        if (!type.isRest) out.add(_Planned(date, type, false));
      }
      return out;
    }

    final base = st.workoutSlot;
    for (var i = 0; i < days; i++) {
      final date = addDays(today, i);
      if (i == 0) {
        if (!st.todayDone && st.isTrainingToday) {
          out.add(_Planned(date, st.todayType!, false));
        }
        continue;
      }
      int slot;
      if (st.todayDone) {
        slot = st.completed + (i - 1);
      } else if (st.restToday) {
        slot = base + i;
      } else {
        if (i <= 3 && st.todayType != null) {
          out.add(_Planned(date, st.todayType!, true));
        }
        continue;
      }
      if (slot >= total) break;
      final type = plan.typeAt(slot);
      if (!type.isRest) out.add(_Planned(date, type, false));
    }
    return out;
  }

  static Future<void> reschedule() async {
    if (!_ready) return;
    try {
      await _p.cancelAll();
      final s = store.data.settings;
      final plan = store.plan;
      final canExact = (await _android?.canScheduleExactNotifications()) ?? false;
      final mode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      final now = DateTime.now();
      final rnd = math.Random();
      final trainingDates = <String>{};
      final streak = plan == null ? 0 : simulate(plan, now).streak;

      if (plan != null) {
        final planned = _project(plan, now, 10);
        for (final pl in planned) {
          trainingDates.add(dateKey(pl.date));
        }
        var n = 0;
        for (final pl in planned) {
          final when = DateTime(pl.date.year, pl.date.month, pl.date.day)
              .add(Duration(minutes: s.workoutMinutes));
          final typeName = tr(pl.type.name);
          if (s.notifyWorkout && when.isAfter(now)) {
            final count = pl.type.items.where((e) => e.role == 'main').length;
            final title = pl.missedStyle
                ? t2('⏰ تمرينك ما زال بانتظارك', '⏰ Your workout is still waiting')
                : t2('💪 حان وقت التمرين', '💪 Time to train');
            final body = pl.missedStyle
                ? t2('لم تكمل تمرين ${pl.type.name} بعد. ابدأ الآن حتى لا يتأخر جدولك.',
                    'You have not finished $typeName yet. Start now so your plan does not fall behind.')
                : t2('${pl.type.emoji} يوم ${pl.type.name} • $count تمارين. جاهز؟',
                    '${pl.type.emoji} $typeName day • $count exercises. Ready?');
            await _p.zonedSchedule(
              100 + n,
              title,
              body,
              tz.TZDateTime.from(when, tz.local),
              _workoutDetails,
              androidScheduleMode: mode,
            );
          }
          // تنبيه تحفيزي عشوائي إذا تأخر عن وقت التمرين
          if (s.streakNudge && !pl.missedStyle) {
            final late = when.add(Duration(minutes: s.lateNudgeMin));
            if (late.isAfter(now)) {
              await _p.zonedSchedule(
                300 + n,
                streak > 0
                    ? t2('🔥 سلسلتك $streak يوم في خطر', '🔥 Your $streak-day streak is at risk')
                    : t2('💪 حان وقت البدء', '💪 Time to get started'),
                randomMotivation(streak, rnd),
                tz.TZDateTime.from(late, tz.local),
                _nudgeDetails,
                androidScheduleMode: mode,
              );
            }
          }
          n++;
        }
      }

      // تذكير آخر اليوم إذا لم يُنجز تمرين اليوم
      if (plan != null && s.notifyWorkout) {
        final st = simulate(plan, now);
        if (st.isTrainingToday && !st.todayDone) {
          final t = dateOnly(now);
          final lateMin = math.max(s.workoutMinutes + 180, 21 * 60);
          if (lateMin <= 23 * 60 + 30) {
            final when = t.add(Duration(minutes: lateMin));
            if (when.isAfter(now)) {
              final typeName = tr(st.todayType!.name);
              await _p.zonedSchedule(
                99,
                t2('🌙 لم تتمرن اليوم بعد', '🌙 You have not trained today'),
                t2('ما زال أمامك وقت. هل تريد التعويض الآن؟ تمرين ${st.todayType!.name} بانتظارك.',
                    'There is still time. Want to make it up now? $typeName is waiting.'),
                tz.TZDateTime.from(when, tz.local),
                _workoutDetails,
                androidScheduleMode: mode,
              );
            }
          }
        }
      }

      if (s.waterReminders) {
        for (var i = 0; i < 7; i++) {
          final date = addDays(dateOnly(now), i);
          final training = trainingDates.contains(dateKey(date));
          final t = computeTargets(store.data.profile, trainingDay: training);
          var k = 0;
          for (var m = s.waterFrom;
              m <= s.waterTo && k < 12;
              m += s.waterEveryMin) {
            final when = DateTime(date.year, date.month, date.day)
                .add(Duration(minutes: m));
            if (!when.isAfter(now)) continue;
            await _p.zonedSchedule(
              1000 + i * 100 + k,
              t2('💧 وقت شرب الماء', '💧 Time to drink water'),
              t2('هدفك اليوم ${fmtLiters(t.waterMl)} لتر. اشرب كوباً الآن.',
                  'Your goal today is ${fmtLiters(t.waterMl)} L. Have a glass now.'),
              tz.TZDateTime.from(when, tz.local),
              _waterDetails,
              androidScheduleMode: mode,
            );
            k++;
          }
        }
      }

      // تذكير الأدوية (حتى 7 أيام، بحد أقصى للإشعارات)
      final doses = <Dose>[];
      for (var i = 0; i < 7; i++) {
        for (final d in store.dosesOn(addDays(dateOnly(now), i))) {
          if (d.med.reminder && d.status.isEmpty && d.when.isAfter(now)) {
            doses.add(d);
          }
        }
      }
      doses.sort((a, b) => a.when.compareTo(b.when));
      var k = 0;
      for (final d in doses.take(150)) {
        final m = d.med;
        final instr = m.instructions.isEmpty ? '' : ' • ${tr(kMedInstr[m.instructions] ?? '')}';
        final body = '${m.dose}$instr'.trim();
        await _p.zonedSchedule(
          20000 + k,
          '${m.emoji} ${t2('موعد دواء', 'Medication time')}: ${m.name}',
          body.isEmpty ? t2('حان وقت الجرعة.', 'It is time for your dose.') : body,
          tz.TZDateTime.from(d.when, tz.local),
          _medDetails,
          androidScheduleMode: mode,
        );
        if (s.medFollowUpMin > 0) {
          await _p.zonedSchedule(
            30000 + k,
            isAr ? '⏰ هل أخذت ${m.name}؟' : '⏰ Did you take ${m.name}?',
            t2('لم تسجّل هذه الجرعة بعد. افتح التطبيق واضغط «تم».',
                'This dose is not logged yet. Open the app and tap “Done”.'),
            tz.TZDateTime.from(d.when.add(Duration(minutes: s.medFollowUpMin)), tz.local),
            _medDetails,
            androidScheduleMode: mode,
          );
        }
        k++;
      }
    } catch (e) {
      debugPrint('reschedule failed: $e');
    }
  }
}
