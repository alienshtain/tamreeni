// كتالوج التمارين: نسخة مضمّنة + تحديث من GitHub (ملف JSON واحد).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// رابط الكتالوج الافتراضي. يمكن تغييره من الإعدادات (مفيد لمن يعمل نسخة fork).
const String kDefaultCatalogUrl =
    'https://raw.githubusercontent.com/alienshtain/tamreeni/main/catalog/exercises.json';

class CatalogData {
  final int version;
  final String updated;
  final List<Map<String, dynamic>> raw;
  CatalogData(this.version, this.updated, this.raw);

  Map<String, Map<String, dynamic>> get byId =>
      {for (final e in raw) toS(e['id']): e};
}

class CatalogDiff {
  final List<String> added;
  final List<String> changed;
  final List<String> removed;
  final bool versionChanged;
  CatalogDiff(this.added, this.changed, this.removed, this.versionChanged);
  bool get isEmpty => added.isEmpty && changed.isEmpty && removed.isEmpty;
}

CatalogData parseCatalog(String text) {
  final j = jsonDecode(text);
  if (j is! Map) throw const FormatException('catalog must be an object');
  final list = asList(j['exercises']);
  final out = <Map<String, dynamic>>[];
  final seen = <String>{};
  for (final e in list) {
    final m = asMap(e);
    final id = toS(m['id']);
    if (id.isEmpty || seen.contains(id)) continue;
    if (toS(m['nameEn']).isEmpty && toS(m['nameAr']).isEmpty) continue;
    seen.add(id);
    out.add(m);
  }
  if (out.isEmpty) throw const FormatException('catalog has no exercises');
  return CatalogData(toI(j['version'], 1), toS(j['updated']), out);
}

CatalogDiff diffCatalog(CatalogData? old, CatalogData next) {
  if (old == null) {
    return CatalogDiff(next.raw.map((e) => toS(e['id'])).toList(), [], [], true);
  }
  final a = old.byId;
  final b = next.byId;
  final added = <String>[];
  final changed = <String>[];
  final removed = <String>[];
  b.forEach((id, e) {
    if (!a.containsKey(id)) {
      added.add(id);
    } else if (jsonEncode(a[id]) != jsonEncode(e)) {
      changed.add(id);
    }
  });
  for (final id in a.keys) {
    if (!b.containsKey(id)) removed.add(id);
  }
  return CatalogDiff(added, changed, removed, old.version != next.version);
}

String catalogBase(String url) {
  final i = url.lastIndexOf('/');
  return i < 0 ? '' : url.substring(0, i + 1);
}

String _abs(String base, String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '$base$path';
}

Exercise catalogToExercise(Map<String, dynamic> e, String base) {
  final en = toS(e['nameEn']);
  final ar = toS(e['nameAr']);
  final cat = toS(e['category']);
  return Exercise(
    id: toS(e['id']),
    name: en.isNotEmpty ? en : ar,
    nameEn: en,
    nameAr: ar,
    emoji: toS(e['emoji']),
    category: kCatKeyToAr[cat] ?? (cat.isEmpty ? 'أخرى' : cat),
    type: toS(e['type']) == 'time' ? 'time' : 'reps',
    equipment: kEquipLabels.containsKey(toS(e['equipment']))
        ? toS(e['equipment'])
        : 'bodyweight',
    youtube: toS(e['video']),
    link: toS(e['link']),
    notes: toS(e['notes']),
    level: toS(e['level']),
    muscles: asList(e['muscles']).map((x) => toS(x)).toList(),
    secondary: asList(e['secondary']).map((x) => toS(x)).toList(),
    stepsEn: asList(e['stepsEn']).map((x) => toS(x)).toList(),
    stepsAr: asList(e['stepsAr']).map((x) => toS(x)).toList(),
    tipsEn: asList(e['tipsEn']).map((x) => toS(x)).toList(),
    tipsAr: asList(e['tipsAr']).map((x) => toS(x)).toList(),
    images: asList(e['images'])
        .map((x) => toS(x))
        .where((x) => x.isNotEmpty)
        .map((x) => _abs(base, x))
        .toList(),
    src: 'catalog',
    edited: false,
    rev: toI(e['rev'], 1),
  );
}

/// يحمّل ويحفظ الكتالوج.
class CatalogService {
  CatalogData? data;
  String base = catalogBase(kDefaultCatalogUrl);
  String url = kDefaultCatalogUrl;
  File? _cache;
  int lastCheckedMs = 0;

  List<Exercise> get items =>
      (data?.raw ?? const <Map<String, dynamic>>[])
          .map((e) => catalogToExercise(e, base))
          .toList();

  Exercise? byId(String id) {
    final e = data?.byId[id];
    return e == null ? null : catalogToExercise(e, base);
  }

  bool get loaded => data != null;
  int get version => data?.version ?? 0;
  String get updated => data?.updated ?? '';

  void setUrl(String custom) {
    url = custom.trim().isEmpty ? kDefaultCatalogUrl : custom.trim();
    base = catalogBase(url);
  }

  /// bundledJson: النسخة المضمّنة في التطبيق. dir: مجلد بيانات التطبيق.
  Future<void> init(String bundledJson, String dirPath) async {
    _cache = File('$dirPath/catalog_cache.json');
    CatalogData? cached;
    try {
      if (await _cache!.exists()) {
        cached = parseCatalog(await _cache!.readAsString());
      }
    } catch (_) {}
    CatalogData? bundled;
    try {
      bundled = parseCatalog(bundledJson);
    } catch (_) {}
    if (cached != null && (bundled == null || cached.version >= bundled.version)) {
      data = cached;
    } else {
      data = bundled ?? cached;
    }
  }

  /// يجلب النسخة الأحدث من GitHub ويحفظها. يعيد الفروقات. يرمي استثناء عند الفشل.
  Future<CatalogDiff> refresh() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('Cache-Control', 'no-cache');
      final res = await req.close().timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      final body = await res
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 40));
      final next = parseCatalog(body);
      final diff = diffCatalog(data, next);
      data = next;
      lastCheckedMs = DateTime.now().millisecondsSinceEpoch;
      try {
        await _cache?.writeAsString(body, flush: true);
      } catch (_) {}
      return diff;
    } finally {
      client.close(force: true);
    }
  }

  /// بحث وتصفية (الاسم بالعربية أو الإنكليزية).
  List<Exercise> search(
      {String query = '', String category = '', String equipment = ''}) {
    final q = query.trim().toLowerCase();
    return items.where((e) {
      if (category.isNotEmpty && e.category != category) return false;
      if (equipment.isNotEmpty && e.equipment != equipment) return false;
      if (q.isNotEmpty) {
        final hay = '${e.nameEn} ${e.nameAr} ${e.muscles.join(' ')}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }
}

final CatalogService catalog = CatalogService();
