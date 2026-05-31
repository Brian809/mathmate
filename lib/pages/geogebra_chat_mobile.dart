import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:mathmate/services/geogebra_agent_service.dart';
import 'package:mathmate/visualization/geogebra_mobile_bridge.dart';

/// 原生 Flutter GeoGebra Chat 页面 —— 移动端专用。
///
/// 架构：
/// - 上半：GeoGebra 画布（WebView 加载本地 HTML + JS Bridge 注入）
/// - 下半：聊天对话面板（Agent 流式响应 + 工具调用）
class GeogebraChatPage extends StatefulWidget {
  const GeogebraChatPage({super.key});

  @override
  State<GeogebraChatPage> createState() => _GeogebraChatPageState();
}

class _GeogebraChatPageState extends State<GeogebraChatPage> {
  final GeogebraAgentService _agent = GeogebraAgentService();
  late GeogebraMobileBridge _bridge;

  WebViewController? _ggbController;
  bool _ggbReady = false;
  bool _ggbLoading = true;

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatBubble> _bubbles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initGeoGebra();
  }

  Future<void> _initGeoGebra() async {
    try {
      final ctrl = WebViewController();
      ctrl.setJavaScriptMode(JavaScriptMode.unrestricted);
      ctrl.setBackgroundColor(const Color(0xFFFFFFFF));

      _bridge = GeogebraMobileBridge(ctrl);
      _ggbController = ctrl;
      _agent.onToolCall = _executeTool;

      ctrl.addJavaScriptChannel(
        'GgbBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          if (msg.message.startsWith('ready|')) {
            _bridge.markReady();
            if (mounted) setState(() { _ggbReady = true; _ggbLoading = false; });
            return;
          }
          _bridge.handleMessage(msg.message);
        },
      );

      // 优先用数学工具箱已解压的本地 GeoGebra 文件（秒开），否则用 CDN
      final localPath =
          '${(await getApplicationDocumentsDirectory()).path}/geogebra/graphing.html';
      final useLocal = File(localPath).existsSync();

      if (useLocal) {
        ctrl.setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) => _injectBridge(ctrl),
          ),
        );
        await ctrl.loadFile(localPath);
      } else {
        await ctrl.loadHtmlString(_buildGgbHtml());
      }
    } catch (e) {
      debugPrint('[GeoChat] Init error: $e');
      if (mounted) setState(() => _ggbLoading = false);
    }
  }

  /// 注入 JS Bridge —— 仅本地 GeoGebra 5.4 文件需要（CDN 版 HTML 已内置）
  Future<void> _injectBridge(WebViewController ctrl) async {
    const bridgeJs = '''
(function() {
  if (window._ggbBridgeReady) return;
  var ggb = null;
  function ready(api) {
    ggb = api;
    window._ggbBridgeReady = true;
    window._ggbBridgeCallback = function(msg) {
      var p = msg.split('|'), t = p[0], id = p[1], pl = p.slice(2).join('|');
      try {
        var r = '';
        switch(t) {
          case 'evalCommand':
            // GeoGebra 5.x 用 evalCommand，6.x 用 evalCommandGetLabels
            if (typeof ggb.evalCommandGetLabels === 'function') {
              var lb = ggb.evalCommandGetLabels(pl);
              var er = '';
              try { er = ggb.getErrorString() || ''; } catch(e) {}
              r = JSON.stringify({success: !er, label: lb||null, error: er||null});
            } else if (typeof ggb.evalCommand === 'function') {
              var ok = ggb.evalCommand(pl);
              var err = '';
              try { err = ggb.getErrorString ? ggb.getErrorString() : ''; } catch(e) {}
              r = JSON.stringify({success: ok && !err, label: null, error: err||null});
            } else {
              r = JSON.stringify({success: false, label: null, error: 'no evalCommand API'});
            }
            break;
          case 'getXML':
            try { r = ggb.getXML ? ggb.getXML() : ''; } catch(e) { r = ''; }
            break;
          case 'deleteObject':
            try { ggb.deleteObject(pl); } catch(e) {}
            r = 'true';
            break;
          case 'setUndoPoint':
            try { ggb.setUndoPoint(); } catch(e) {}
            r = 'true';
            break;
          case 'undo':
            try { ggb.undo(); } catch(e) {}
            r = 'true';
            break;
          case 'setPerspective':
            try { ggb.setPerspective(pl); } catch(e) {}
            r = 'true';
            break;
          case 'reset':
            try { ggb.reset(); } catch(e) {}
            r = 'true';
            break;
          case 'getSelectedObjects':
            try { r = ggb.getSelectedObjects ? ggb.getSelectedObjects().join(',') : ''; } catch(e) { r = ''; }
            break;
        }
        GgbBridge.postMessage(t + '|' + id + '|' + r);
      } catch(e) { GgbBridge.postMessage('error|' + id + '|' + e.toString()); }
    };
    GgbBridge.postMessage('ready|0|{}');
  }
  if (window.ggbApplet) { ready(window.ggbApplet); return; }
  if (window.ggbApp && window.ggbApp.evalCommand) { ready(window.ggbApp); return; }
  var n = 0;
  var iv = setInterval(function() {
    n++;
    var api = window.ggbApplet || window.ggbApp || null;
    if (api && (typeof api.evalCommand === 'function' || typeof api.evalCommandGetLabels === 'function')) {
      clearInterval(iv); ready(api);
    } else if (n > 150) {
      clearInterval(iv);
      GgbBridge.postMessage('error|0|GeoGebra API not found after timeout');
    }
  }, 100);
})();
''';
    await ctrl.runJavaScript(bridgeJs);
  }

  /// CDN 版精简 GeoGebra HTML（本地文件不存在时使用）
  String _buildGgbHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
