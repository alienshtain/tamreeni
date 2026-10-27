import 'package:flutter/material.dart' hide Text;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'engine.dart';
import 'i18n.dart';
import 'models.dart';
import 'screens/body.dart';
import 'screens/home.dart';
import 'screens/intro.dart';
import 'screens/more.dart';
import 'screens/plans.dart';
import 'screens/progress.dart';
import 'screens/today.dart';
import 'services.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  await Notifier.init();
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return MaterialApp(
          title: isAr ? 'تمريني' : 'Tamreeni',
          debugShowCheckedModeBanner: false,
          locale: Locale(isAr ? 'ar' : 'en'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(Pal.light),
          darkTheme: buildTheme(Pal.dark),
          themeMode: store.themeMode,
          home: store.settings.lang.isEmpty
              ? const LanguageScreen()
              : (!store.settings.introSeen
                  ? const IntroScreen()
                  : (store.data.onboarded
                      ? const MainShell()
                      : const OnboardingScreen())),
        );
      },
    );
  }
}

// ======================= الهيكل الرئيسي =======================
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => Notifier.reschedule());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      store.touch(); // قد يكون التاريخ تغيّر
      Notifier.reschedule();
    } else if (state == AppLifecycleState.paused) {
      store.flush();
    }
  }

  void _openPlans() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        goToday: () => setState(() => index = 1),
        goBody: () => setState(() => index = 3),
        openPlans: _openPlans,
      ),
      TodayScreen(openPlans: _openPlans),
      const ProgressScreen(),
      const BodyScreen(),
      const MoreScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: tr('الرئيسية')),
          NavigationDestination(
              icon: const Icon(Icons.fitness_center_outlined),
              selectedIcon: const Icon(Icons.fitness_center),
              label: tr('اليوم')),
          NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: tr('التقدم')),
          NavigationDestination(
              icon: const Icon(Icons.monitor_weight_outlined),
              selectedIcon: const Icon(Icons.monitor_weight),
              label: tr('الجسم')),
          NavigationDestination(
              icon: const Icon(Icons.menu_rounded),
              selectedIcon: const Icon(Icons.menu_rounded),
              label: tr('المزيد')),
        ],
      ),
    );
  }
}

// ======================= الترحيب =======================
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.pal;
        final pr = store.data.profile;
        final s = store.settings;
        final hasPlan = store.data.plans.isNotEmpty;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              children: [
                const Center(child: Text('💪', style: TextStyle(fontSize: 64))),
                const SizedBox(height: 8),
                Center(
                  child: Text('أهلاً بك في «تمريني»',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900, color: p.text)),
                ),
                const SizedBox(height: 6),
                const Center(
                    child: Dim('مدرّبك المنزلي لبناء العضلات: جدول ذكي، عدّاد عدات، مؤقتات، وتتبّع للتقدم.',
                        align: TextAlign.center)),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SectionTitle('١) بياناتك'),
                    const Dim('الجنس'),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, children: [
                      Pill('ذكر', selected: pr.gender == 'male', onTap: () {
                        pr.gender = 'male';
                        store.changed();
                      }),
                      Pill('أنثى', selected: pr.gender == 'female', onTap: () {
                        pr.gender = 'female';
                        store.changed();
                      }),
                    ]),
                    const SizedBox(height: 8),
                    LabeledRow(
                        'العمر',
                        NumStepper(
                            value: pr.age == 0 ? 25 : pr.age.toDouble(),
                            min: 10,
                            max: 100,
                            unit: 'سنة',
                            onChanged: (v) {
                              pr.age = v.round();
                              store.changed();
                            })),
                    LabeledRow(
                        'الطول',
                        NumStepper(
                            value: pr.heightCm == 0 ? 170 : pr.heightCm,
                            min: 100,
                            max: 250,
                            unit: 'سم',
                            decimal: true,
                            onChanged: (v) {
                              pr.heightCm = v;
                              store.changed();
                            })),
                    LabeledRow(
                        'الوزن',
                        NumStepper(
                            value: pr.weightKg == 0 ? 70 : pr.weightKg,
                            min: 30,
                            max: 300,
                            step: 0.5,
                            unit: 'كغ',
                            decimal: true,
                            onChanged: (v) {
                              pr.weightKg = v;
                              store.changed();
                            })),
                    const SizedBox(height: 4),
                    const Dim('هدفي'),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      Pill('تضخيم عضلات', selected: pr.goal == 'bulk', onTap: () {
                        pr.goal = 'bulk';
                        store.changed();
                      }),
                      Pill('تنشيف', selected: pr.goal == 'cut', onTap: () {
                        pr.goal = 'cut';
                        store.changed();
                      }),
                      Pill('ثبات', selected: pr.goal == 'maintain', onTap: () {
                        pr.goal = 'maintain';
                        store.changed();
                      }),
                    ]),
                  ]),
                ),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SectionTitle('٢) وقت التمرين'),
                    LabeledRow(
                        'يصلك تنبيه في هذا الوقت',
                        GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: s.workoutMinutes ~/ 60,
                                    minute: s.workoutMinutes % 60));
                            if (t != null) {
                              s.workoutMinutes = t.hour * 60 + t.minute;
                              store.changed();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                                color: p.surface2,
                                borderRadius: BorderRadius.circular(14)),
                            child: Text(fmtTime(s.workoutMinutes),
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, color: p.accent)),
                          ),
                        )),
                  ]),
                ),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SectionTitle('٣) خطتك'),
                    if (hasPlan)
                      Row(children: [
                        Icon(Icons.check_circle, color: p.green),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('تم إنشاء: ${store.plan?.name ?? ''}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, color: p.text))),
                      ])
                    else
                      const Dim('اختر قالباً جاهزاً (علوي/سفلي، دفع/سحب/أرجل...) وعدّله لاحقاً كما تشاء، '
                          'أو استورد ملفاً من ذكاء اصطناعي بعد الدخول.'),
                    const SizedBox(height: 12),
                    PButton(hasPlan ? 'إنشاء خطة أخرى' : 'إنشاء خطتي',
                        icon: Icons.add,
                        style: hasPlan ? BtnStyle.tonal : BtnStyle.filled,
                        onTap: () => showNewPlanWizard(context)),
                  ]),
                ),
                const SizedBox(height: 8),
                PButton('ابدأ الآن', big: true, icon: isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, onTap: () async {
                  store.data.onboarded = true;
                  store.changed();
                  await Notifier.requestPermission();
                  await Notifier.reschedule();
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
