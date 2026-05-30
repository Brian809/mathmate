import 'package:flutter/material.dart';

import 'geogebra_web_renderer.dart';

/// Web 端场景渲染器 —— 使用 GeoGebra 在线 API 渲染几何场景。
///
/// 此文件仅在 Web 平台编译。通过 iframe 嵌入 GeoGebra 官方应用，
/// 将 AI 生成的 GeometryScene JSON 转换为 GeoGebra 命令执行。
class SceneRenderer extends StatelessWidget {
  final Map<String, dynamic> scene;
  final double height;

  const SceneRenderer({
    super.key,
    required this.scene,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: GeogebraWebRenderer(scene: scene),
      ),
    );
  }
}
