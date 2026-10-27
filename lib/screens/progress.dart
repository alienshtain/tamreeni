// التقدم: إحصاءات، مخطط تطور التمرين، 1RM، إنجازات، سجل الجلسات.
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import '../engine.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final st = store.state;
        final best = math.max(store.settings.bestStreak, st?.streak ?? 0);
        final loggedIds = <String>[];
        for (final l in store.data.logs) {
          if (!loggedIds.contains(l.exerciseId)) loggedIds.add(l.exerciseId);
        }
        final exs = loggedIds.map(store.ex).whereType<Exercise>().toList();
        if (exs.isNotEmpty && (selected == null || !exs.any((e) => e.id == selected))) {
          selected = exs.first.id;
        }
        final sel = exs.isEmpty ? null : store.ex(selected ?? '');
        final badges = computeBadges(
          workouts: store.completedWorkouts,
          bestStreak: best,
          volume: store.totalVolume,
          planDone: st?.finished ?? false,
          photos: store.data.photos.length,
          prCount: store.settings.prCount,
        );
        final unlocked = badges.where((b) => b.unlocked).length;

        return Scaffold(
          appBar: AppBar(title: const Text('التقدم')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              AppCard(
                child: Row(children: [
                  _stat(p, '${store.completedWorkouts}', 'تمرين مكتمل'),
                  _stat(p, fmtNum(store.totalVolume / 1000.0), 'طن حجم'),
                  _stat(p, '$best', 'أفضل سلسلة 🔥'),
                  _stat(p, '${store.settings.prCount}', 'أرقام قياسية 🏆'),
                ]),
              ),
              const SectionTitle('تطور التمرين'),
              if (sel == null)
                const AppCard(
                    child: Dim('ابدأ أول تمرين وسيظهر هنا تطور أوزانك وعداتك.'))
              else ...[
                SizedBox(
                  height: 44,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final e in exs)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Pill('${e.emoji} ${e.title}'.trim(),
                            selected: sel.id == e.id,
                            onTap: () => setState(() => selected = e.id)),
                      ),
                  ]),
                ),
                const SizedBox(height: 10),
                _ExerciseChart(ex: sel),
              ],
              SectionTitle('الإنجازات ($unlocked/${badges.length})'),
              AppCard(
                child: Wrap(spacing: 10, runSpacing: 14, children: [
                  for (final b in badges) _Badge(b: b),
                ]),
              ),
              const SectionTitle('آخر الجلسات'),
              if (store.data.sessions.isEmpty)
                const AppCard(child: Dim('لا توجد جلسات مكتملة بعد.'))
              else
                for (final s in store.data.sessions.reversed.take(10))
                  AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      Text(fmtShortKey(s.date),
                          style: TextStyle(
                              fontWeight: FontWeight.w900, color: p.accent)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s.dayName,
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: p.text)),
                      ),
                      Dim('${fmtClock(s.durationSec)} • ${s.sets} مجموعة'
                          '${s.volume > 0 ? ' • ${fmtNum(s.volume)} كغ' : ''}',
                          size: 12),
                    ]),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(Pal p, String v, String l) => Expanded(
        child: Column(children: [
          Text(v,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: p.accent)),
          Dim(l, size: 11, align: TextAlign.center),
        ]),
      );
}

class _ExerciseChart extends StatelessWidget {
  final Exercise ex;
  const _ExerciseChart({required this.ex});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final h = store.exerciseHistory(ex.id);
    final labels = h.map((e) => fmtShortKey(e.date)).toList();
    List<double> main;
    String unit;
    String title;
    if (ex.usesWeight && h.any((e) => e.maxWeight > 0)) {
      main = h.map((e) => e.maxWeight).toList();
      unit = 'كغ';
      title = 'أعلى وزن في كل جلسة';
    } else if (ex.isTime) {
      main = h.map((e) => e.maxSeconds.toDouble()).toList();
      unit = 'ثانية';
      title = 'أطول مدة في كل جلسة';
    } else {
      main = h.map((e) => e.maxReps.toDouble()).toList();
      unit = 'عدة';
      title = 'أعلى عدد عدات في كل جلسة';
    }
    final pr = main.isEmpty ? 0.0 : main.reduce(math.max);
    final e1 = h.map((e) => e.e1rm).fold(0.0, math.max);
    final volumes = h.map((e) => e.volume).toList();

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(title,
                style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: p.amber.withAlpha(36),
                borderRadius: BorderRadius.circular(16)),
            child: Text('🏆 ${fmtNum(pr)} $unit',
                style: TextStyle(fontWeight: FontWeight.w900, color: p.text)),
          ),
        ]),
        const SizedBox(height: 12),
        LineChart(values: main, labels: labels),
        if (ex.usesWeight && e1 > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: p.surface2, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Text('🧮', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    'أقصى وزن تقديري لمرة واحدة (1RM): ${fmtNum(double.parse(e1.toStringAsFixed(1)))} كغ',
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
              ),
            ]),
          ),
        ],
        if (volumes.any((v) => v > 0)) ...[
          const SizedBox(height: 14),
          Text('حجم التمرين في كل جلسة (وزن × عدات)',
              style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 8),
          LineChart(values: volumes, labels: labels, height: 120, color: p.blue),
        ],
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final BadgeInfo b;
  const _Badge({required this.b});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      width: 92,
      child: Opacity(
        opacity: b.unlocked ? 1 : 0.35,
        child: Column(children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: b.unlocked ? p.amber.withAlpha(50) : p.surface2,
                shape: BoxShape.circle),
            child: Text(b.unlocked ? b.emoji : '🔒',
                style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 6),
          Text(b.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: p.text)),
          Dim(b.desc, size: 10.5, align: TextAlign.center),
        ]),
      ),
    );
  }
}
