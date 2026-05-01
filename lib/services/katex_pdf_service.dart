import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// KaTeX + WebView PDF 导出服务
/// 使用 WebView 渲染 KaTeX 公式，通过系统打印对话框导出 PDF
class KatexPdfService {
  /// 导出 PDF - 在 WebView 中预览，点击打印按钮触发系统打印
  Future<KatexPdfResult> exportToPdf({
    required String title,
    required String content,
    required BuildContext context,
    String subtitle = '由 MathMate 生成',
  }) async {
    try {
      // 生成 HTML 内容
      final String htmlContent = _generateHtml(title, subtitle, content);

      // 保存 HTML 文件到临时目录
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File htmlFile = File('${tempDir.path}/mathmate_print_$timestamp.html');
      await htmlFile.writeAsString(htmlContent);

      // 打开 WebView 打印对话框
      if (context.mounted) {
        await _openPrintDialog(context, htmlFile);
      }

      return KatexPdfResult(success: true);
    } catch (e) {
      return KatexPdfResult(success: false, error: e.toString());
    }
  }

  /// 生成 HTML 内容（包含 KaTeX）
  String _generateHtml(String title, String subtitle, String content) {
    // 处理 Markdown/LaTeX 内容
    final String processedContent = _processMarkdownLatex(content);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
  <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      font-size: 14px;
      line-height: 1.6;
      color: #333;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      background: #fff;
    }
    .header {
      text-align: center;
      border-bottom: 2px solid #3F51B5;
      padding-bottom: 16px;
      margin-bottom: 24px;
    }
    .header h1 {
      color: #3F51B5;
      font-size: 22px;
      margin: 0;
    }
    .header .subtitle {
      color: #666;
      font-size: 12px;
      margin-top: 4px;
    }
    .section { margin-bottom: 20px; }
    .section-title {
      font-size: 16px;
      font-weight: bold;
      color: #1A1A1A;
      border-left: 4px solid #3F51B5;
      padding-left: 10px;
      margin-bottom: 10px;
    }
    .content {
      padding: 12px;
      background: #F8F9FC;
      border-radius: 8px;
    }
    .formula-preview {
      padding: 16px;
      background: #E3F2FD;
      border-radius: 8px;
      text-align: center;
      margin-top: 12px;
    }
    .math-display {
      margin: 12px 0;
      overflow-x: auto;
      overflow-y: hidden;
      padding: 8px 0;
    }
    .math-display .katex { font-size: 1.1em; }
    pre {
      background: #F5F5F5;
      padding: 12px;
      border-radius: 6px;
      overflow-x: auto;
      font-size: 13px;
    }
    code {
      background: #F5F5F5;
      padding: 2px 6px;
      border-radius: 4px;
      font-family: 'Consolas', 'Monaco', monospace;
      font-size: 13px;
    }
    blockquote {
      border-left: 3px solid #3F51B5;
      margin: 12px 0;
      padding: 8px 16px;
      background: #F5F7FF;
      color: #555;
    }
    h1, h2, h3 { margin-top: 16px; margin-bottom: 8px; }
    ul, ol { padding-left: 24px; }
    li { margin-bottom: 4px; }
    @page { margin: 15mm; }
    @media print { body { padding: 0; } }
  </style>
</head>
<body>
  <div class="header">
    <h1>$title</h1>
    <div class="subtitle">$subtitle</div>
  </div>
  <div class="content">
    $processedContent
  </div>
  <script>
    document.addEventListener('DOMContentLoaded', function() {
      // 渲染 KaTeX 公式
      document.querySelectorAll('.math-tex').forEach(function(el) {
        try {
          katex.render(el.textContent, el, {
            throwOnError: false,
            displayMode: el.classList.contains('math-display')
          });
        } catch (e) {}
      });
      // 自动触发打印
      setTimeout(function() { window.print(); }, 800);
    });
  </script>
</body>
</html>
''';
  }

  /// 处理 Markdown 和 LaTeX 内容
  String _processMarkdownLatex(String content) {
    String text = content;

    // 处理代码块
    text = text.replaceAllMapped(
      RegExp(r'```(\w*)\n?([\s\S]*?)```'),
      (Match m) => '<pre><code>${_escapeHtml(m.group(2)?.trim() ?? '')}</code></pre>',
    );

    // 处理行内代码
    text = text.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (Match m) => '<code>${_escapeHtml(m.group(1) ?? '')}</code>',
    );

    // 处理 $$...$$ 展示数学
    text = text.replaceAllMapped(
      RegExp(r'\$\$([\s\S]*?)\$\$'),
      (Match m) => '<div class="math-display"><span class="math-tex">${_escapeHtml(m.group(1)?.trim() ?? '')}</span></div>',
    );

    // 处理 $...$ 内联数学
    text = text.replaceAllMapped(
      RegExp(r'\$([^\$\n]+?)\$'),
      (Match m) => '<span class="math-inline"><span class="math-tex">${_escapeHtml(m.group(1)?.trim() ?? '')}</span></span>',
    );

    // 处理标题
    text = text.replaceAllMapped(
      RegExp(r'^### (.+)$', multiLine: true),
      (Match m) => '<h3>${m.group(1)}</h3>',
    );
    text = text.replaceAllMapped(
      RegExp(r'^## (.+)$', multiLine: true),
      (Match m) => '<h2>${m.group(1)}</h2>',
    );
    text = text.replaceAllMapped(
      RegExp(r'^# (.+)$', multiLine: true),
      (Match m) => '<h1>${m.group(1)}</h1>',
    );

    // 处理加粗
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (Match m) => '<strong>${m.group(1)}</strong>',
    );
    text = text.replaceAllMapped(
      RegExp(r'\*([^*]+)\*'),
      (Match m) => '<em>${m.group(1)}</em>',
    );

    // 处理列表
    text = text.replaceAllMapped(
      RegExp(r'^\s*[-*+]\s+(.+)$', multiLine: true),
      (Match m) => '<li>${m.group(1)}</li>',
    );
    text = text.replaceAllMapped(
      RegExp(r'(<li>.*</li>\n?)+'),
      (Match m) => '<ul>${m.group(0)}</ul>',
    );

    // 处理引用
    text = text.replaceAllMapped(
      RegExp(r'^>\s*(.+)$', multiLine: true),
      (Match m) => '<blockquote>${m.group(1)}</blockquote>',
    );

    // 处理换行为段落
    final lines = text.split('\n');
    final buffer = StringBuffer();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('<h') ||
          trimmed.startsWith('<pre') ||
          trimmed.startsWith('<ul') ||
          trimmed.startsWith('<ol') ||
          trimmed.startsWith('<blockquote') ||
          trimmed.startsWith('<div class="math')) {
        buffer.write(trimmed);
      } else if (!trimmed.startsWith('</')) {
        buffer.write('<p>$trimmed</p>');
      } else {
        buffer.write(trimmed);
      }
    }

    return buffer.toString();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// 打开 WebView 打印对话框
  Future<void> _openPrintDialog(BuildContext context, File htmlFile) async {
    late WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFile(htmlFile.path);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('导出 PDF'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.75,
          child: WebViewWidget(controller: controller),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // 执行打印脚本
              await controller.runJavaScript('window.print();');
            },
            icon: const Icon(Icons.print),
            label: const Text('打印/导出 PDF'),
          ),
        ],
      ),
    );
  }

  /// 清理临时文件
  Future<void> cleanup() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();
      for (final file in files) {
        if (file is File && file.path.contains('mathmate_print_')) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }
}

class KatexPdfResult {
  final bool success;
  final String? error;
  final String? pdfPath;

  KatexPdfResult({required this.success, this.error, this.pdfPath});
}
