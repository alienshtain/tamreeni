// الخطط: القائمة، المعالج، محرر الخطة، محرر نوع اليوم، محرر عنصر التمرين.
import 'package:flutter/material.dart' hide Text;

import '../engine.dart';
import '../models.dart';
import '../services.dart';
import '../store.dart';
import '../templates.dart';
import '../theme.dart';
import '../widgets.dart';
import 'exercises.dart';

// ======================= محرر عنصر (مجموعات/عدات/وزن) =======================
Future<void> editPlanItem(BuildContext context, PlanItem it, Exercise ex) {
  return showSheet<void>(context, (ctx) {
    final p = ctx.pal;
    return StatefulBuilder(builder: (ctx, setS) {
      void upd(VoidCallback f) {
        f();
        store.changed();
        setS(() {});
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                ExIcon(ex, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(ex.title,
                      style: TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w900, color: p.text)),
                ),
              ]),
              const SizedBox(height: 14),
              const Dim('دور التمرين في اليوم'),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                for (final e in kRoleLabels.entries)
                  Pill(e.value,
                      selected: it.role == e.key,
                      onTap: () => upd(() => it.role = e.key)),
              ]),
              const SizedBox(height: 10),
              LabeledRow(
                  'عدد المجموعات',
                  NumStepper(
                      value: it.sets.toDouble(),
                      min: 1,
                      max: 20,
                      onChanged: (v) => upd(() => it.sets = v.round()))),
              if (ex.isTime)
                LabeledRow(
                    'مدة المجموعة',
                    NumStepper(
                        value: (it.seconds > 0 ? it.seconds : 30).toDouble(),
                        min: 5,
                        max: 1800,
                        step: 5,
                        unit: 'ثانية',
                        onChanged: (v) => upd(() => it.seconds = v.round())))
              else
                LabeledRow(
                    'عدد العدات',
                    NumStepper(
                        value: it.reps.toDouble(),
                        min: 1,
                        max: 200,
                        onChanged: (v) => upd(() => it.reps = v.round()))),
              LabeledRow(
                  'الراحة بعد المجموعة',
                  NumStepper(
                      value: it.restSeconds.toDouble(),
                      min: 5,
                      max: 600,
                      step: 15,
                      unit: 'ثانية',
                      onChanged: (v) => upd(() => it.restSeconds = v.round()))),
              if (ex.usesWeight) ...[
                LabeledRow(
                    'الوزن الحالي',
                    NumStepper(
                        value: it.weight,
                        min: 0,
                        max: 500,
                        step: 0.5,
                        decimal: true,
                        unit: 'كغ',
                        onChanged: (v) => upd(() => it.weight = v))),
                LabeledRow(
                    'زيادة تلقائية عند النجاح',
                    NumStepper(
                        value: it.increment,
                        min: 0,
                        max: 20,
                        step: 0.5,
                        decimal: true,
                        unit: 'كغ',
                        onChanged: (v) => upd(() => it.increment = v)),
                    sub: 'إذا أكملت كل العدات المطلوبة تزيد في الجلسة القادمة'),
              ],
              const SizedBox(height: 12),
              PButton('تم', onTap: () => Navigator.pop(ctx)),
            ]),
      );
    });
  });
}

PlanItem defaultItemFor(Exercise e) {
  final warm = e.category == 'إحماء';
  final cool = e.category == 'تمدد';
  return PlanItem(
    exerciseId: e.id,
    role: warm ? 'warmup' : (cool ? 'cooldown' : 'main'),
    sets: (warm || cool) ? 1 : 3,
    reps: e.isTime ? 0 : 12,
    seconds: e.isTime ? ((warm || cool) ? 30 : 45) : 0,
    restSeconds: (warm || cool) ? 10 : (e.isTime ? 45 : store.settings.defaultRest),
    weight: 0,
    increment: e.usesWeight ? 2 : 0,
  );
}

String patternText(Plan p) {
  final names = p.pattern.map((id) => p.dayTypeById(id).name).toList();
  return '${names.join(' ← ')} (يتكرر)';
}

