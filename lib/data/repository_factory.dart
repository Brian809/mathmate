// Conditional exports for platform-specific implementations
// Web uses models_web.dart (without Isar), Native uses history_models.dart (with Isar)

export 'models_web.dart' if (dart.library.html) 'history_models.dart';
export 'models_web_conversation.dart' if (dart.library.html) 'conversation_models.dart';