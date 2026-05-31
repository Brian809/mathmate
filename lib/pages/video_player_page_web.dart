// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web 端 B站 视频播放页面 —— 使用 iframe 嵌入 B站 播放器。
class VideoPlayerPage extends StatefulWidget {
  final String title;
  final String bvId;

  const VideoPlayerPage({super.key, required this.title, required this.bvId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  bool _isLoading = true;
  bool _hasError = false;
  late final String _viewType;

  String get _embedUrl =>
      'https://player.bilibili.com/player.html?bvid=${widget.bvId}&autoplay=1&high_quality=1&danmaku=1';

  @override
  void initState() {
    super.initState();
    _viewType = 'bili-${widget.bvId}-${identityHashCode(this)}';

    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = _embedUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..allowFullscreen = true
        ..onLoad.listen((_) {
          if (mounted) setState(() => _isLoading = false);
        })
        ..onError.listen((_) {
          if (mounted) { setState(() { _isLoading = false; _hasError = true; }); }
        });
      return iframe;
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) setState(() { _isLoading = false; _hasError = true; });
    });
  }

  Future<void> _openInBilibili() async {
    final url = Uri.parse('https://www.bilibili.com/video/${widget.bvId}/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: '在 B站 打开',
            onPressed: _openInBilibili,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: <Widget>[
                HtmlElementView(viewType: _viewType),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.white54)),
                if (_hasError)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                        const SizedBox(height: 12),
                        const Text('视频加载失败', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _openInBilibili,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('在 B站 打开'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Text('视频来源: Bilibili', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openInBilibili,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.open_in_new, size: 14, color: Colors.white.withAlpha(130)),
                            const SizedBox(width: 4),
                            Text('在 B站 打开', style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
