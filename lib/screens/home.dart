import 'package:flutter/material.dart' hide Text;

import '../engine.dart';
import '../i18n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'meals.dart';
import 'meds.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback goToday;
  final VoidCallback goBody;
  final VoidCallback openPlans;
  const HomeScreen({
    super.key,
    required this.goToday,
    required this.goBody,
    required this.openPlans,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final st = store.state;
        final plan = store.plan;
        return Scaffold(
          appBar: AppBar(title: const Text('الرئيسية')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              const _WaterCard(),
              const _FoodCard(),
              const MedsCard(),
              if (!store.data.profile.complete) _ProfileHint(onTap: goBody),
              if (plan == null || st == null)
                _NoPlan(onCreate: openPlans)
              else ...[
                _TodayCard(st: st, plan: plan, goToday: goToday),
                _ProgressCard(st: st, plan: plan),
                if (store.showMissedPrompt) _MissedPrompt(st: st),
                _GridCard(st: st),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------
class _NoPlan extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoPlan({required this.onCreate});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        const SizedBox(height: 8),
        const Text('🏋️', style: TextStyle(fontSize: 54)),
        const SizedBox(height: 8),
        Text('لا توجد خطة بعد',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.pal.text)),
        const SizedBox(height: 6),
        const Dim('أنشئ خطتك من قالب جاهز أو استورد ملفاً جهّزه لك ذكاء اصطناعي.',
            align: TextAlign.center),
        const SizedBox(height: 16),
        PButton('إنشاء خطة', icon: Icons.add, onTap: onCreate),
      ]),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final PlanState st;
  final Plan plan;
  final VoidCallback goToday;
  const _TodayCard({required this.st, required this.plan, required this.goToday});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    String emoji;
    String title;
    String sub;
    Color tint = p.accent;
    String? action;
    if (!st.started) {
      emoji = '⏳';
      title = 'الخطة لم تبدأ بعد';
      sub = 'تبدأ بعد ${st.startsInDays} يوم (${fmtDate(plan.startDate)})';
    } else if (st.finished) {
      emoji = '🎉';
      title = 'أكملت الخطة!';
      sub = 'مبروك، يمكنك إنشاء خطة جديدة أو إعادة هذه الخطة.';
      tint = p.green;
    } else if (st.todayDone) {
      emoji = '✅';
      title = 'أنهيت تمرين اليوم';
      sub = 'أحسنت! استرح وتغذَّ جيداً، وموعدنا غداً.';
      tint = p.green;
    } else if (st.restToday) {
      emoji = '😴';
      title = 'اليوم راحة';
      sub = 'العضلات تنمو أثناء الراحة. اشرب الماء وكل البروتين.';
      tint = p.blue;
      action = 'أريد التمرن اليوم';
    } else {
      final t = st.todayType!;
      final mains = t.items.where((e) => e.role == 'main').length;
      emoji = t.emoji;
      title = 'اليوم: ${t.name}';
      sub = '$mains تمارين أساسية • الوقت ${fmtTime(store.settings.workoutMinutes)}';
      action = 'افتح تمرين اليوم';
    }
    return AppCard(
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: tint.withAlpha(36), borderRadius: BorderRadius.circular(20)),
          child: Text(emoji, style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800, color: p.text)),
            const SizedBox(height: 4),
            Dim(sub),
            if (action != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GestureDetector(
                  onTap: goToday,
                  child: Text('$action ‹',
                      style: TextStyle(
                          color: p.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final PlanState st;
  final Plan plan;
  const _ProgressCard({required this.st, required this.plan});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final pct = (st.progress * 100).floor();
    final remaining = (st.total - st.completed).clamp(0, 100000);
    Widget stat(String v, String l, Color c) => Expanded(
          child: Column(children: [
            Text(v,
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
            Dim(l, size: 12),
          ]),
        );
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(plan.name,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
          ),
          Text('$pct%',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: p.accent)),
        ]),
        const SizedBox(height: 4),
        Dim('${st.completed} من ${st.total} يوم'
            '${st.missed > 0 ? ' • أُضيف ${st.missed} للتعويض' : ''}'),
        const SizedBox(height: 12),
        BarProgress(value: st.progress),
        const SizedBox(height: 16),
        Row(children: [
          stat('${st.doneCount}', 'تمرنت', p.green),
          stat('${st.missed}', 'فائت', p.red),
          stat('$remaining', 'متبقي', p.blue),
          stat('${st.streak}', 'سلسلة 🔥', p.accent),
        ]),
      ]),
    );
  }
}

