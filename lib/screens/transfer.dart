// الاستيراد والتصدير: Excel / JSON / برومبت الذكاء الاصطناعي / نسخ احتياطي.
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../engine.dart';
import '../io.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _req = TextEditingController();

  @override
  void dispose() {
    _req.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final plan = store.plan;
        return Scaffold(
          appBar: AppBar(title: const Text('الاستيراد والتصدير')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('📥 استيراد خطة',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900, color: p.text)),
                  const SizedBox(height: 6),
                  const Dim(
                      'اختر ملف Excel (.xlsx) أو JSON عبّأته بنفسك أو جهّزه لك ذكاء اصطناعي أو مدرب. '
                      'يُفحص الملف أولاً وتظهر لك الأخطاء قبل الاستيراد.'),
                  const SizedBox(height: 12),
                  PButton('اختيار ملف الخطة', icon: Icons.upload_file,
                      onTap: () => _pickPlan(context)),
                ]),
              ),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('🤖 خطة بالذكاء الاصطناعي',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900, color: p.text)),
                  const SizedBox(height: 6),
                  const Dim(
                      'اكتب ما تريده (هدفك، المعدات، أيام التمرين، إصابات...). '
                      'يُرفق التطبيق مع طلبك كتالوج التمارين ليختار الذكاء الاصطناعي منه تلقائياً، '
                      'ثم يعطيك خطة جاهزة تلصقها هنا فتتحول مباشرة إلى خطة في التطبيق.'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _req,
                    maxLines: 4,
                    decoration: deco(context, 'مثال: أريد تضخيم عضلات، عندي دمبل فقط، 4 أيام في الأسبوع، 90 يوماً'),
                  ),
                  const SizedBox(height: 12),
                  PButton('نسخ البرومبت', icon: Icons.copy, onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: buildAiPrompt(request: _req.text)));
                    if (context.mounted) toast(context, 'تم نسخ البرومبت');
                  }),
                  const SizedBox(height: 8),
                  PButton('مشاركة البرومبت', icon: Icons.share, style: BtnStyle.tonal,
                      onTap: () => Share.share(buildAiPrompt(request: _req.text),
                          subject: 'Workout plan prompt')),
                  const SizedBox(height: 8),
                  PButton('لصق رد الذكاء الاصطناعي واستيراده', icon: Icons.content_paste,
                      style: BtnStyle.green, onTap: () => _pasteImport(context)),
                  const SizedBox(height: 6),
                  const Dim('بدلاً من اللصق يمكنك حفظ الرد في ملف .json واستيراده من الأعلى.',
                      size: 12),
                ]),
              ),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('📤 تصدير',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900, color: p.text)),
                  const SizedBox(height: 12),
                  PButton('قالب Excel للتعبئة', icon: Icons.table_chart, style: BtnStyle.tonal,
                      onTap: () => _run(context, exportTemplateExcel)),
                  const SizedBox(height: 8),
                  PButton(
                      plan == null ? 'لا توجد خطة للتصدير' : 'تصدير «${plan.name}» Excel',
                      icon: Icons.grid_on,
                      style: BtnStyle.tonal,
                      onTap: plan == null ? null : () => _run(context, () => exportPlanExcel(plan))),
                  const SizedBox(height: 8),
                  PButton(
                      plan == null ? 'لا توجد خطة للتصدير' : 'تصدير «${plan.name}» JSON',
                      icon: Icons.data_object,
                      style: BtnStyle.tonal,
                      onTap: plan == null ? null : () => _run(context, () => exportPlanJson(plan))),
                ]),
              ),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('💾 نسخة احتياطية كاملة',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900, color: p.text)),
                  const SizedBox(height: 6),
                  const Dim(
                      'كل بياناتك: الخطط، السجلات، الجسم، الماء والسعرات. الصور لا تدخل في النسخة. '
                      'احفظها في مكان آمن (مثلاً سيرفرك المنزلي).'),
                  const SizedBox(height: 12),
                  PButton('تصدير نسخة احتياطية', icon: Icons.save_alt,
                      onTap: () => _run(context, exportBackup)),
                  const SizedBox(height: 8),
                  PButton('استعادة من نسخة', icon: Icons.restore, style: BtnStyle.outline,
                      onTap: () => _restore(context)),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _run(BuildContext context, Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      if (context.mounted) toast(context, 'تعذر التنفيذ: $e');
    }
  }

  Future<Uint8List?> _pick(BuildContext context, List<String> ext, {String? nameOut}) async {
    try {
      final r = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ext, withData: true);
      if (r == null || r.files.isEmpty) return null;
      final f = r.files.single;
      Uint8List? bytes = f.bytes;
      if (bytes == null && f.path != null) bytes = await File(f.path!).readAsBytes();
      if (bytes == null) {
        if (context.mounted) toast(context, 'تعذرت قراءة الملف');
        return null;
      }
      _lastName = f.name;
      return bytes;
    } catch (e) {
      if (context.mounted) toast(context, 'تعذر اختيار الملف: $e');
      return null;
    }
  }

  static String _lastName = '';

  Future<void> _pickPlan(BuildContext context) async {
    final bytes = await _pick(context, ['xlsx', 'json']);
    if (bytes == null || !context.mounted) return;
    final res = await parseImportBytes(bytes, _lastName);
    if (!context.mounted) return;
    await _showResult(context, res);
  }

  Future<void> _pasteImport(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final txt = data?.text ?? '';
    if (txt.trim().isEmpty) {
      if (context.mounted) toast(context, 'الحافظة فارغة. انسخ رد الذكاء الاصطناعي أولاً.');
      return;
    }
    final res = parseImportText(txt);
    if (!context.mounted) return;
    await _showResult(context, res);
  }

  Future<void> _restore(BuildContext context) async {
    final ok = await confirm(context, 'استعادة نسخة',
        'ستُستبدل كل بياناتك الحالية بمحتوى النسخة. هل أنت متأكد؟',
        ok: 'استعادة', danger: true);
    if (!ok || !context.mounted) return;
    final bytes = await _pick(context, ['json']);
    if (bytes == null || !context.mounted) return;
    final msg = restoreBackupFromBytes(bytes);
    toast(context, msg);
  }

  Future<void> _showResult(BuildContext context, ImportResult r) async {
    await showSheet<void>(context, (ctx) {
      final p = ctx.pal;
      final plan = r.plan;
      return SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.ok ? 'الملف سليم ✅' : 'يوجد أخطاء ❌',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: r.ok ? p.green : p.red)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(children: [
                if (plan != null) ...[
                  AppCard(
                    color: p.surface2,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(plan.name,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900, color: p.text)),
                      const SizedBox(height: 4),
                      Dim('${plan.totalDays} يوم • تبدأ ${fmtDate(plan.startDate)}'),
                      Dim(patternLine(plan), size: 12.5),
                      for (final d in plan.dayTypes)
                        Dim('${d.emoji} ${d.name}: ${d.isRest ? 'راحة' : '${d.items.length} عناصر'}',
                            size: 12.5),
                      Dim('${r.exercises.length} تمرين سيُضاف/يُحدَّث في المكتبة',
                          size: 12.5),
                      if (r.profile != null)
                        const Dim('ستُحدَّث معلومات الجسم من الملف', size: 12.5),
                      if (r.workoutMinutes != null)
                        Dim('وقت التمرين: ${fmtTime(r.workoutMinutes!)}', size: 12.5),
                    ]),
                  ),
                ],
                if (r.errors.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('أخطاء يجب إصلاحها (${r.errors.length})',
                      style: TextStyle(fontWeight: FontWeight.w900, color: p.red)),
                  const SizedBox(height: 4),
                  for (final e in r.errors)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('• $e', style: TextStyle(color: p.text, height: 1.4)),
                    ),
                ],
                if (r.warnings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('تنبيهات (${r.warnings.length})',
                      style: TextStyle(fontWeight: FontWeight.w900, color: p.amber)),
                  const SizedBox(height: 4),
                  for (final w in r.warnings)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('• $w', style: TextStyle(color: p.dim, height: 1.4)),
                    ),
                ],
              ]),
            ),
            const SizedBox(height: 8),
            if (r.ok)
              PButton('استيراد الخطة وتفعيلها', icon: Icons.check, onTap: () {
                applyImport(r);
                Navigator.pop(ctx);
                toast(context, 'تم استيراد الخطة وجدولة التنبيهات');
              })
            else
              PButton('إغلاق', style: BtnStyle.tonal, onTap: () => Navigator.pop(ctx)),
          ]),
        ),
      );
    });
  }

  static String patternLine(Plan p) =>
      p.pattern.map((id) => p.dayTypeById(id).name).join(' ← ');
}
