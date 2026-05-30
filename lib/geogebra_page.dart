/// GeoGebra 页面 —— 平台条件导出。
///
/// - **移动端 (Android/iOS)**：使用 WebView 加载本地 GeoGebra HTML 文件。
/// - **Web 端**：通过 iframe 嵌入 GeoGebra 官方在线应用。
///
/// 两个实现导出相同的 [GeogebraPage] 类，接口完全一致，调用方无需
/// 感知平台差异。
library;

export 'geogebra_page_web.dart'
    if (dart.library.io) 'geogebra_page_mobile.dart';
