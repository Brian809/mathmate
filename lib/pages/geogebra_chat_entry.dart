/// GeoGebra 聊天页面 —— 平台条件导出。
library;

export 'geogebra_chat_page.dart'
    if (dart.library.io) 'geogebra_chat_mobile.dart';
