import 'package:flutter/material.dart';

import 'geometry_painter.dart';
import 'safe_json_parser.dart';

/// 移动端场景渲染器 —— 使用 Canvas [GeometryPainter] 绘制几何场景。
///
/// 此文件仅在原生平台（Android/iOS/macOS/Windows/Linux）编译。
class SceneRenderer extends StatelessWidget {
  final Map<String, dynamic> scene;
  final double height;

  const SceneRenderer({
    super.key,
    required this.scene,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: GeometryPainter(
            scene: SafeJsonParser.parseSceneFromMap(scene),
          ),
        ),
      ),
    );
  }
}
