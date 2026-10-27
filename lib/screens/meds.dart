// الأدوية والعلاجات: جدول الجرعات، التسجيل، التذكير، السجل.
import 'package:flutter/material.dart' hide Text;

import '../engine.dart';
import '../i18n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

String _doseLine(Medication m) {
  final parts = <String>[];
  if (m.dose.isNotEmpty) parts.add(m.dose);
  final ins = kMedInstr[m.instructions] ?? '';
  if (m.instructions.isNotEmpty) parts.add(ins);
  return parts.join(' • ');
}

// ======================= صف جرعة =======================
class DoseTile extends StatelessWidget {
  final Dose dose;
  const DoseTile(this.dose, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final m = dose.med;
    final overdue = dose.status.isEmpty && dose.when.isBefore(DateTime.now());
    final timeColor = dose.taken
        ? p.green
        : (overdue ? p.red : p.dim);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(
          width: 64,
          child: Text(fmtTime(dose.minutes),
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w800, color: timeColor)),
        ),
        Text(m.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: p.text,
                    decoration: dose.skipped ? TextDecoration.lineThrough : null)),
            if (_doseLine(m).isNotEmpty) Dim(_doseLine(m), size: 12),
          ]),
        ),
        if (dose.status.isEmpty) ...[
          RoundIconBtn(Icons.close, size: 38,
              onTap: () => store.setDoseStatus(dose, 'skipped')),
          const SizedBox(width: 8),
          RoundIconBtn(Icons.check, size: 38, bg: p.green, fg: Colors.white,
              onTap: () => store.setDoseStatus(dose, 'taken')),
        ] else
          GestureDetector(
            onTap: () => store.setDoseStatus(dose, ''),
            child: Row(children: [
              Icon(dose.taken ? Icons.check_circle : Icons.remove_circle_outline,
                  color: dose.taken ? p.green : p.dim),
              const SizedBox(width: 4),
              Dim(dose.taken ? 'تم' : 'تخطيت', size: 12),
            ]),
          ),
      ]),
    );
  }
}

// ======================= بطاقة الرئيسية =======================
class MedsCard extends StatelessWidget {
  const MedsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final doses = store.dosesOn(store.today);
    final taken = doses.where((d) => d.taken).length;
    void open() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const MedsScreen()));
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: open,
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            Expanded(
              child: Text('الأدوية والعلاجات 💊',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
            ),
            if (doses.isNotEmpty)
              Text('$taken/${doses.length}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: taken == doses.length ? p.green : p.accent)),
            Icon(fwdIcon(), color: p.dim),
          ]),
        ),
        if (store.data.meds.isEmpty) ...[
          const SizedBox(height: 6),
          const Dim('سجّل أدويتك وعلاجاتك ليذكّرك التطبيق بمواعيد الجرعات.'),
          const SizedBox(height: 10),
          PButton('إضافة دواء', icon: Icons.add, style: BtnStyle.tonal,
              onTap: () => editMedSheet(context, null)),
        ] else if (doses.isEmpty) ...[
          const SizedBox(height: 6),
          const Dim('لا جرعات مجدولة اليوم.'),
        ] else ...[
          const SizedBox(height: 6),
          for (final d in doses) DoseTile(d),
        ],
      ]),
    );
  }
}

