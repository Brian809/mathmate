import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PdfViewerPage({super.key, required this.pdfPath, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final WebViewController _controller;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPdfViewer();
  }

  void _initPdfViewer() {
    final file = File(widget.pdfPath);
    final bytes = file.readAsBytesSync();
    final base64Pdf = base64Encode(bytes);

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #525659; display: flex; flex-direction: column; align-items: center; overflow-y: auto; }
    canvas { margin: 10px 0; box-shadow: 0 2px 8px rgba(0,0,0,0.3); }
    .page-container { display: flex; flex-direction: column; align-items: center; padding: 20px 0; }
  </style>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
</head>
<body>
  <div class="page-container" id="container"></div>
  <script>
    pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
    var pdfDoc = null;
    var currentPage = 1;
    var totalPages = 0;
    var scale = 1.0;

    function renderPage(num) {
      pdfDoc.getPage(num).then(function(page) {
        var container = document.getElementById('container');
        var canvas = document.createElement('canvas');
        canvas.id = 'page-' + num;
        canvas.style.width = '95%';
        canvas.style.maxWidth = '800px';
        var ctx = canvas.getContext('2d');
        var viewport = page.getViewport({scale: scale});
        canvas.height = viewport.height;
        canvas.width = viewport.width;
        container.appendChild(canvas);

        // 自适应缩放
        var maxWidth = Math.min(window.innerWidth * 0.95, 800);
        if (viewport.width > maxWidth) {
          var ratio = maxWidth / viewport.width;
          canvas.style.width = maxWidth + 'px';
          canvas.style.height = (viewport.height * ratio) + 'px';
        }

        page.render({canvasContext: ctx, viewport: viewport}).promise.then(function() {
          window.flutterMessage.postMessage(JSON.stringify({
            type: 'pageRendered',
            page: num,
            total: totalPages
          }));
        });
      });
    }

    function loadPdf(base64Data) {
      var raw = atob(base64Data);
      var uint8Array = new Uint8Array(raw.length);
      for (var i = 0; i < raw.length; i++) { uint8Array[i] = raw.charCodeAt(i); }
      pdfjsLib.getDocument({data: uint8Array}).promise.then(function(pdf) {
        pdfDoc = pdf;
        totalPages = pdf.numPages;
        window.flutterMessage.postMessage(JSON.stringify({
          type: 'loaded',
          total: totalPages
        }));
        renderPage(currentPage);
      });
    }

    function goToPage(num) {
      if (num < 1 || num > totalPages) return;
      currentPage = num;
      document.getElementById('container').innerHTML = '';
      renderPage(currentPage);
    }

    document.addEventListener('DOMContentLoaded', function() {
      loadPdf('$base64Pdf');
    });
  </script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF525659))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..addJavaScriptChannel(
        'flutterMessage',
        onMessageReceived: (JavaScriptMessage msg) {
          try {
            final match = RegExp(r'\{.*\}').firstMatch(msg.message);
            final data = match?.group(0) ?? msg.message;
            final map = jsonDecode(data) as Map<String, dynamic>;
            if (map['type'] == 'loaded' || map['type'] == 'pageRendered') {
              if (mounted) {
                setState(() {
                  _totalPages = (map['total'] as num?)?.toInt() ?? 1;
                  if (map['page'] != null) {
                    _currentPage = (map['page'] as num).toInt();
                  }
                  _isLoading = false;
                });
              }
            }
          } catch (_) {}
        },
      )
      ..loadHtmlString(html);
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
    _controller.runJavaScript('goToPage($page);');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF525659),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: WebViewWidget(controller: _controller)),
              // 底部翻页栏
              _buildPageBar(),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildPageBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}
