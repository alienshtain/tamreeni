// كتالوج التمارين من GitHub: تصفح، تفاصيل، إضافة للمكتبة، وتحديث.
import 'package:flutter/material.dart' hide Text;

import '../catalog.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'exercise_detail.dart';

/// يتحقق من وجود تمارين جديدة/معدّلة على GitHub ويطبّقها. يعرض النتيجة للمستخدم.
Future<void> updateCatalogFlow(BuildContext context) async {
  final p = context.pal;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      content: Row(children: [
        const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(width: 16),
        Expanded(child: Text('جارٍ التحقق من GitHub...', style: TextStyle(color: p.text))),
      ]),
    ),
  );
  CatalogDiff? diff;
  Object? error;
  var synced = 0;
  try {
    diff = await catalog.refresh();
    synced = store.syncLibraryFromCatalog();
    store.touch();
  } catch (e) {
    error = e;
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  if (error != null) {
    toast(context, 'تعذر التحديث. تحقق من الاتصال بالإنترنت.');
    return;
  }
  final d = diff!;
  final msg = d.isEmpty
      ? 'لا توجد تحديثات. الكتالوج محدّث (${catalog.items.length} تمرين).'
      : 'جديد: ${d.added.length} • معدّل: ${d.changed.length} • محذوف: ${d.removed.length}'
          '${synced > 0 ? '\nتم تحديث $synced تمرين في مكتبتك.' : ''}';
  await confirm(context, d.isEmpty ? 'محدّث ✅' : 'تم التحديث ✅', msg,
      ok: 'حسناً', cancel: 'إغلاق');
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String query = '';
  String cat = '';
  String equip = '';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = catalog.search(query: query, category: cat, equipment: equip);
        return Scaffold(
          appBar: AppBar(
            title: const Text('كتالوج التمارين'),
            actions: [
              IconButton(
                tooltip: 'تحديث من GitHub',
                icon: Icon(Icons.sync, color: p.accent),
                onPressed: () async {
                  await updateCatalogFlow(context);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: TextField(
                decoration: deco(context, 'بحث (اسم أو عضلة)'),
                onChanged: (v) => setState(() => query = v.trim()),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Pill('الكل',
                            selected: cat.isEmpty, onTap: () => setState(() => cat = ''))),
                    for (final c in kCategories)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Pill(c,
                            selected: cat == c, onTap: () => setState(() => cat = c)),
                      ),
                  ]),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Pill('كل المعدات',
                            selected: equip.isEmpty, onTap: () => setState(() => equip = ''))),
                    for (final e in kEquipLabels.entries)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Pill(e.value,
                            selected: equip == e.key,
                            onTap: () => setState(() => equip = e.key)),
                      ),
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(children: [
                Expanded(
                    child: Dim(
                        '${list.length} تمرين • نسخة الكتالوج ${catalog.version}'
                        '${catalog.updated.isNotEmpty ? ' • ${catalog.updated}' : ''}',
                        size: 12)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final e = list[i];
                  final have = store.ex(e.id) != null;
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    onTap: () => _open(context, e, have),
                    child: Row(children: [
                      ExIcon(e, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: p.text, fontSize: 15)),
                          Dim('${e.category} • ${kEquipLabels[e.equipment] ?? ''} • ${e.isTime ? 'وقتي' : 'عدات'}'
                              '${e.youtube.isNotEmpty ? ' • ▶︎' : ''}',
                              size: 12),
                        ]),
                      ),
                      if (have)
                        Icon(Icons.check_circle, color: p.green)
                      else
                        IconButton(
                          icon: Icon(Icons.add_circle_outline, color: p.accent),
                          onPressed: () {
                            store.addFromCatalog(e);
                            toast(context, 'أُضيف إلى مكتبتك');
                          },
                        ),
                    ]),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  void _open(BuildContext context, Exercise e, bool have) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          ex: e,
          editable: false,
          actionLabel: have ? null : 'إضافة إلى مكتبتي',
          onAction: (c) {
            store.addFromCatalog(e);
            toast(context, 'أُضيف إلى مكتبتك');
            return true;
          },
        ),
      ),
    );
  }
}
