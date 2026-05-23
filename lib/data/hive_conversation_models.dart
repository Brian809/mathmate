import 'package:hive/hive.dart';

part 'hive_conversation_models.g.dart';

@HiveType(typeId: 4)
class Conversation extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3)
  late DateTime updatedAt;

  @HiveField(4)
  late List<ChatMessageEmbedded> messages;

  Conversation();

  Conversation.create({
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    List<ChatMessageEmbedded>? messages,
  }) : messages = messages ?? [];
}

@HiveType(typeId: 5)
class ChatMessageEmbedded extends HiveObject {
  @HiveField(0)
  late String role;

  @HiveField(1)
  late String content;

  @HiveField(2)
  String? reasoning;

  @HiveField(3)
  late DateTime timestamp;

  ChatMessageEmbedded();
}