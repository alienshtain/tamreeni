// شاشة اختيار اللغة (أول فتح) + جولة تعريفية بالتطبيق.
import 'package:flutter/material.dart' hide Text;

import '../i18n.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget big(String title, String sub, String code) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: p.surface,
            borderRadius: BorderRadius.circular(kRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(kRadius),
              onTap: () => store.setLang(code),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w900, color: p.text)),
                      const SizedBox(height: 4),
                      Text(sub, style: TextStyle(color: p.dim)),
                    ]),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: p.accent),
                ]),
              ),
            ),
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('💪', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text('Tamreeni • تمريني',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.text)),
            const SizedBox(height: 6),
            Text('Choose your language • اختر لغتك',
                style: TextStyle(color: p.dim)),
            const SizedBox(height: 32),
            big('العربية', 'Arabic', 'ar'),
            big('English', 'الإنكليزية', 'en'),
          ]),
        ),
      ),
    );
  }
}

class _Slide {
  final String emoji;
  final String title;
  final String body;
  const _Slide(this.emoji, this.title, this.body);
}

const _slides = [
  _Slide('🏋️', 'خطتك التدريبية',
      'أنشئ خطة من قالب جاهز (علوي/سفلي، دفع/سحب/أرجل...) لأي عدد أيام. إذا فاتك يوم يتحرك الجدول تلقائياً ويُعاد نفس التمرين.'),
  _Slide('⏱️', 'تمرين تفاعلي',
      'عدّاد عدات دائري (يدوي أو تلقائي)، مؤقت للتمارين الوقتية، وراحة تلقائية بين المجموعات مع صوت واهتزاز.'),
  _Slide('📚', 'كتالوج التمارين',
      'أكثر من 100 تمرين بالصور وطريقة الأداء وفيديو شرح يعمل داخل التطبيق. زر التحديث يجلب التمارين الجديدة من GitHub.'),
  _Slide('🤖', 'خطة بالذكاء الاصطناعي',
      'اكتب لماذا تريد وأي أيام، انسخ البرومبت وأرسله لأي ذكاء اصطناعي، ثم استورد ملف الخطة الذي يعطيك إياه.'),
  _Slide('💧', 'الماء والأكل',
      'تتبّع الماء والسعرات والبروتين والكربوهيدرات. احفظ وجباتك لتعيد اختيارها، أو صوّر الوجبة ودع الذكاء الاصطناعي يحسب قيمها.'),
  _Slide('💊', 'الأدوية والعلاجات',
      'سجّل أدويتك ومواعيدها وأيام العلاج، ويذكّرك التطبيق بكل جرعة ويحفظ سجل التزامك.'),
  _Slide('🔥', 'السلسلة والتحفيز',
      'كل يوم تتمرنه يزيد سلسلتك. إذا تأخرت عن موعد التمرين يصلك تنبيه تحفيزي حتى لا تنكسر السلسلة.'),
];

class IntroScreen extends StatefulWidget {
  /// true عند فتحها من الإعدادات (تُغلق بدل أن تنقل لشاشة البداية).
  final bool fromSettings;
  const IntroScreen({super.key, this.fromSettings = false});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _ctl = PageController();
  int page = 0;

  void _finish() {
    if (widget.fromSettings) {
      Navigator.pop(context);
      return;
    }
    store.data.settings.introSeen = true;
    store.changed();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final last = page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _finish,
              child: Text('تخطي', style: TextStyle(color: p.dim)),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _ctl,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => page = i),
              itemBuilder: (_, i) {
                final s = _slides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 140,
                      height: 140,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: p.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(44)),
                      child: Text(s.emoji, style: const TextStyle(fontSize: 70)),
                    ),
                    const SizedBox(height: 28),
                    Text(s.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900, color: p.text)),
                    const SizedBox(height: 12),
                    Text(s.body,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15.5, height: 1.6, color: p.dim)),
                  ]),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == page ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                    color: i == page ? p.accent : p.surface2,
                    borderRadius: BorderRadius.circular(8)),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: PButton(last ? 'ابدأ' : 'التالي', big: true, onTap: () {
              if (last) {
                _finish();
              } else {
                _ctl.nextPage(
                    duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              }
            }),
          ),
        ]),
      ),
    );
  }
}
