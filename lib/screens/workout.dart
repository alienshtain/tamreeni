// شاشة التمرين: عداد العدات الدائري، مؤقت الوقتي، مؤقت الراحة، أصوات.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../engine.dart';
import '../models.dart';
import '../services.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'exercise_detail.dart';

enum Phase { ready, reps, timed, rest, done }

Future<void> openYoutube(BuildContext context, String url) async {
  var u = url.trim();
  if (u.isEmpty) return;
  if (!u.startsWith('http')) u = 'https://$u';
  try {
    final ok = await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) toast(context, 'تعذر فتح الرابط');
  } catch (_) {
    if (context.mounted) toast(context, 'تعذر فتح الرابط');
  }
}

class WorkoutScreen extends StatefulWidget {
  final int startIndex;
  const WorkoutScreen({super.key, this.startIndex = 0});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late List<RunItem> items;
  int idx = 0;
  int setNo = 1;
  Phase phase = Phase.ready;

  int repCount = 0;
  bool autoOn = false;
  int interval = 10;
  double elapsed = 0;

  double timedRemaining = 0;
  double timedTotal = 0;

  double restRemaining = 0;
  double restTotal = 0;
  int nextIdx = 0;
  int nextSet = 1;

  bool paused = false;
  bool _modal = false;
  int _lastBeepSec = -1;

  late DateTime startedAt;
  final List<SetLog> logs = [];
  final Map<String, double> weights = {};
  SessionSummary? summary;

  Timer? _timer;
  DateTime _last = DateTime.now();

  RunItem get cur => items[idx];