class _MissedPrompt extends StatelessWidget {
  final PlanState st;
  const _MissedPrompt({required this.st});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      color: p.red.withAlpha(30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('فاتك ${st.consecutiveMissed} أيام متتالية 😟',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
        const SizedBox(height: 6),
        const Dim(
            'هل تريد إعادة ترتيب الخطة وبدءها من اليوم، أم الاستمرار كما هي؟'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: PButton('أعد البدء من اليوم', onTap: () async {
              final ok = await confirm(context, 'إعادة بدء الخطة',
                  'ستبدأ الخطة من اليوم الأول مع الاحتفاظ بسجل أوزانك وتمارينك.',
                  ok: 'أعد البدء');
              if (ok) store.restartPlan();
            }),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: PButton('استمر كما هي',
                  style: BtnStyle.tonal, onTap: store.snoozeMissedPrompt)),
        ]),
      ]),
    );
  }
}

class _GridCard extends StatelessWidget {
  final PlanState st;
  const _GridCard({required this.st});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('أيام الخطة'),
        DayGrid(state: st),
        const SizedBox(height: 14),
        const GridLegend(),
      ]),
    );
  }
}

class _ProfileHint extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileHint({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      onTap: onTap,
      color: p.accent.withAlpha(28),
      child: Row(children: [
        const Text('📏', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        const Expanded(
            child: Dim(
                'أدخل عمرك وطولك ووزنك ليحسب التطبيق احتياجك من الماء والسعرات والبروتين.')),
        Icon(fwdIcon(), color: p.dim),
      ]),
    );
  }
}

// ======================= الماء =======================
class _WaterCard extends StatelessWidget {
  const _WaterCard();
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final goal = store.targets.waterMl;
    final cur = store.waterMl(store.today);
    final pr = goal <= 0 ? 0.0 : cur / goal;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          WaterCup(
            progress: pr,
            child: Text('${(pr * 100).floor()}%',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: pr > 0.45 ? Colors.white : p.text)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الماء 💧',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
              const SizedBox(height: 6),
              Text('${fmtLiters(cur)} / ${fmtLiters(goal)} لتر',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: p.blue)),
              const SizedBox(height: 4),
              Dim(cur >= goal ? 'أحسنت! وصلت هدفك 🎉' : 'متبقي ${fmtLiters(goal - cur)} لتر'),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Pill('+0.2 لتر', onTap: () => store.addWater(200)),
          Pill('+0.5 لتر', onTap: () => store.addWater(500)),
          Pill('+ مخصص', onTap: () async {
            final v = await askNumber(context, 'كمية الماء', 0, suffix: 'لتر');
            if (v != null && v > 0 && v <= 10) store.addWater((v * 1000).round());
          }),
          Pill('تراجع', onTap: store.undoWater),
        ]),
      ]),
    );
  }
}

// ======================= الأكل =======================
class _FoodCard extends StatelessWidget {
  const _FoodCard();
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = store.targets;
    final kcal = store.kcalOf(store.today);
    final prot = store.proteinOf(store.today);
    final carbs = store.carbsOf(store.today);
    final pr = t.kcal <= 0 ? 0.0 : kcal / t.kcal;
    final entries = store.foodOf(store.today);
    Widget macro(String label, int cur, int goal, Color c) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            Expanded(
                child: BarProgress(
                    value: goal <= 0 ? 0 : cur / goal, color: c, height: 10)),
            const SizedBox(width: 8),
            Text('$cur/$goal${tr('غ')}',
                style: TextStyle(fontSize: 12, color: p.dim)),
            const SizedBox(width: 6),
            SizedBox(width: 58, child: Dim(label, size: 11)),
          ]),
        );
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          FoodBowl(
            progress: pr,
            child: Text('${(pr * 100).floor()}%',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: p.text)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('السعرات 🍽️',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
              const SizedBox(height: 6),
              Text('$kcal / ${t.kcal}',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: p.amber)),
              const Dim('سعرة حرارية'),
              const SizedBox(height: 4),
              macro('البروتين', prot, t.protein, p.green),
              macro('الكربوهيدرات', carbs, t.carbs, p.blue),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        PButton('إضافة وجبة', icon: Icons.add, style: BtnStyle.tonal,
            onTap: () => showAddMealSheet(context)),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final e in entries.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.name.isEmpty ? 'وجبة' : e.name,
                      style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
                  Dim(macroLine(e.kcal, e.protein, e.carbs, e.fat), size: 12),
                ])),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => store.removeFood(e.ts),
                  child: Icon(Icons.close, size: 18, color: p.dim),
                ),
              ]),
            ),
        ],
      ]),
    );
  }
}
