// الترجمة: النصوص الأصلية بالعربية، والإنكليزية تُبحث في القاموس وقت العرض.
// القوالب الديناميكية تستخدم {} في المفتاح و{0} {1} في الترجمة.
import 'dictionary.dart';

/// 'ar' أو 'en' (يُضبط من الإعدادات).
String gLang = 'ar';
bool get isAr => gLang != 'en';

final RegExp _arabicChar = RegExp(r'[؀-ۿ]');

class _Tpl {
  final RegExp re;
  final String en;
  final int n;
  final int weight;
  _Tpl(this.re, this.en, this.n, this.weight);
}

List<_Tpl>? _tpls;

List<_Tpl> _build() {
  final out = <_Tpl>[];
  kEn.forEach((k, v) {
    if (!k.contains('{}')) return;
    final parts = k.split('{}');
    final b = StringBuffer('^');
    for (var i = 0; i < parts.length; i++) {
      b.write(RegExp.escape(parts[i]));
      if (i < parts.length - 1) b.write('(.+?)');
    }
    b.write(r'$');
    final literal = parts.fold<int>(0, (a, p) => a + p.length);
    out.add(_Tpl(RegExp(b.toString(), dotAll: true), v, parts.length - 1, literal));
  });
  out.sort((a, b) => b.weight.compareTo(a.weight));
  return out;
}

/// يترجم نصاً عربياً إلى لغة التطبيق الحالية. إن لم توجد ترجمة يعيد النص كما هو.
String tr(String s) {
  if (gLang != 'en' || s.isEmpty) return s;
  if (!_arabicChar.hasMatch(s)) return s;
  final direct = kEn[s];
  if (direct != null) return direct;
  final tpls = _tpls ??= _build();
  for (final t in tpls) {
    final m = t.re.firstMatch(s);
    if (m == null) continue;
    var out = t.en;
    for (var i = 0; i < t.n; i++) {
      out = out.replaceAll('{$i}', tr(m.group(i + 1) ?? ''));
    }
    return out;
  }
  return s;
}

/// يختار نصاً حسب اللغة مباشرة (للنصوص التي تُكتب بلغتين في الكود).
String t2(String ar, String en) => isAr ? ar : en;

/// هل يحتوي النص حروفاً عربية.
bool hasArabic(String s) => _arabicChar.hasMatch(s);
