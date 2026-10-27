// ويدجت Text يترجم نصه تلقائياً حسب لغة التطبيق. يُستخدم بدل Text الخاص بـ Flutter.
import 'package:flutter/material.dart' as m;

import 'i18n.dart';

class Text extends m.StatelessWidget {
  final String data;
  final m.TextStyle? style;
  final m.TextAlign? textAlign;
  final m.TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final m.TextDirection? textDirection;
  final String? semanticsLabel;

  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  });

  @override
  m.Widget build(m.BuildContext context) => m.Text(
        tr(data),
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
        softWrap: softWrap,
        textDirection: textDirection,
        semanticsLabel: semanticsLabel,
      );
}
