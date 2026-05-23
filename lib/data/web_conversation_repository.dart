import 'package:mathmate/data/models_web_conversation.dart';

class ConversationRepository {
  ConversationRepository._();
  static final ConversationRepository instance = ConversationRepository._();

  bool get isReady => true;

  Future<void> init() async {}

  Future<Conversation> createConversation(String title) async {
    return Conversation()
      ..id = 0
      ..title = title
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }

  Future<void> addMessage(int conversationId, ChatMessageEmbedded message) async {}

  Future<void> updateTitle(int conversationId, String title) async {}

  Stream<List<Conversation>> watchConversations() async* {
    yield [];
  }

  Future<Conversation?> getConversation(int id) async => null;

  Future<void> replaceMessages(int conversationId, List<ChatMessageEmbedded> messages) async {}

  Future<void> deleteConversation(int id) async {}
}