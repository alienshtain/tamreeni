// المزيد: روابط الخطط والمكتبة والاستيراد + كل الإعدادات.
import 'package:flutter/material.dart' hide Text;

import '../engine.dart';
import '../i18n.dart';
import '../catalog.dart';
import '../services.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'catalog_screen.dart';
import 'exercises.dart';
import 'intro.dart';
import 'meds.dart';
import 'plans.dart';
import 'transfer.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.pal;
        final s = store.settings;

        Widget nav(String emoji, String title, String sub, Widget page) => AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
                    Dim(sub, size: 12.5),
                  ]),
                ),
                Icon(fwdIcon(), color: p.dim),
              ]),
            );

        void resched() => Notifier.reschedule();

        Future<int?> pickTime(int current) async {
          final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: (current ~/ 60) % 24, minute: current % 60));
          if (t == null) return null;
          return t.hour * 60 + t.minute;
        }

        Widget timeBox(int minutes, VoidCallback onTap) => GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                    color: p.surface2, borderRadius: BorderRadius.circular(14)),
                child: Text(fmtTime(minutes),
                    style: TextStyle(fontWeight: FontWeight.w800, color: p.accent)),
              ),
            );

        return Scaffold(
          appBar: AppBar(title: const Text('المزيد')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              nav('🗓️', 'خططي', 'إنشاء وتعديل الخطط والأيام', const PlansScreen()),
              nav('💊', 'الأدوية والعلاجات', 'جدول الجرعات وتذكيرات ومتابعة الالتزام',
                  const MedsScreen()),
              nav('📚', 'مكتبة التمارين', 'تمارينك وتعديلها وروابط الشرح',
                  const ExerciseLibraryScreen()),
              nav('🌐', 'كتالوج التمارين', 'تصفح التمارين الجاهزة مع الصور والفيديو وحدّثها من GitHub',
                  const CatalogScreen()),
              nav('📥', 'الاستيراد والتصدير', 'Excel • JSON • ذكاء اصطناعي • نسخ احتياطي',
                  const TransferScreen()),
              const SectionTitle('التنبيهات'),
              AppCard(
                child: Column(children: [
                  LabeledRow('وقت التمرين',
                      timeBox(s.workoutMinutes, () async {
                    final t = await pickTime(s.workoutMinutes);
                    if (t != null) {
                      s.workoutMinutes = t;
                      store.changed();
                      resched();
                    }
                  }), sub: 'يصلك إشعار في هذا الوقت في أيام التمرين فقط'),
                  LabeledRow(
                      'تنبيه التمرين',
                      Switch(
                          value: s.notifyWorkout,
                          onChanged: (v) {
                            s.notifyWorkout = v;
                            store.changed();
                            resched();
                          }),
                      sub: 'لا يُرسل في أيام الراحة'),
                  LabeledRow(
                      'تذكير الماء',
                      Switch(
                          value: s.waterReminders,
                          onChanged: (v) {
                            s.waterReminders = v;
                            store.changed();
                            resched();
                          })),
                  if (s.waterReminders) ...[
                    LabeledRow(
                        'كل',
                        NumStepper(
                            value: s.waterEveryMin.toDouble(),
                            min: 30,
                            max: 360,
                            step: 30,
                            unit: 'دقيقة',
                            onChanged: (v) {
                              s.waterEveryMin = v.round();
                              store.changed();
                              resched();
                            })),
                    LabeledRow('من الساعة', timeBox(s.waterFrom, () async {
                      final t = await pickTime(s.waterFrom);
                      if (t != null) {
                        s.waterFrom = t;
                        store.changed();
                        resched();
                      }
                    })),
                    LabeledRow('إلى الساعة', timeBox(s.waterTo, () async {
                      final t = await pickTime(s.waterTo);
                      if (t != null) {
                        s.waterTo = t;
                        store.changed();
                        resched();
                      }
                    })),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: PButton('السماح بالإشعارات', style: BtnStyle.tonal,
                          onTap: () async {
                        final ok = await Notifier.requestPermission();
                        if (context.mounted) {
                          toast(context, ok ? 'تم السماح بالإشعارات' : 'لم يُمنح الإذن');
                        }
                        resched();
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: PButton('إشعار تجريبي', style: BtnStyle.tonal,
                            onTap: Notifier.showTest)),
                  ]),
                  const SizedBox(height: 8),
                  const Dim(
                      'إذا لم تصلك الإشعارات في وقتها: من إعدادات أندرويد > التطبيقات > تمريني > البطارية، '
                      'اختر «بدون قيود». وفعّل «التنبيهات والتذكيرات» إن ظهر الخيار.',
                      size: 12),
                ]),
              ),
              const SectionTitle('التحفيز والأدوية'),
              AppCard(
                child: Column(children: [
                  LabeledRow(
                      'تنبيه تحفيزي عند التأخر',
                      Switch(
                          value: s.streakNudge,
                          onChanged: (v) {
                            s.streakNudge = v;
                            store.changed();
                            resched();
                          }),
                      sub: 'رسالة عشوائية تذكّرك بسلسلتك إذا تأخرت عن وقت التمرين'),
                  if (s.streakNudge)
                    LabeledRow(
                        'التأخر المسموح قبل التنبيه',
                        NumStepper(
                            value: s.lateNudgeMin.toDouble(),
                            min: 5,
                            max: 240,
                            step: 5,
                            unit: 'دقيقة',
                            onChanged: (v) {
                              s.lateNudgeMin = v.round();
                              store.changed();
                              resched();
                            })),
                  LabeledRow(
                      'تذكير ثانٍ إن لم تسجّل الجرعة',
                      NumStepper(
                          value: s.medFollowUpMin.toDouble(),
                          min: 0,
                          max: 120,
                          step: 5,
                          unit: s.medFollowUpMin == 0 ? 'معطّل' : 'دقيقة',
                          onChanged: (v) {
                            s.medFollowUpMin = v.round();
                            store.changed();
                            resched();
                          }),
                      sub: 'يتكرر التذكير بعد المدة المحددة إذا لم تضغط «تم»'),
                ]),
              ),
              const SectionTitle('أثناء التمرين'),
              AppCard(
                child: Column(children: [
                  LabeledRow(
                      'العد التلقائي للعدات',
                      Switch(
                          value: s.autoCount,
                          onChanged: (v) {
                            s.autoCount = v;
                            store.changed();
                          }),
                      sub: 'تُحسب عدة كل فترة تحددها'),
                  LabeledRow(
                      'فترة العدة التلقائية',
                      NumStepper(
                          value: s.autoInterval.toDouble(),
                          min: 1,
                          max: 120,
                          step: 5,
                          unit: 'ثانية',
                          onChanged: (v) {
                            s.autoInterval = v.round();
                            store.changed();
                          })),
                  LabeledRow(
                      'الراحة الافتراضية للتمرين الجديد',
                      NumStepper(
                          value: s.defaultRest.toDouble(),
                          min: 15,
                          max: 300,
                          step: 15,
                          unit: 'ثانية',
                          onChanged: (v) {
                            s.defaultRest = v.round();
                            store.changed();
                          })),
                  LabeledRow(
                      'الأصوات',
                      Switch(
                          value: s.sound,
                          onChanged: (v) {
                            s.sound = v;
                            store.changed();
                            if (v) Sfx.setDone();
                          })),
                  LabeledRow(
                      'الاهتزاز',
                      Switch(
                          value: s.vibrate,
                          onChanged: (v) {
                            s.vibrate = v;
                            store.changed();
                            if (v) Sfx.light();
                          })),
                  LabeledRow(
                      'إبقاء الشاشة مضيئة',
                      Switch(
                          value: s.keepAwake,
                          onChanged: (v) {
                            s.keepAwake = v;
                            store.changed();
                          })),
                  LabeledRow(
                      'سؤال الجهد بعد آخر مجموعة',
                      Switch(
                          value: s.askRpe,
                          onChanged: (v) {
                            s.askRpe = v;
                            store.changed();
                          })),
                  LabeledRow(
                      'زيادة الحمل التلقائية',
                      Switch(
                          value: s.autoProgression,
                          onChanged: (v) {
                            s.autoProgression = v;
                            store.changed();
                          }),
                      sub: 'عند إكمال كل العدات المطلوبة يرتفع الوزن/العدات'),
                  LabeledRow(
                      'اسألني بعد أيام فائتة متتالية',
                      NumStepper(
                          value: s.askAfterMissed.toDouble(),
                          min: 0,
                          max: 14,
                          unit: s.askAfterMissed == 0 ? 'معطّل' : 'أيام',
                          onChanged: (v) {
                            s.askAfterMissed = v.round();
                            store.changed();
                          }),
                      sub: 'يعرض عليك إعادة ترتيب الخطة'),
                ]),
              ),
              const SectionTitle('اللغة'),
              AppCard(
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  Pill('العربية', selected: isAr, onTap: () => store.setLang('ar')),
                  Pill('English', selected: !isAr, onTap: () => store.setLang('en')),
                ]),
              ),
              const SectionTitle('الكتالوج والمساعدة'),
              AppCard(
                child: Column(children: [
                  PButton('تحديث التمارين من GitHub', icon: Icons.sync,
                      style: BtnStyle.tonal,
                      onTap: () => updateCatalogFlow(context)),
                  const SizedBox(height: 8),
                  PButton('تغيير مصدر الكتالوج', icon: Icons.link,
                      style: BtnStyle.tonal, onTap: () async {
                    final v = await askText(context, 'رابط ملف الكتالوج',
                        initial: s.catalogUrl, hint: 'اتركه فارغاً للرابط الافتراضي');
                    if (v != null) {
                      s.catalogUrl = v;
                      catalog.setUrl(v);
                      store.changed();
                    }
                  }),
                  const SizedBox(height: 8),
                  PButton('عرض شرح التطبيق', icon: Icons.help_outline,
                      style: BtnStyle.tonal,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const IntroScreen(fromSettings: true)))),
                ]),
              ),
              const SectionTitle('المظهر'),
              AppCard(
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  Pill('حسب النظام', selected: s.themeMode == 'system', onTap: () {
                    s.themeMode = 'system';
                    store.changed();
                  }),
                  Pill('فاتح', selected: s.themeMode == 'light', onTap: () {
                    s.themeMode = 'light';
                    store.changed();
                  }),
                  Pill('داكن', selected: s.themeMode == 'dark', onTap: () {
                    s.themeMode = 'dark';
                    store.changed();
                  }),
                ]),
              ),
              const SizedBox(height: 4),
              const Center(child: Dim('تمريني • الإصدار 1.1', size: 12)),
            ],
          ),
        );
      },
    );
  }
}
