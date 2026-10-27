// تشغيل فيديو يوتيوب داخل التطبيق.
import 'package:flutter/material.dart' hide Text;
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../theme.dart';
import '../widgets.dart';

/// يستخرج معرّف الفيديو (11 خانة) من أي رابط يوتيوب، أو يعيد null.
String? youtubeId(String url) {
  final u = url.trim();
  if (u.isEmpty) return null;
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(u)) return u;
  final pats = [
    RegExp(r'[?&]v=([A-Za-z0-9_-]{11})'),
    RegExp(r'youtu\.be/([A-Za-z0-9_-]{11})'),
    RegExp(r'youtube\.com/(?:embed|shorts|live|v)/([A-Za-z0-9_-]{11})'),
  ];
  for (final r in pats) {
    final m = r.firstMatch(u);
    if (m != null) return m.group(1);
  }
  return null;
}

bool isYoutubeUrl(String url) => youtubeId(url) != null;

Future<void> openExternal(BuildContext context, String url) async {
  var u = url.trim();
  if (u.isEmpty) return;
  if (!u.startsWith('http')) u = 'https://$u';
  try {
    final ok = await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) toast(context, 'تعذر فتح الرابط');
  } catch (_) {
    if (context.mounted) toast(context, 'تعذر فتح الرابط');
  }
}

class YtPlayer extends StatefulWidget {
  final String videoId;
  final String originalUrl;
  const YtPlayer({super.key, required this.videoId, required this.originalUrl});

  @override
  State<YtPlayer> createState() => _YtPlayerState();
}

class _YtPlayerState extends State<YtPlayer> {
  late final YoutubePlayerController _c;

  @override
  void initState() {
    super.initState();
    _c = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _c.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusSm),
        child: YoutubePlayerScaffold(
          controller: _c,
          aspectRatio: 16 / 9,
          builder: (context, player) => player,
        ),
      ),
      const SizedBox(height: 4),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton.icon(
          onPressed: () => openExternal(context, widget.originalUrl),
          icon: Icon(Icons.open_in_new, size: 16, color: p.dim),
          label: Text('فتح في يوتيوب',
              style: TextStyle(color: p.dim, fontSize: 12)),
        ),
      ),
    ]);
  }
}