// ======================= الشاشة الكاملة =======================
class MedsScreen extends StatelessWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.pal;
        final doses = store.dosesOn(store.today);
        final meds = store.data.meds;
        return Scaffold(
          appBar: AppBar(
            title: const Text('الأدوية والعلاجات'),
            actions: [
              IconButton(
                  onPressed: () => editMedSheet(context, null),
                  icon: Icon(Icons.add_circle, color: p.accent, size: 30)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              const SectionTitle('جرعات اليوم'),
              AppCard(
                child: doses.isEmpty
                    ? const Dim('لا توجد جرعات اليوم.')
                    : Column(children: [for (final d in doses) DoseTile(d)]),
              ),
              const SectionTitle('كل الأدوية'),
              if (meds.isEmpty)
                AppCard(
                  child: Column(children: [
                    const Dim('لم تضف أي دواء بعد.', align: TextAlign.center),
                    const SizedBox(height: 10),
                    PButton('إضافة دواء', icon: Icons.add,
                        onTap: () => editMedSheet(context, null)),
                  ]),
                )
              else
                for (final m in meds) _medCard(context, p, m),
              if (meds.isNotEmpty) ...[
                const SectionTitle('آخر 7 أيام'),
                AppCard(child: _History(p)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _medCard(BuildContext context, Pal p, Medication m) {
    final today = store.today;
    final cd = m.courseDay(today);
    final len = m.courseLength;
    String course;
    if (!m.active) {
      course = 'متوقف';
    } else if (cd == 0) {
      course = 'يبدأ ${fmtDate(m.startDate)}';
    } else if (len != null && cd > len) {
      course = 'انتهى العلاج';
    } else if (len != null) {
      course = 'اليوم $cd من $len';
    } else {
      course = 'علاج مستمر';
    }
    final days = m.weekdays.isEmpty
        ? 'كل يوم'
        : (m.weekdays.toList()..sort()).map(dayName).join('، ');
    return AppCard(
      onTap: () => editMedSheet(context, m),
      child: Row(children: [
        Text(m.emoji, style: const TextStyle(fontSize: 30)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
            if (_doseLine(m).isNotEmpty) Dim(_doseLine(m), size: 12.5),
            Dim('${m.times.map(fmtTime).join(' • ')}  |  $days', size: 12),
            Dim(course, size: 12),
          ]),
        ),
        Switch(
            value: m.active,
            onChanged: (v) {
              m.active = v;
              store.upsertMed(m);
            }),
      ]),
    );
  }
}

class _History extends StatelessWidget {
  final Pal p;
  const _History(this.p);
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < 7; i++) {
      final d = addDays(store.today, -i);
      final doses = store.dosesOn(d);
      if (doses.isEmpty) continue;
      final taken = doses.where((x) => x.taken).length;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(width: 110, child: Dim(i == 0 ? 'اليوم' : fmtDate(d), size: 12.5)),
          Expanded(
              child: BarProgress(
                  value: taken / doses.length,
                  height: 10,
                  color: taken == doses.length ? p.green : p.accent)),
          const SizedBox(width: 8),
          Text('$taken/${doses.length}',
              style: TextStyle(fontSize: 12, color: p.dim)),
        ]),
      ));
    }
    if (rows.isEmpty) return const Dim('لا توجد بيانات بعد.');
    return Column(children: rows);
  }
}

