/// B站视频播放页 —— 平台条件导出。
///
/// - **移动端**：WebView 内嵌播放器
/// - **Web 端**：iframe 嵌入 B站播放器
library;

export 'video_player_page_web.dart'
    if (dart.library.io) 'video_player_page_mobile.dart';