// ======================= قائمة الخطط =======================
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final plans = store.data.plans;
        return Scaffold(
          appBar: AppBar(
            title: const Text('خططي'),
            actions: [
              IconButton(
                  onPressed: () => showNewPlanWizard(context),
                  icon: Icon(Icons.add_circle, color: p.accent, size: 30)),
            ],
          ),
          body: plans.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🏋️', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 10),
                      const Dim('لا توجد خطط بعد', size: 15),
                      const SizedBox(height: 14),
                      PButton('إنشاء خطة', icon: Icons.add, onTap: () => showNewPlanWizard(context)),
                    ]),
                  ),
                )
              : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
                  for (final pl in plans) _PlanTile(plan: pl),
                ]),
        );
      },
    );
  }
}

class _PlanTile extends StatelessWidget {
  final Plan plan;
  const _PlanTile({required this.plan});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final active = store.plan?.id == plan.id;
    final st = simulate(plan, DateTime.now());
    return AppCard(
      color: active ? p.accent.withAlpha(24) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(plan.name,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: p.text)),
          ),
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: p.accent, borderRadius: BorderRadius.circular(20)),
              child: Text('نشطة',
                  style: TextStyle(
                      color: p.onAccent, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
        ]),
        const SizedBox(height: 4),
        Dim('${plan.totalDays} يوم • تبدأ ${fmtDate(plan.startDate)}'),
        Dim(patternText(plan), size: 12.5),
        const SizedBox(height: 10),
        BarProgress(value: st.progress, height: 10),
        const SizedBox(height: 4),
        Dim('${(st.progress * 100).floor()}% • فائت ${st.missed}', size: 12),
        const SizedBox(height: 12),
        Row(children: [
          if (!active)
            Expanded(
                child: PButton('تفعيل', onTap: () => store.setActivePlan(plan.id))),
          if (!active) const SizedBox(width: 8),
          Expanded(
            child: PButton('تعديل', style: BtnStyle.tonal, onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PlanEditorScreen(planId: plan.id)));
            }),
          ),
          const SizedBox(width: 8),
          RoundIconBtn(Icons.delete_outline, size: 48, onTap: () async {
            final ok = await confirm(context, 'حذف الخطة',
                'سيتم حذف «${plan.name}». سجل أوزانك وتمارينك السابقة يبقى محفوظاً.',
                ok: 'حذف', danger: true);
            if (ok) store.deletePlan(plan.id);
          }),
        ]),
      ]),
    );
  }
}

// ======================= معالج خطة جديدة =======================
Future<void> showNewPlanWizard(BuildContext context) {
  var tpl = kTemplates.first;
  var equip = 'weights';
  var days = 100;
  var start = store.today;
  var warm = true;
  var stretch = true;
  var shift = true;

  return showSheet<void>(context, (ctx) {
    final p = ctx.pal;
    return StatefulBuilder(builder: (ctx, setS) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('خطة جديدة',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: p.text)),
              const SizedBox(height: 14),
              const Dim('اختر النمط'),
              const SizedBox(height: 8),
              for (final t in kTemplates)
                GestureDetector(
                  onTap: () => setS(() => tpl = t),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tpl.id == t.id ? p.accent.withAlpha(30) : p.surface2,
                      borderRadius: BorderRadius.circular(kRadiusSm + 2),
                      border: Border.all(
                          color: tpl.id == t.id ? p.accent : Colors.transparent,
                          width: 2),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: p.text, fontSize: 15)),
                      Dim(t.desc, size: 12.5),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
              const Dim('نوع التمارين'),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final e in kEquipLabels.entries)
                  Pill(e.value, selected: equip == e.key, onTap: () => setS(() => equip = e.key)),
              ]),
              const SizedBox(height: 14),
              LabeledRow(
                  'مدة الخطة',
                  NumStepper(
                      value: days.toDouble(),
                      min: 7,
                      max: 2000,
                      step: 10,
                      unit: 'يوم',
                      onChanged: (v) => setS(() => days = v.round()))),
              Wrap(spacing: 8, children: [
                for (final d in [30, 60, 100, 150, 200, 365])
                  Pill('$d', selected: days == d, onTap: () => setS(() => days = d)),
              ]),
              const SizedBox(height: 10),
              LabeledRow(
                  'تاريخ البداية',
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: start,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setS(() => start = dateOnly(d));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: p.surface2, borderRadius: BorderRadius.circular(14)),
                      child: Text(fmtDate(start),
                          style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
                    ),
                  )),
              LabeledRow('إضافة إحماء قبل التمرين',
                  Switch(value: warm, onChanged: (v) => setS(() => warm = v))),
              LabeledRow('إضافة تمدد بعد التمرين',
                  Switch(value: stretch, onChanged: (v) => setS(() => stretch = v))),
              LabeledRow(
                  'إزاحة الجدول عند فوات يوم',
                  Switch(value: shift, onChanged: (v) => setS(() => shift = v)),
                  sub: 'إذا فاتك يوم يُعاد نفس التمرين ويُضاف يوم في النهاية'),
              const SizedBox(height: 14),
              PButton('إنشاء الخطة', icon: Icons.check, onTap: () {
                final plan = buildPlanFromTemplate(
                  tpl,
                  equipment: equip,
                  totalDays: days,
                  startDate: start,
                  warmup: warm,
                  stretch: stretch,
                  shiftOnMiss: shift,
                  library: store.data.exercises,
                );
                store.addPlan(plan);
                Navigator.pop(ctx);
                if (tpl.id == 'blank') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PlanEditorScreen(planId: plan.id)));
                }
              }),
            ]),
      );
    });
  });
}

