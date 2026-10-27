// تقويم اليوم: خط زمني عمودي مع مربعات للتمارين والراحة.
import 'package:flutter/material.dart' hide Text;

import '../engine.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'exercise_detail.dart';
import 'plans.dart';
import 'workout.dart';

class TodayScreen extends StatelessWidget {
  final VoidCallback openPlans;
  const TodayScreen({super.key, required this.openPlans});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final st = store.state;
        final plan = store.plan;
        return Scaffold(
          appBar: AppBar(title: const Text('تمرين اليوم')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: _content(context, st, plan),
          ),
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, PlanState? st, Plan? plan) {
    final p = context.pal;
    if (plan == null || st == null) {
      return [
        AppCard(
          child: Column(children: [
            const SizedBox(height: 8),
            const Text('🗓️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Dim('لا توجد خطة. أنشئ خطة لتظهر تمارين اليوم هنا.',
                align: TextAlign.center),
            const SizedBox(height: 14),
            PButton('إنشاء خطة', icon: Icons.add, onTap: openPlans),
          ]),
        ),
      ];
    }
    final date = fmtDate(store.today);
    if (!st.started) {
      return [
        _Info(
            emoji: '⏳',
            title: 'الخطة لم تبدأ بعد',
            sub: 'تبدأ يوم ${fmtDate(plan.startDate)}',
            date: date),
      ];
    }
    if (st.finished && !st.todayDone) {
      return [
        _Info(
            emoji: '🎉',
            title: 'أكملت الخطة!',
            sub: 'يمكنك إنشاء خطة جديدة من قائمة «المزيد».',
            date: date),
      ];
    }
    if (st.restToday) {
      return [
        _Info(
            emoji: '😴',
            title: 'يوم راحة',
            sub: 'الراحة جزء من البناء. نم جيداً، اشرب الماء، وكل بروتيناً كافياً.',
            date: date,
            color: p.blue),
        PButton('أريد التمرن اليوم', icon: Icons.fitness_center, onTap: () async {
          final ok = await confirm(context, 'تحويل الراحة إلى تمرين',
              'سيُستهلك يوم الراحة هذا مع أقرب يوم تمرين، ويستمر الجدول بعدهما بشكل طبيعي.',
              ok: 'نعم، لنتمرن');
          if (ok) store.startBonusToday();
        }),
      ];
    }
    final type = st.todayType!;
    final items = type.items;
    final logsToday = store.logsOn(dateKey(store.today));
    final out = <Widget>[];

    // رأس اليوم
    var total = 0;
    for (final it in items) {
      final e = store.ex(it.exerciseId);
      if (e != null) total += estItemSeconds(e, it);
    }
    final deload = isDeloadWeek(plan, st.workoutSlot);
    out.add(AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(type.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('يوم ${type.name}',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: p.text)),
              Dim(date),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip(p, '🕒 ${fmtTime(store.settings.workoutMinutes)}'),
          _chip(p, '⏱️ ~${(total / 60).round()} د'),
          _chip(p, '📋 ${items.length} عناصر'),
          if (deload) _chip(p, '🪶 أسبوع تخفيف', color: p.blue),
          if (st.bonusToday) _chip(p, '🔁 بدل الراحة', color: p.green),
        ]),
        if (st.consecutiveMissed > 0 && !st.todayDone) ...[
          const SizedBox(height: 10),
          const Dim('ملاحظة: رُحِّل الجدول بسبب الأيام الفائتة، فهذا هو التمرين المستحق عليك.'),
        ],
        const SizedBox(height: 14),
        if (st.todayDone)
          Row(children: [
            Icon(Icons.check_circle, color: p.green),
            const SizedBox(width: 8),
            Text('تم إكمال تمرين اليوم',
                style: TextStyle(
                    color: p.green, fontWeight: FontWeight.w800, fontSize: 16)),
          ])
        else if (items.isEmpty)
          PButton('أضف تمارين لهذا اليوم', icon: Icons.add, onTap: openPlans)
        else
          PButton('ابدأ التمرين',
              icon: Icons.play_arrow_rounded,
              big: true,
              onTap: () => _start(context, 0)),
      ]),
    ));

    // الخط الزمني
    var cursor = store.settings.workoutMinutes.toDouble();
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final e = store.ex(it.exerciseId);
      if (e == null) continue;
      final dur = estItemSeconds(e, it) / 60.0;
      final setsDone =
          logsToday.where((l) => l.exerciseId == e.id).length;
      final done = setsDone >= it.sets;
      rows.add(_TimelineRow(
        time: fmtTime(cursor.round()),
        dot: done ? p.green : (it.role == 'main' ? p.accent : p.blue),
        child: _ExerciseBox(
          ex: e,
          item: it,
          setsDone: setsDone,
          minutes: dur,
          onTap: () => _details(context, e, it, i, st.todayDone),
        ),
      ));
      cursor += dur;
      if (i < items.length - 1) {
        final restSec = it.restSeconds;
        rows.add(_TimelineRow(
          time: '',
          dot: p.line,
          small: true,
          child: _RestBox(text: 'راحة ${restSec >= 60 ? '${(restSec / 60).toStringAsFixed(restSec % 60 == 0 ? 0 : 1)} د' : '$restSec ث'} بين التمارين'),
        ));
        cursor += restSec / 60.0;
      }
    }
    rows.add(_TimelineRow(
      time: fmtTime(cursor.round()),
      dot: p.green,
      last: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text('🏁 نهاية التمرين',
            style: TextStyle(fontWeight: FontWeight.w800, color: p.dim)),
      ),
    ));
    out.add(const SectionTitle('جدول اليوم'));
    out.add(Column(children: rows));

    if (st.todayDone) {
      final s = store.data.sessions
          .where((x) => x.date == dateKey(store.today))
          .toList();
      if (s.isNotEmpty) {
        final x = s.last;
        out.add(AppCard(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat(p, fmtClock(x.durationSec), 'المدة'),
            _stat(p, '${x.sets}', 'مجموعات'),
            _stat(p, x.volume > 0 ? fmtNum(x.volume) : '—', 'الحجم (كغ)'),
          ]),
        ));
      }
    }
    return out;
  }

  static Widget _stat(Pal p, String v, String l) => Column(children: [
        Text(v,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: p.accent)),
        Dim(l, size: 12),
      ]);

  static Widget _chip(Pal p, String t, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: (color ?? p.accent).withAlpha(30),
            borderRadius: BorderRadius.circular(20)),
        child: Text(t,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color ?? p.text)),
      );

  void _start(BuildContext context, int index) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => WorkoutScreen(startIndex: index)));
  }

  void _details(BuildContext context, Exercise e, PlanItem it, int index, bool done) {
    showSheet<void>(context, (ctx) {
      final p = ctx.pal;
      final hist = store.exerciseHistory(e.id);
      final last = hist.isEmpty ? null : hist.last;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            ExIcon(e, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: p.text)),
                Dim('${e.category} • ${kEquipLabels[e.equipment] ?? ''} • ${e.isTime ? 'وقتي' : 'بالعدات'}'),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Text(_target(e, it),
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: p.accent)),
          if (last != null) ...[
            const SizedBox(height: 6),
            Dim('آخر مرة (${fmtShortKey(last.date)}): ' +
                (e.isTime
                    ? '${last.maxSeconds} ثانية'
                    : (last.maxWeight > 0
                        ? '${fmtNum(last.maxWeight)} كغ × ${last.maxReps}'
                        : '${last.maxReps} عدة'))),
          ],
          if (e.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Dim(e.notes),
          ],
          const SizedBox(height: 16),
          PButton('شرح التمرين (فيديو وصور وخطوات)',
              icon: Icons.play_circle_fill,
              style: BtnStyle.tonal,
              onTap: () {
                Navigator.pop(ctx);
                openExerciseDetail(context, e);
              }),
          const SizedBox(height: 10),
          if (!done)
            PButton('بدء هذا التمرين', icon: Icons.play_arrow_rounded, onTap: () {
              Navigator.pop(ctx);
              _start(context, index);
            }),
          if (!done) const SizedBox(height: 10),
          PButton('تعديل المجموعات والأوزان', icon: Icons.tune, style: BtnStyle.outline,
              onTap: () async {
            Navigator.pop(ctx);
            await editPlanItem(context, it, e);
          }),
        ]),
      );
    });
  }

  static String _target(Exercise e, PlanItem it) {
    if (e.isTime) return '${it.sets} × ${it.seconds > 0 ? it.seconds : 30} ثانية';
    final w = e.usesWeight && it.weight > 0 ? ' • ${fmtNum(it.weight)} كغ' : '';
    return '${it.sets} × ${it.reps} عدة$w';
  }
}

