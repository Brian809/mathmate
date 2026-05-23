// Conditional exports for platform-specific repository implementations
// Web uses web_repository.dart (SharedPreferences), Native uses history_repository.dart (Isar)

export 'web_repository.dart' if (dart.library.html) 'history_repository.dart';
export 'web_conversation_repository.dart' if (dart.library.html) 'conversation_repository.dart';