// ======================= محرر الخطة =======================
class PlanEditorScreen extends StatefulWidget {
  final String planId;
  const PlanEditorScreen({super.key, required this.planId});
  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  Plan? get plan {
    for (final p in store.data.plans) {
      if (p.id == widget.planId) return p;
    }
    return null;
  }

  @override
  void dispose() {
    Notifier.reschedule();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final pl = plan;
        if (pl == null) {
          return Scaffold(appBar: AppBar(), body: Center(child: Dim('الخطة غير موجودة')));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('تعديل الخطة')),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LabeledRow(
                    'اسم الخطة',
                    GestureDetector(
                      onTap: () async {
                        final v = await askText(context, 'اسم الخطة', initial: pl.name);
                        if (v != null && v.isNotEmpty) {
                          pl.name = v;
                          store.changed();
                        }
                      },
                      child: Row(children: [
                        Text(pl.name,
                            style: TextStyle(fontWeight: FontWeight.w800, color: p.accent)),
                        const SizedBox(width: 6),
                        Icon(Icons.edit, size: 16, color: p.accent),
                      ]),
                    )),
                LabeledRow(
                    'مدة الخطة',
                    NumStepper(
                        value: pl.totalDays.toDouble(),
                        min: 1,
                        max: 2000,
                        step: 10,
                        unit: 'يوم',
                        onChanged: (v) {
                          pl.totalDays = v.round();
                          store.changed();
                        })),
                LabeledRow(
                    'تاريخ البداية',
                    GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: pl.startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) {
                          pl.startDate = dateOnly(d);
                          store.changed();
                        }
                      },
                      child: Text(fmtDate(pl.startDate),
                          style: TextStyle(fontWeight: FontWeight.w800, color: p.accent)),
                    )),
                LabeledRow(
                    'إزاحة الجدول عند فوات يوم',
                    Switch(
                        value: pl.shiftOnMiss,
                        onChanged: (v) {
                          pl.shiftOnMiss = v;
                          store.changed();
                        }),
                    sub: pl.shiftOnMiss
                        ? 'يُعاد التمرين الفائت ويُضاف يوم للتعويض'
                        : 'الجدول ثابت بالتاريخ، والأيام الفائتة تُحسب فائتة فقط'),
                LabeledRow(
                    'أسبوع تخفيف كل',
                    NumStepper(
                        value: pl.deloadEvery.toDouble(),
                        min: 0,
                        max: 12,
                        unit: pl.deloadEvery == 0 ? 'معطّل' : 'أسابيع',
                        onChanged: (v) {
                          pl.deloadEvery = v.round();
                          store.changed();
                        }),
                    sub: 'أسبوع بحمل أخف لتعافي العضلات (اختياري)'),
              ]),
            ),
            const SectionTitle('نمط الأسبوع'),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Dim('تسلسل الأيام يتكرر طوال مدة الخطة:'),
                const SizedBox(height: 8),
                for (var i = 0; i < pl.pattern.length; i++)
                  _PatternRow(plan: pl, index: i),
                const SizedBox(height: 8),
                PButton('إضافة يوم للنمط', icon: Icons.add, style: BtnStyle.tonal,
                    onTap: () => _addToPattern(context, pl)),
              ]),
            ),
            SectionTitle('أنواع الأيام',
                trailing: TextButton(
                    onPressed: () => _newDayType(context, pl),
                    child: Text('+ جديد',
                        style: TextStyle(color: p.accent, fontWeight: FontWeight.w800)))),
            for (final d in pl.dayTypes)
              AppCard(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DayTypeEditorScreen(planId: pl.id, typeId: d.id))),
                child: Row(children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.name,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
                      Dim(d.isRest ? 'يوم راحة' : '${d.items.length} عناصر', size: 12.5),
                    ]),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: p.dim),
                    onPressed: () async {
                      if (pl.pattern.contains(d.id)) {
                        toast(context, 'هذا اليوم مستخدم في النمط. أزله منه أولاً.');
                        return;
                      }
                      if (pl.dayTypes.length <= 1) {
                        toast(context, 'يجب أن يبقى نوع يوم واحد على الأقل.');
                        return;
                      }
                      final ok = await confirm(context, 'حذف نوع اليوم',
                          'حذف «${d.name}» وكل تمارينه؟', ok: 'حذف', danger: true);
                      if (ok) {
                        pl.dayTypes.removeWhere((x) => x.id == d.id);
                        store.changed();
                      }
                    },
                  ),
                  Icon(fwdIcon(), color: p.dim),
                ]),
              ),
            const SizedBox(height: 8),
            PButton('إعادة بدء هذه الخطة من اليوم', style: BtnStyle.outline, onTap: () async {
              final ok = await confirm(context, 'إعادة البدء',
                  'ستبدأ الخطة من اليوم الأول بتاريخ اليوم. سجل أوزانك يبقى.',
                  ok: 'إعادة البدء');
              if (ok) {
                store.setActivePlan(pl.id);
                store.restartPlan();
              }
            }),
          ]),
        );
      },
    );
  }

  Future<void> _addToPattern(BuildContext context, Plan pl) async {
    final id = await showSheet<String>(context, (ctx) {
      final p = ctx.pal;
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('أي يوم تضيف؟',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: p.text)),
          const SizedBox(height: 12),
          for (final d in pl.dayTypes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PButton('${d.emoji}  ${d.name}',
                  style: BtnStyle.tonal, onTap: () => Navigator.pop(ctx, d.id)),
            ),
        ]),
      );
    });
    if (id != null) {
      pl.pattern.add(id);
      store.changed();
    }
  }

  Future<void> _newDayType(BuildContext context, Plan pl) async {
    final name = await askText(context, 'اسم نوع اليوم', hint: 'مثال: كتف وذراع');
    if (name == null || name.isEmpty) return;
    if (!context.mounted) return;
    final rest = await confirm(context, 'هل هو يوم راحة؟',
        'اختر «نعم» إذا كان يوم راحة بلا تمارين، و«لا» إذا كان يوم تمرين.',
        ok: 'نعم، راحة', cancel: 'لا، تمرين');
    pl.dayTypes.add(DayType(
        id: newId(),
        name: name,
        kind: rest ? 'rest' : 'train',
        emoji: rest ? '😴' : '💪'));
    store.changed();
  }
}