<style>
  * { margin:0; padding:0; }
  html, body, #ggb { width:100%; height:100%; overflow:hidden; }
</style>
<script src="https://www.geogebra.org/apps/deployggb.js"></script>
</head>
<body>
<div id="ggb"></div>
<script>
  var ggbApp = new GGBApplet({
    "appName": "graphing",
    "width": "100%",
    "height": "100%",
    "showToolBar": false,
    "showAlgebraInput": false,
    "showMenuBar": false,
    "enableLabelDrags": false,
    "enableShiftDragZoom": true,
    "enableRightClick": false,
    "showResetIcon": false,
    "enable3d": true,
    "errorDialogsActive": false,
    "useBrowserForJS": false,
    "language": "zh",
    "borderColor": "#FFFFFF"
  }, true);
  ggbApp.setHTML5Codebase("https://www.geogebra.org/apps/HTML5/5.0/web3d/");

  window._ggbBridgeCallback = function(msg) {
    var parts = msg.split('|');
    var type = parts[0], msgId = parts[1];
    var payload = parts.length > 2 ? parts.slice(2).join('|') : '';
    try {
      var result = '';
      switch(type) {
        case 'evalCommand':
          var label = ggbApp.evalCommandGetLabels(payload);
          var err = (ggbApp.getErrorString && ggbApp.getErrorString()) || '';
          result = JSON.stringify({success: !err, label: label||null, error: err||null});
          break;
        case 'getXML':
          result = ggbApp.getXML() || '';
          break;
        case 'deleteObject':
          ggbApp.deleteObject(payload); result = 'true'; break;
        case 'setUndoPoint':
          ggbApp.setUndoPoint(); result = 'true'; break;
        case 'undo':
          ggbApp.undo(); result = 'true'; break;
        case 'setPerspective':
          ggbApp.setPerspective(payload); result = 'true'; break;
        case 'reset':
          ggbApp.reset(); result = 'true'; break;
        case 'getSelectedObjects':
          result = ggbApp.getSelectedObjects ? ggbApp.getSelectedObjects().join(',') : '';
          break;
        default: result = 'unknown';
      }
      GgbBridge.postMessage(type + '|' + msgId + '|' + result);
    } catch(e) {
      GgbBridge.postMessage('error|' + msgId + '|' + e.toString());
    }
  };

  ggbApp.inject('ggb', 'preferHTML5');
  GgbBridge.postMessage('ready|0|{}');
