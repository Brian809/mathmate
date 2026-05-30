/// 几何场景渲染器 —— 平台条件导出。
///
/// - **移动端**：使用 [GeometryPainter] + [CustomPaint] Canvas 绘制。
/// - **Web 端**：使用 GeoGebra 在线 API 交互式渲染。
///
/// 两个实现导出相同的 [SceneRenderer] 类，接口一致。
library;

export 'scene_renderer_web.dart'
    if (dart.library.io) 'scene_renderer_mobile.dart';