class _PatternRow extends StatelessWidget {
  final Plan plan;
  final int index;
  const _PatternRow({required this.plan, required this.index});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final d = plan.dayTypeById(plan.pattern[index]);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: d.isRest ? p.blue.withAlpha(26) : p.surface2,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Text('${index + 1}',
            style: TextStyle(fontWeight: FontWeight.w900, color: p.dim)),
        const SizedBox(width: 12),
        Text('${d.emoji} ${d.name}',
            style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
        const Spacer(),
        IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.arrow_upward, size: 20, color: p.dim),
            onPressed: index == 0
                ? null
                : () {
                    final x = plan.pattern.removeAt(index);
                    plan.pattern.insert(index - 1, x);
                    store.changed();
                  }),
        IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.arrow_downward, size: 20, color: p.dim),
            onPressed: index >= plan.pattern.length - 1
                ? null
                : () {
                    final x = plan.pattern.removeAt(index);
                    plan.pattern.insert(index + 1, x);
                    store.changed();
                  }),
        IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 20, color: p.red),
            onPressed: plan.pattern.length <= 1
                ? null
                : () {
                    plan.pattern.removeAt(index);
                    store.changed();
                  }),
      ]),
    );
  }
}

// ======================= محرر نوع اليوم =======================
class DayTypeEditorScreen extends StatelessWidget {
  final String planId;
  final String typeId;
  const DayTypeEditorScreen({super.key, required this.planId, required this.typeId});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        Plan? pl;
        for (final x in store.data.plans) {
          if (x.id == planId) pl = x;
        }
        DayType? d;
        if (pl != null) {
          for (final x in pl.dayTypes) {
            if (x.id == typeId) d = x;
          }
        }
        if (pl == null || d == null) {
          return Scaffold(appBar: AppBar(), body: Center(child: Dim('غير موجود')));
        }
        final day = d;
        return Scaffold(
          appBar: AppBar(title: Text('${day.emoji} ${day.name}')),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
            AppCard(
              child: Column(children: [
                LabeledRow(
                    'الاسم',
                    GestureDetector(
                      onTap: () async {
                        final v = await askText(context, 'اسم اليوم', initial: day.name);
                        if (v != null && v.isNotEmpty) {
                          day.name = v;
                          store.changed();
                        }
                      },
                      child: Row(children: [
                        Text(day.name,
                            style: TextStyle(fontWeight: FontWeight.w800, color: p.accent)),
                        const SizedBox(width: 6),
                        Icon(Icons.edit, size: 16, color: p.accent),
                      ]),
                    )),
                LabeledRow(
                    'الأيقونة',
                    GestureDetector(
                      onTap: () async {
                        final v = await askText(context, 'إيموجي لليوم', initial: day.emoji);
                        if (v != null && v.isNotEmpty) {
                          day.emoji = v;
                          store.changed();
                        }
                      },
                      child: Text(day.emoji, style: const TextStyle(fontSize: 26)),
                    )),
                LabeledRow(
                    'يوم راحة',
                    Switch(
                        value: day.isRest,
                        onChanged: (v) {
                          day.kind = v ? 'rest' : 'train';
                          store.changed();
                        })),
              ]),
            ),
            if (!day.isRest) ...[
              SectionTitle('تمارين اليوم',
                  trailing: TextButton(
                    onPressed: () async {
                      final e = await pickExercise(context);
                      if (e != null) {
                        day.items.add(defaultItemFor(e));
                        store.changed();
                      }
                    },
                    child: Text('+ إضافة',
                        style: TextStyle(color: p.accent, fontWeight: FontWeight.w800)),
                  )),
              if (day.items.isEmpty)
                AppCard(
                    child: const Center(
                        child: Dim('لا توجد تمارين. اضغط «+ إضافة».'))),
              for (var i = 0; i < day.items.length; i++)
                _ItemTile(day: day, index: i),
            ] else
              const AppCard(
                  child: Dim('يوم الراحة لا يرسل إشعاراً ولا يحتوي تمارين.')),
          ]),
        );
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  final DayType day;
  final int index;
  const _ItemTile({required this.day, required this.index});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final it = day.items[index];
    final e = store.ex(it.exerciseId);
    if (e == null) {
      return AppCard(
        child: Row(children: [
          const Expanded(child: Dim('تمرين محذوف من المكتبة')),
          IconButton(
              icon: Icon(Icons.delete_outline, color: p.red),
              onPressed: () {
                day.items.removeAt(index);
                store.changed();
              }),
        ]),
      );
    }
    final detail = e.isTime
        ? '${it.sets} × ${it.seconds > 0 ? it.seconds : 30} ث'
        : '${it.sets} × ${it.reps}${e.usesWeight && it.weight > 0 ? ' • ${fmtNum(it.weight)} كغ' : ''}';
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      onTap: () => editPlanItem(context, it, e),
      child: Row(children: [
        ExIcon(e, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15, color: p.text)),
            Dim('${kRoleLabels[it.role] ?? ''} • $detail • راحة ${it.restSeconds}ث',
                size: 12),
          ]),
        ),
        IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.arrow_upward, size: 20, color: p.dim),
            onPressed: index == 0
                ? null
                : () {
                    final x = day.items.removeAt(index);
                    day.items.insert(index - 1, x);
                    store.changed();
                  }),
        IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.arrow_downward, size: 20, color: p.dim),
            onPressed: index >= day.items.length - 1
                ? null
                : () {
                    final x = day.items.removeAt(index);
                    day.items.insert(index + 1, x);
                    store.changed();
                  }),
        IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 20, color: p.red),
            onPressed: () {
              day.items.removeAt(index);
              store.changed();
            }),
      ]),
    );
  }
}