</script>
</body>
</html>
''';
  }

  /// 桥接 Agent 工具调用到 GeoGebra
  Future<String> _executeTool(String toolName, Map<String, dynamic> args) async {
    try {
      switch (toolName) {
        case 'getCanvasContext':
          final xml = await _bridge.getXML();
          final selected = await _bridge.getSelectedObjects();
          return _summarizeXML(xml, selected);

        case 'executeGeoGebraCommand':
          final cmd = args['command'] as String? ?? '';
          if (cmd.isEmpty) return 'Error: empty command';
          final result = await _bridge.evalCommand(cmd);
          if (result['success'] == true) {
            return '成功: ${result['label'] ?? "OK"}';
          }
          return '失败: ${result['error'] ?? "未知错误"}';

        case 'deleteGeoGebraObject':
          final label = args['label'] as String? ?? '';
          final ok = await _bridge.deleteObject(label);
          return ok ? '已删除 $label' : '删除 $label 失败';

        case 'setUndoPoint':
          final ok = await _bridge.setUndoPoint();
          return ok ? '撤销点已设置' : '设置撤销点失败';

        case 'undo':
          final ok = await _bridge.undo();
          return ok ? '已撤销' : '撤销失败';

        case 'setPerspective':
          final mode = args['mode'] as String? ?? 'G';
          final ok = await _bridge.setPerspective(mode);
          return ok ? '切换至 ${mode == 'T' ? '3D' : '2D'} 视图' : '切换视图失败';

        case 'getSelectedObjects':
          final objects = await _bridge.getSelectedObjects();
          return objects.isEmpty ? '无选中对象' : '选中: ${objects.join(", ")}';

        default:
          return '未知工具: $toolName';
      }
    } catch (e) {
      return '工具执行异常: $e';
    }
  }

  String _summarizeXML(String xml, List<String> selected) {
    if (xml.isEmpty) return '{}';
    final elementExp = RegExp(r'<element[^>]*type="(\w+)"[^>]*label="([^"]*)"');
    final matches = elementExp.allMatches(xml);
    final elements = matches.map((m) => '${m.group(1)}:${m.group(2)}').toList();
    final buf = StringBuffer();
    buf.writeln('{');
    buf.writeln('  "elements": ${elements.isNotEmpty ? elements.toString() : "[]"},');
    buf.writeln('  "selectedObjects": ${selected.toString()}');
    buf.writeln('}');
    return buf.toString();
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isLoading || !_ggbReady) return;

    _inputCtrl.clear();
    setState(() {
      _bubbles.add(ChatBubble(role: 'user', content: text));
      _bubbles.add(ChatBubble(role: 'assistant', content: '', isStreaming: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final history = <Map<String, String>>[];
    for (final b in _bubbles.where((b) => !b.isStreaming)) {
      history.add({'role': b.role, 'content': b.content});
    }
    history.removeLast(); // 去掉刚加的 streaming 占位

    try {
      final assistantIdx = _bubbles.length - 1;
      String fullContent = '';
      String pendingTool = '';

      await for (final chunk in _agent.chat(messages: history)) {
        if (!mounted) break;

        if (chunk.error != null) {
          fullContent += '\n\n> ⚠️ ${chunk.error}';
        } else if (chunk.toolCallName != null) {
          pendingTool = chunk.toolCallName!;
          // 立即显示工具调用状态
          fullContent += '\n\n⏳ 调用工具: `$pendingTool`...';
        } else if (chunk.toolResult != null) {
          // 替换掉之前的 ⏳ 占位为实际结果
          if (pendingTool.isNotEmpty) {
            final placeholder = '\n\n⏳ 调用工具: `$pendingTool`...';
            fullContent = fullContent.replaceFirst(
              placeholder,
              '\n\n✅ `$pendingTool` → ${chunk.toolResult}',
            );
            pendingTool = '';
          }
        } else if (chunk.textDelta != null) {
          fullContent += chunk.textDelta!;
        }

        if (mounted) {
          setState(() {
            _bubbles[assistantIdx] = ChatBubble(
              role: 'assistant',
              content: fullContent,
              isStreaming: !chunk.isDone,
            );
          });
          _scrollToBottom();
        }

        if (chunk.isDone) break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final idx = _bubbles.length - 1;
          _bubbles[idx] = ChatBubble(role: 'assistant', content: '请求失败: $e');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearCanvas() {
    _bridge.reset();
    setState(() => _bubbles.clear());
  }

  void _undoLast() {
    _bridge.undo();
  }

  @override
  void dispose() {
    _agent.cancel();
    _bridge.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          // GeoGebra 画布区域
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                if (_ggbController != null)
                  Positioned.fill(
                    child: WebViewWidget(controller: _ggbController!),
                  ),
                if (_ggbLoading)
                  const Center(child: CircularProgressIndicator()),
                // GeoGebra ready 标记
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black38,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _ggbReady ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _ggbReady ? '就绪' : '等待...',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: _undoLast,
                        icon: const Icon(Icons.undo, color: Colors.white),
                        tooltip: '撤销',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black38,
                        ),
                      ),
                      IconButton(
                        onPressed: _clearCanvas,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                        tooltip: '清空画布',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 分隔线
          Container(height: 1, color: cs.outlineVariant),

          // 聊天区域
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Icon(Icons.draw, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        '对话绘图',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // 消息列表
                Expanded(
                  child: _bubbles.isEmpty
                      ? _buildEmptyState(cs)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(12),
                          itemCount: _bubbles.length,
                          itemBuilder: (_, i) => _buildBubble(_bubbles[i], cs),
                        ),
                ),

                // 输入栏
                _buildInputBar(cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    final suggestions = [
      '画一个以A为圆心，半径为3的圆',
      '画一个三角形ABC',
      '画椭圆 x²/4 + y²/9 = 1',
      '画出 y = x² 和它的切线',
      '画一个正六边形',
    ];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 40,
              color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Text('描述你想绘制的图形',
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions
                .map((s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      onPressed: _ggbReady
                          ? () {
                              _inputCtrl.text = s;
                              _sendMessage();
                            }
                          : null,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatBubble bubble, ColorScheme cs) {
    final isUser = bubble.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 14),
              ),
            ),
            child: isUser
                ? Text(bubble.content,
                    style: TextStyle(fontSize: 14, color: cs.onPrimary))
                : bubble.isStreaming && bubble.content.isEmpty
                    ? SizedBox(
                        width: 40,
                        child: LinearProgressIndicator(
                          backgroundColor: cs.surfaceContainerHighest,
                          color: cs.primary,
                        ),
                      )
                    : _buildAssistantContent(bubble.content),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantContent(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('🔧')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontFamily: 'monospace')),
        ));
      } else if (line.startsWith('> ⚠️')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ));
      } else if (line.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line, style: const TextStyle(fontSize: 13, height: 1.5)),
        ));
      }
    }

    if (widgets.isEmpty) return const Text('');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInputBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 3,
                enabled: !_isLoading && _ggbReady,
                decoration: InputDecoration(
                  hintText: _ggbReady ? '描述你要画的图形...' : '等待 GeoGebra 就绪...',
                  hintStyle: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed:
                  _isLoading || !_ggbReady ? null : _sendMessage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 18),
              style: IconButton.styleFrom(backgroundColor: cs.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble {
  final String role;
  final String content;
  final bool isStreaming;
  ChatBubble({
    required this.role,
    required this.content,
    this.isStreaming = false,
  });
}
