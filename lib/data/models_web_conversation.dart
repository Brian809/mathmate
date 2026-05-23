// Web-compatible Conversation and ChatMessageEmbedded models
// Used when compiling to Web (Isar doesn't support Web)

class Conversation {
  int id = 0;
  String title = '';
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  List<ChatMessageEmbedded> messages = [];
}

class ChatMessageEmbedded {
  String role = '';
  String content = '';
  String? reasoning;
  DateTime timestamp = DateTime.now();
}