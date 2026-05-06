import 'package:flutter/material.dart';
import 'package:mathmate/visualization/models.dart';
import 'package:mathmate/visualization/geometry_painter.dart';
import 'package:mathmate/visualization/safe_json_parser.dart';

class VisualizationPage extends StatefulWidget {
  final Map<String, dynamic> scene;
  final String title;

  const VisualizationPage({
    super.key,
    required this.scene,
    this.title = '几何可视化',
  });

  @override
  State<VisualizationPage> createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late GeometryScene _scene;

  Map<String, double> _dragOverrides = {};
  String? _draggingGliderId;
  int _paintVersion = 0;
  bool _animationPaused = false;

  @override
  void initState() {
    super.initState();
    _scene = SafeJsonParser.parseSceneFromMap(widget.scene);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleAnimation() {
    setState(() {
      _animationPaused = !_animationPaused;
      if (_animationPaused) {
        _animController.stop();
      } else {
        _animController.repeat();
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPos = box.globalToLocal(details.globalPosition);
    final size = box.size;
    final v = _scene.viewport;
    final byId = {for (final e in _scene.elements) e.id: e};

    String? bestId;
    double bestDist = double.infinity;

    for (final e in _scene.elements) {
      if (e is GliderElement && e.isDraggable) {
        final t = _dragOverrides.containsKey(e.id)
            ? _dragOverrides[e.id]!
            : (e.isAnimated ? _animController.value : e.t);
        final mathPos = GeometryPainter.gliderMathPosition(e, byId, t);
        if (mathPos == null) continue;
        final pixel = GeometryPainter.mathToPixel(mathPos, size, v);
        final dist = (pixel - localPos).distance;
        if (dist < 26 && dist < bestDist) {
          bestDist = dist;
          bestId = e.id;
        }
      }
    }

    if (bestId != null) {
      setState(() {
        _draggingGliderId = bestId;
        _paintVersion++;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final id = _draggingGliderId;
    if (id == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPos = box.globalToLocal(details.globalPosition);
    final size = box.size;
    final v = _scene.viewport;
    final byId = {for (final e in _scene.elements) e.id: e};

    final glider = byId[id];
    if (glider is! GliderElement) return;
    final target = byId[glider.targetId];
    if (target == null) return;

    final mathPos = GeometryPainter.pixelToMath(localPos, size, v);
    final currentT = _dragOverrides[id] ??
        (glider.isAnimated ? _animController.value : glider.t);
    final newT = GeometryPainter.projectToCurve(mathPos, target, currentT);

    setState(() {
      _dragOverrides[id] = newT;
      _paintVersion++;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final id = _draggingGliderId;
    if (id == null) return;
    final byId = {for (final e in _scene.elements) e.id: e};
    final glider = byId[id];

    setState(() {
      _draggingGliderId = null;
      if (glider is GliderElement && glider.isAnimated) {
        _dragOverrides.remove(id);
      }
      _paintVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        actions: <Widget>[
          IconButton(
            icon: Icon(_animationPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _toggleAnimation,
            tooltip: _animationPaused ? '播放动画' : '暂停动画',
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            child: CustomPaint(
              size: Size.infinite,
              painter: GeometryPainter(
                scene: _scene,
                animation: _animController,
                dragOverrides: _dragOverrides,
                draggingGliderId: _draggingGliderId,
                paintVersion: _paintVersion,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