// ======================= إضافة/تعديل دواء =======================
Future<void> editMedSheet(BuildContext context, Medication? existing) {
  final name = TextEditingController(text: existing?.name ?? '');
  final dose = TextEditingController(text: existing?.dose ?? '');
  final notes = TextEditingController(text: existing?.notes ?? '');
  var form = existing?.form ?? 'pill';
  var times = List<int>.from(existing?.times ?? [8 * 60]);
  var weekdays = List<int>.from(existing?.weekdays ?? <int>[]);
  var start = existing?.startDate ?? store.today;
  var hasEnd = existing?.endDate != null;
  var days = existing?.courseLength ?? 7;
  var instr = existing?.instructions ?? '';
  var reminder = existing?.reminder ?? true;

  return showSheet<void>(context, (ctx) {
    final p = ctx.pal;
    return StatefulBuilder(builder: (ctx, setS) {
      Future<void> addTime() async {
        final t = await showTimePicker(
            context: ctx, initialTime: const TimeOfDay(hour: 8, minute: 0));
        if (t == null) return;
        final v = t.hour * 60 + t.minute;
        if (!times.contains(v)) {
          setS(() => times = ([...times, v]..sort()));
        }
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'دواء جديد' : 'تعديل الدواء',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w900, color: p.text)),
              const SizedBox(height: 14),
              TextField(controller: name, decoration: deco(ctx, 'اسم الدواء / العلاج')),
              const SizedBox(height: 10),
              TextField(
                  controller: dose,
                  decoration: deco(ctx, 'الجرعة (مثل: حبة، 5 مل)')),
              const SizedBox(height: 12),
              const Dim('الشكل'),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final e in kMedForms.entries)
                  Pill('${e.value[1]} ${e.value[0]}',
                      selected: form == e.key, onTap: () => setS(() => form = e.key)),
              ]),
              const SizedBox(height: 14),
              const Dim('أوقات الجرعات'),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in times)
                  GestureDetector(
                    onTap: () => setS(() {
                      if (times.length > 1) times = times.where((x) => x != t).toList();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: p.surface2, borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(fmtTime(t),
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: p.accent)),
                        if (times.length > 1) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.close, size: 16, color: p.dim),
                        ],
                      ]),
                    ),
                  ),
                Pill('+ وقت', onTap: addTime),
              ]),
              const SizedBox(height: 14),
              const Dim('الأيام'),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                Pill('كل يوم',
                    selected: weekdays.isEmpty, onTap: () => setS(() => weekdays = []))
                ,
                for (var d = 1; d <= 7; d++)
                  Pill(dayName(d), selected: weekdays.contains(d), onTap: () {
                    setS(() {
                      final l = List<int>.from(weekdays);
                      if (l.contains(d)) {
                        l.remove(d);
                      } else {
                        l.add(d);
                      }
                      weekdays = l.length == 7 ? [] : l;
                    });
                  }),
              ]),
              const SizedBox(height: 14),
              const Dim('تعليمات'),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final e in kMedInstr.entries)
                  Pill(e.value, selected: instr == e.key, onTap: () => setS(() => instr = e.key)),
              ]),
              const SizedBox(height: 14),
              LabeledRow(
                  'تاريخ البداية',
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                          context: ctx,
                          initialDate: start,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100));
                      if (d != null) setS(() => start = dateOnly(d));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                          color: p.surface2, borderRadius: BorderRadius.circular(14)),
                      child: Text(fmtDate(start),
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: p.accent)),
                    ),
                  )),
              LabeledRow(
                  'علاج محدد المدة',
                  Switch(value: hasEnd, onChanged: (v) => setS(() => hasEnd = v)),
                  sub: 'مثل مضاد حيوي لمدة 7 أيام'),
              if (hasEnd)
                LabeledRow(
                    'عدد الأيام',
                    NumStepper(
                        value: days.toDouble(),
                        min: 1,
                        max: 365,
                        unit: 'يوم',
                        onChanged: (v) => setS(() => days = v.round()))),
              LabeledRow('تذكير بالإشعارات',
                  Switch(value: reminder, onChanged: (v) => setS(() => reminder = v))),
              const SizedBox(height: 6),
              TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: deco(ctx, 'ملاحظات (اختياري)')),
              const SizedBox(height: 16),
              PButton('حفظ', onTap: () {
                final n = name.text.trim();
                if (n.isEmpty) {
                  toast(ctx, 'اكتب اسم الدواء');
                  return;
                }
                final m = Medication(
                  id: existing?.id ?? newId(),
                  name: n,
                  dose: dose.text.trim(),
                  form: form,
                  times: times,
                  weekdays: weekdays,
                  startDate: start,
                  endDate: hasEnd ? addDays(start, days - 1) : null,
                  instructions: instr,
                  notes: notes.text.trim(),
                  reminder: reminder,
                  active: existing?.active ?? true,
                );
                store.upsertMed(m);
                Navigator.pop(ctx);
              }),
              if (existing != null) ...[
                const SizedBox(height: 8),
                PButton('حذف الدواء', style: BtnStyle.danger, onTap: () async {
                  final ok = await confirm(ctx, 'حذف الدواء',
                      'سيُحذف «${existing.name}» وسجل جرعاته.',
                      ok: 'حذف', danger: true);
                  if (ok) {
                    store.deleteMed(existing.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                }),
              ],
            ]),
      );
    });
  });
}