// ---------------------------------------------------------------
class _Info extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final String date;
  final Color? color;
  const _Info(
      {required this.emoji,
      required this.title,
      required this.sub,
      required this.date,
      this.color});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      color: (color ?? p.accent).withAlpha(24),
      child: Column(children: [
        const SizedBox(height: 8),
        Text(emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text(title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: p.text)),
        const SizedBox(height: 6),
        Dim(sub, align: TextAlign.center),
        const SizedBox(height: 4),
        Dim(date, size: 12),
      ]),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String time;
  final Color dot;
  final Widget child;
  final bool last;
  final bool small;
  const _TimelineRow({
    required this.time,
    required this.dot,
    required this.child,
    this.last = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 64,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(time,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: p.dim)),
          ),
        ),
        SizedBox(
          width: 22,
          child: Column(children: [
            const SizedBox(height: 16),
            Container(
              width: small ? 8 : 14,
              height: small ? 8 : 14,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            if (!last)
              Expanded(child: Container(width: 3, color: p.line))
            else
              const SizedBox(height: 8),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : (small ? 6 : 10)),
            child: child,
          ),
        ),
      ]),
    );
  }
}

class _ExerciseBox extends StatelessWidget {
  final Exercise ex;
  final PlanItem item;
  final int setsDone;
  final double minutes;
  final VoidCallback onTap;
  const _ExerciseBox({
    required this.ex,
    required this.item,
    required this.setsDone,
    required this.minutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final done = setsDone >= item.sets;
    final main = item.role == 'main';
    final bg = done
        ? p.green.withAlpha(34)
        : (main ? p.surface : p.blue.withAlpha(22));
    return AppCard(
      margin: EdgeInsets.zero,
      color: bg,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(children: [
        ExIcon(ex, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ex.title,
                style: TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.w800, color: p.text)),
            const SizedBox(height: 2),
            Dim(TodayScreen._target(ex, item), size: 12.5),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (done)
            Icon(Icons.check_circle, color: p.green, size: 22)
          else if (setsDone > 0)
            Text('$setsDone/${item.sets}',
                style: TextStyle(
                    color: p.accent, fontWeight: FontWeight.w800, fontSize: 13)),
          Dim('~${minutes.round() < 1 ? 1 : minutes.round()} د', size: 11.5),
        ]),
      ]),
    );
  }
}

class _RestBox extends StatelessWidget {
  final String text;
  const _RestBox({required this.text});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: p.blue.withAlpha(26), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Text('⏸', style: TextStyle(fontSize: 13, color: p.blue)),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: p.blue)),
      ]),
    );
  }
}
