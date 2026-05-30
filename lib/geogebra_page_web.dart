// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

/// Web 平台 GeoGebra 页面 —— 使用 iframe 嵌入 GeoGebra 官方在线应用。
///
/// 因为 webview_flutter 不支持 Web 平台，而 MathMate 原本在移动端通过
/// WebView 加载本地 GeoGebra HTML 文件。此文件提供 Web 端的替代实现：
/// 通过 dart:html 的 IFrameElement 直接加载 GeoGebra 官网的在线应用。
class GeogebraPage extends StatefulWidget {
  final String appName;

  const GeogebraPage({
    super.key,
    this.appName = 'graphing',
  });

  @override
  State<GeogebraPage> createState() => _GeogebraPageWebState();
}

class _GeogebraPageWebState extends State<GeogebraPage> {
  bool _loading = true;
  bool _hasError = false;
  late final String _viewType;

  String get _title {
    switch (widget.appName) {
      case 'geometry':
      case 'classic':
        return '几何画板';
      case 'graphing':
        return '函数绘图';
      case '3d':
        return '3D视图';
      case 'scientific':
        return '科学计算器';
      case 'notes':
        return '尺规作图';
      case 'probability':
        return '概率模型';
      default:
        return '几何画板';
    }
  }

  /// 将 MathMate 的 appName 映射为 GeoGebra 官网 URL。
  /// 参数 ?embed=true 请求简化嵌入视图（隐藏导航栏等）。
  static String _geoGebraUrl(String appName) {
    switch (appName) {
      case 'geometry':
        return 'https://www.geogebra.org/geometry';
      case 'classic':
        return 'https://www.geogebra.org/classic';
      case 'graphing':
        return 'https://www.geogebra.org/graphing';
      case '3d':
        return 'https://www.geogebra.org/3d';
      case 'scientific':
        return 'https://www.geogebra.org/scientific';
      case 'notes':
        return 'https://www.geogebra.org/notes';
      case 'probability':
        return 'https://www.geogebra.org/probability';
      default:
        return 'https://www.geogebra.org/geometry';
    }
  }

  @override
  void initState() {
    super.initState();
    _viewType = 'geogebra-${widget.appName}-${identityHashCode(this)}';

    // 注册 platform view factory，创建 iframe 嵌入 GeoGebra
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final html.IFrameElement iframe = html.IFrameElement()
        ..src = _geoGebraUrl(widget.appName)
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.overflow = 'hidden'
        ..allowFullscreen = true
        ..onLoad.listen((html.Event event) {
          if (mounted) {
            setState(() => _loading = false);
          }
        })
        ..onError.listen((html.Event event) {
          if (mounted) {
            setState(() {
              _loading = false;
              _hasError = true;
            });
          }
        });

      return iframe;
    });

    // 超时兜底：15 秒后如果还在 loading 则显示错误
    Future<void>.delayed(const Duration(seconds: 15), () {
      if (mounted && _loading) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    });
  }

  void _retry() {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    // 重新触发 iframe 加载
    final String freshViewType = 'geogebra-${widget.appName}-retry-${DateTime.now().millisecondsSinceEpoch}';
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(freshViewType, (int viewId) {
      final html.IFrameElement iframe = html.IFrameElement()
        ..src = _geoGebraUrl(widget.appName)
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..onLoad.listen((html.Event event) {
          if (mounted) {
            setState(() => _loading = false);
          }
        })
        ..onError.listen((html.Event event) {
          if (mounted) {
            setState(() {
              _loading = false;
              _hasError = true;
            });
          }
        });
      return iframe;
    });
    if (mounted) {
      setState(() {
        _viewType = freshViewType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: <Widget>[
          // 主内容 —— HtmlElementView 嵌入 iframe
          HtmlElementView(viewType: _viewType),
          // 加载中遮罩
          if (_loading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    '加载中...',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          // 错误提示
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.error_outline,
                    color: cs.onSurface.withValues(alpha: 0.4),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GeoGebra 加载失败',
                    style: TextStyle(
                      fontSize: 16,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请检查网络连接后重试',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