  @override
  void initState() {
    super.initState();
    items = store.buildRunItems();
    startedAt = DateTime.now();
    idx = items.isEmpty ? 0 : clampI(widget.startIndex, 0, items.length - 1);
    autoOn = store.settings.autoCount;
    interval = store.settings.autoInterval;
    for (final it in items) {
      weights.putIfAbsent(it.ex.id, () => it.weight);
    }
    if (store.settings.keepAwake) {
      try {
        WakelockPlus.enable();
      } catch (_) {}
    }
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  // ---------------- المؤقت ----------------
  void _tick() {
    final now = DateTime.now();
    final dt = now.difference(_last).inMilliseconds / 1000.0;
    _last = now;
    if (!mounted || paused || _modal || items.isEmpty) return;
    switch (phase) {
      case Phase.reps:
        if (autoOn) {
          elapsed += math.min(dt, 1.0);
          if (elapsed >= interval) {
            elapsed = 0;
            _addRep();
          } else {
            setState(() {});
          }
        }
        break;
      case Phase.timed:
        timedRemaining -= dt;
        _countdownBeep(timedRemaining);
        if (timedRemaining <= 0) {
          timedRemaining = 0;
          _finishSet();
        } else {
          setState(() {});
        }
        break;
      case Phase.rest:
        restRemaining -= dt;
        _countdownBeep(restRemaining);
        if (restRemaining <= 0) {
          restRemaining = 0;
          _endRest(sound: true);
        } else {
          setState(() {});
        }
        break;
      default:
        break;
    }
  }

  void _countdownBeep(double remaining) {
    final s = remaining.ceil();
    if (s >= 1 && s <= 3 && s != _lastBeepSec) {
      _lastBeepSec = s;
      Sfx.tick();
    }
  }

  // ---------------- المجموعات ----------------
  int get _targetReps => cur.reps > 0 ? cur.reps : 10;
  int get _targetSecs => cur.seconds > 0 ? cur.seconds : 30;

  void _startSet() {
    setState(() {
      paused = false;
      _lastBeepSec = -1;
      repCount = 0;
      elapsed = 0;
      if (cur.ex.isTime) {
        timedTotal = _targetSecs.toDouble();
        timedRemaining = timedTotal;
        phase = Phase.timed;
      } else {
        phase = Phase.reps;
      }
    });
    Sfx.light();
  }

  void _addRep() {
    repCount++;
    elapsed = 0;
    Sfx.tick();
    if (autoOn && repCount >= _targetReps) {
      _finishSet();
    } else {
      setState(() {});
    }
  }

  void _removeRep() {
    if (repCount > 0) setState(() => repCount--);
  }

  Future<void> _finishSet() async {
    if (_modal) return;
    final it = cur;
    final isTime = it.ex.isTime;
    final secs = isTime ? (timedTotal - timedRemaining).round() : 0;
    final reps = isTime ? 0 : repCount;
    SetLog? log;
    if (reps > 0 || secs > 0) {
      log = SetLog(
        date: dateKey(store.today),
        exerciseId: it.ex.id,
        setNo: setNo,
        reps: reps,
        seconds: secs,
        weight: it.ex.usesWeight ? (weights[it.ex.id] ?? 0) : 0,
      );
      logs.add(log);
      store.addLog(log);
    }
    Sfx.setDone();
    final lastSet = setNo >= it.sets;

    if (lastSet && it.isMain && log != null && store.settings.askRpe && mounted) {
      _modal = true;
      paused = true;
      await _askRpe(log);
      _modal = false;
      paused = false;
      _last = DateTime.now();
    }
    if (!mounted) return;

    if (!lastSet) {
      nextIdx = idx;
      nextSet = setNo + 1;
      _startRest(it.rest);
    } else if (idx + 1 < items.length) {
      nextIdx = idx + 1;
      nextSet = 1;
      _startRest(math.max(it.rest, it.isMain ? 60 : 10));
    } else {
      _complete();
    }
  }

  void _startRest(int seconds) {
    setState(() {
      phase = Phase.rest;
      restTotal = math.max(5, seconds).toDouble();
      restRemaining = restTotal;
      paused = false;
      _lastBeepSec = -1;
    });
  }

  void _endRest({required bool sound}) {
    if (sound) Sfx.restEnd();
    setState(() {
      idx = nextIdx;
      setNo = nextSet;
      phase = Phase.ready;
      paused = false;
    });
  }

  void _skipExercise() {
    if (idx + 1 < items.length) {
      setState(() {
        idx++;
        setNo = 1;
        phase = Phase.ready;
      });
    } else {
      _complete();
    }
  }

  void _complete() {
    final s = store.completeSession(items, logs, startedAt);
    Sfx.finished();
    setState(() {
      summary = s;
      phase = Phase.done;
    });
  }

  Future<void> _askRpe(SetLog log) async {
    var rpe = 0;
    final noteCtl = TextEditingController();
    await showSheet<void>(context, (ctx) {
      final p = ctx.pal;
      return StatefulBuilder(builder: (ctx, setS) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كيف كان الجهد؟ ${cur.ex.emoji}',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: p.text)),
                const SizedBox(height: 4),
                const Dim('1 = سهل جداً، 10 = لم أستطع إكمال المزيد. (10 يمنع زيادة الحمل تلقائياً)'),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 1; i <= 10; i++)
                    Pill('$i', selected: rpe == i, onTap: () => setS(() => rpe = i)),
                ]),
                const SizedBox(height: 14),
                TextField(
                    controller: noteCtl,
                    decoration: deco(ctx, 'ملاحظة (اختياري)', hint: 'مثال: ألم خفيف في الكتف')),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: PButton('حفظ', onTap: () {
                    log.rpe = rpe;
                    log.note = noteCtl.text.trim();
                    store.changed();
                    Navigator.pop(ctx);
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: PButton('تخطي',
                          style: BtnStyle.tonal, onTap: () => Navigator.pop(ctx))),
                ]),
              ]),
        );
      });
    });
  }

  Future<void> _confirmExit() async {
    if (phase == Phase.done || logs.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _modal = true;
    final choice = await showSheet<String>(context, (ctx) {
      final p = ctx.pal;
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('الخروج من التمرين',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 6),
          const Dim('سجلات المجموعات التي أنهيتها محفوظة في كل الأحوال.'),
          const SizedBox(height: 16),
          PButton('إنهاء الجلسة واعتبار اليوم مكتملاً',
              style: BtnStyle.green, onTap: () => Navigator.pop(ctx, 'finish')),
          const SizedBox(height: 10),
          PButton('خروج بدون إكمال اليوم',
              style: BtnStyle.tonal, onTap: () => Navigator.pop(ctx, 'exit')),
          const SizedBox(height: 10),
          PButton('متابعة التمرين',
              style: BtnStyle.outline, onTap: () => Navigator.pop(ctx, 'stay')),
        ]),
      );
    });
    _modal = false;
    _last = DateTime.now();
    if (!mounted) return;
    if (choice == 'finish') {
      _complete();
    } else if (choice == 'exit') {
      Navigator.pop(context);
    }
  }

  // ---------------- الواجهة ----------------
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (items.isEmpty) {
      return Scaffold(body: Center(child: Dim('لا توجد تمارين اليوم')));
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Column(children: [
            _topBar(p),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [_body(p)],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _topBar(Pal p) {
    final total = items.length;
    final current = phase == Phase.done ? total : (idx + 1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(children: [
        Row(children: [
          RoundIconBtn(Icons.close, onTap: _confirmExit),
          Expanded(
            child: Center(
              child: Text(
                  phase == Phase.done ? 'انتهى التمرين' : 'تمرين $current من $total',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
            ),
          ),
          const SizedBox(width: 44),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: phase == Phase.done || i < idx
                      ? p.green
                      : (i == idx ? p.accent : p.surface2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _body(Pal p) {
    switch (phase) {
      case Phase.ready:
        return _ready(p);
      case Phase.reps:
        return _repsView(p);
      case Phase.timed:
        return _timedView(p);
      case Phase.rest:
        return _restView(p);
      case Phase.done:
        return _doneView(p);
    }
  }

  Widget _header(Pal p, RunItem it, {bool big = true}) {
    return Column(children: [
      Container(
        width: big ? 96 : 64,
        height: big ? 96 : 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: p.surface, borderRadius: BorderRadius.circular(big ? 32 : 22)),
        child: ExIcon(it.ex, size: big ? 50 : 34),
      ),
      const SizedBox(height: 12),
      Text(it.ex.title,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: big ? 26 : 20, fontWeight: FontWeight.w900, color: p.text)),
      const SizedBox(height: 6),
      Wrap(alignment: WrapAlignment.center, spacing: 6, children: [
        _badge(p, kRoleLabels[it.item.role] ?? 'أساسي', p.surface2, p.dim),
        _badge(p, it.ex.category, p.surface2, p.dim),
        if (it.deload) _badge(p, 'أسبوع تخفيف', p.blue.withAlpha(40), p.blue),
      ]),
    ]);
  }

  Widget _badge(Pal p, String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(t,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
      );

  Widget _ready(Pal p) {
    final it = cur;
    final isTime = it.ex.isTime;
    return Column(children: [
      const SizedBox(height: 12),
      _header(p, it),
      const SizedBox(height: 18),
      AppCard(
        child: Column(children: [
          Text('المجموعة $setNo من ${it.sets}',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: p.accent)),
          const SizedBox(height: 6),
          Text(isTime ? 'المدة: $_targetSecs ثانية' : 'الهدف: $_targetReps عدة',
              style: TextStyle(fontSize: 18, color: p.text, fontWeight: FontWeight.w700)),
          if (it.ex.usesWeight) ...[
            const SizedBox(height: 14),
            Divider(color: p.line, height: 1),
            const SizedBox(height: 14),
            const Dim('الوزن المستخدم'),
            const SizedBox(height: 6),
            NumStepper(
              value: weights[it.ex.id] ?? 0,
              step: 0.5,
              decimal: true,
              unit: 'كغ',
              onChanged: (v) => setState(() => weights[it.ex.id] = v),
            ),
          ],
          if (it.ex.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Dim(it.ex.notes, align: TextAlign.center),
          ],
        ]),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PButton('شرح التمرين (فيديو وصور وخطوات)',
            icon: Icons.play_circle_fill,
            style: BtnStyle.tonal,
            onTap: () => openExerciseDetail(context, it.ex)),
      ),
      PButton('ابدأ المجموعة', icon: Icons.play_arrow_rounded, big: true, onTap: _startSet),
      const SizedBox(height: 10),
      PButton('تخطي هذا التمرين', style: BtnStyle.outline, onTap: _skipExercise),
    ]);
  }

  Widget _repsView(Pal p) {
    final it = cur;
    final pr = autoOn ? (elapsed / interval) : (repCount / _targetReps);
    return Column(children: [
      _header(p, it, big: false),
      const SizedBox(height: 4),
      Text('المجموعة $setNo من ${it.sets}',
          style: TextStyle(fontWeight: FontWeight.w800, color: p.accent, fontSize: 16)),
      const SizedBox(height: 18),
      GestureDetector(
        onTap: _addRep,
        child: Ring(
          size: 270,
          stroke: 18,
          progress: pr,
          color: autoOn ? p.accent : p.green,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$repCount',
                style: TextStyle(
                    fontSize: 96,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: p.text)),
            Dim('من $_targetReps عدة', size: 15),
            if (it.ex.usesWeight)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${fmtNum(weights[it.ex.id] ?? 0)} كغ',
                    style: TextStyle(
                        color: p.accent, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      AppCard(
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Text('العد التلقائي',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15, color: p.text)),
            ),
            Switch(
              value: autoOn,
              onChanged: (v) {
                setState(() {
                  autoOn = v;
                  elapsed = 0;
                });
                store.settings.autoCount = v;
                store.changed();
              },
            ),
          ]),
          if (autoOn) ...[
            Dim('تُحسب عدة كل $interval ثانية على افتراض أنك أكملتها'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in const [3, 5, 8, 10, 15, 20, 30, 45, 60])
                Pill('$s ث', selected: interval == s, onTap: () {
                  setState(() {
                    interval = s;
                    elapsed = 0;
                  });
                  store.settings.autoInterval = s;
                  store.changed();
                }),
            ]),
          ] else
            const Dim('اضغط على الدائرة أو زر +1 لتسجيل كل عدة'),
        ]),
      ),
      Row(children: [
        RoundIconBtn(Icons.remove, size: 60, onTap: _removeRep),
        const SizedBox(width: 12),
        Expanded(
            child: PButton('+1 عدة', icon: Icons.add, big: true, onTap: _addRep)),
        const SizedBox(width: 12),
        RoundIconBtn(paused ? Icons.play_arrow : Icons.pause,
            size: 60,
            bg: paused ? p.accent : null,
            fg: paused ? p.onAccent : null,
            onTap: () => setState(() {
                  paused = !paused;
                  _last = DateTime.now();
                })),
      ]),
      const SizedBox(height: 12),
      PButton('إنهاء المجموعة',
          icon: Icons.check_rounded, style: BtnStyle.green, onTap: _finishSet),
    ]);
  }

  Widget _timedView(Pal p) {
    final it = cur;
    final pr = timedTotal <= 0 ? 0.0 : timedRemaining / timedTotal;
    return Column(children: [
      _header(p, it, big: false),
      const SizedBox(height: 4),
      Text('المجموعة $setNo من ${it.sets}',
          style: TextStyle(fontWeight: FontWeight.w800, color: p.accent, fontSize: 16)),
      const SizedBox(height: 18),
      Ring(
        size: 270,
        stroke: 18,
        progress: pr,
        color: paused ? p.dim : p.accent,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(fmtClock(timedRemaining.ceil()),
              style: TextStyle(
                  fontSize: 70,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: p.text)),
          Dim(paused ? 'متوقف مؤقتاً' : 'ثبّت الوضعية 💪', size: 15),
        ]),
      ),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(
          child: PButton(paused ? 'استئناف' : 'إيقاف مؤقت',
              icon: paused ? Icons.play_arrow : Icons.pause,
              style: paused ? BtnStyle.filled : BtnStyle.tonal,
              onTap: () => setState(() {
                    paused = !paused;
                    _last = DateTime.now();
                  })),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PButton('+10 ثوانٍ',
              style: BtnStyle.tonal,
              onTap: () => setState(() {
                    timedRemaining += 10;
                    timedTotal += 10;
                  })),
        ),
      ]),
      const SizedBox(height: 10),
      PButton('إنهاء الآن',
          icon: Icons.check_rounded, style: BtnStyle.green, onTap: _finishSet),
    ]);
  }

  Widget _restView(Pal p) {
    final next = items[nextIdx];
    final sameEx = nextIdx == idx;
    final pr = restTotal <= 0 ? 0.0 : restRemaining / restTotal;
    return Column(children: [
      const SizedBox(height: 12),
      Text('استراحة 😮‍💨',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: p.blue)),
      const SizedBox(height: 16),
      Ring(
        size: 250,
        stroke: 16,
        progress: pr,
        color: paused ? p.dim : p.blue,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(fmtClock(restRemaining.ceil()),
              style: TextStyle(
                  fontSize: 64,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: p.text)),
          Dim(paused ? 'متوقف مؤقتاً' : 'يصدر صوت عند الانتهاء', size: 13),
        ]),
      ),
      const SizedBox(height: 18),
      AppCard(
        child: Row(children: [
          ExIcon(next.ex, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Dim('التالي', size: 12),
              Text(next.ex.title,
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
              Dim(sameEx
                  ? 'المجموعة $nextSet من ${next.sets}'
                  : (next.ex.isTime
                      ? '${next.sets} × ${next.seconds > 0 ? next.seconds : 30} ث'
                      : '${next.sets} × ${next.reps > 0 ? next.reps : 10} عدة')),
            ]),
          ),
        ]),
      ),
      Row(children: [
        Expanded(
          child: PButton('+30 ثانية',
              style: BtnStyle.tonal,
              onTap: () => setState(() {
                    restRemaining += 30;
                    restTotal += 30;
                  })),
        ),
        const SizedBox(width: 10),
        RoundIconBtn(paused ? Icons.play_arrow : Icons.pause,
            size: 48,
            onTap: () => setState(() {
                  paused = !paused;
                  _last = DateTime.now();
                })),
        const SizedBox(width: 10),
        Expanded(
            child: PButton('تخطي', icon: Icons.skip_next, onTap: () => _endRest(sound: false))),
      ]),
    ]);
  }

  Widget _doneView(Pal p) {
    final s = summary;
    Widget stat(String v, String l) => Expanded(
          child: Column(children: [
            Text(v,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900, color: p.accent)),
            Dim(l, size: 12),
          ]),
        );
    return Column(children: [
      const SizedBox(height: 20),
      const Text('🎉', style: TextStyle(fontSize: 72)),
      const SizedBox(height: 8),
      Text('أحسنت! أنهيت تمرين اليوم',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: p.text)),
      const SizedBox(height: 18),
      if (s != null)
        AppCard(
          child: Row(children: [
            stat(fmtClock(s.durationSec), 'المدة'),
            stat('${s.sets}', 'مجموعات'),
            stat(s.volume > 0 ? fmtNum(s.volume) : '—', 'حجم (كغ)'),
            stat('${s.streak}', 'سلسلة 🔥'),
          ]),
        ),
      if (s != null && s.prs.isNotEmpty)
        AppCard(
          color: p.amber.withAlpha(36),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🏆 أرقام قياسية جديدة',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
            const SizedBox(height: 8),
            for (final t in s.prs)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(t, style: TextStyle(color: p.text, fontSize: 15))),
          ]),
        ),
      if (s != null && s.bumps.isNotEmpty)
        AppCard(
          color: p.green.withAlpha(30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📈 زيادة الحمل في الجلسة القادمة',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
            const SizedBox(height: 8),
            for (final t in s.bumps)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(t, style: TextStyle(color: p.text, fontSize: 15))),
          ]),
        ),
      const SizedBox(height: 8),
      PButton('تم', big: true, onTap: () => Navigator.pop(context)),
    ]);
  }
}
