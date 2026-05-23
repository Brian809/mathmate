// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_conversation_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationAdapter extends TypeAdapter<Conversation> {
  @override
  final int typeId = 4;

  @override
  Conversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Conversation()
      ..id = fields[0] as int
      ..title = fields[1] as String
      ..createdAt = fields[2] as DateTime
      ..updatedAt = fields[3] as DateTime
      ..messages = (fields[4] as List).cast<ChatMessageEmbedded>();
  }

  @override
  void write(BinaryWriter writer, Conversation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.messages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMessageEmbeddedAdapter extends TypeAdapter<ChatMessageEmbedded> {
  @override
  final int typeId = 5;

  @override
  ChatMessageEmbedded read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessageEmbedded()
      ..role = fields[0] as String
      ..content = fields[1] as String
      ..reasoning = fields[2] as String?
      ..timestamp = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, ChatMessageEmbedded obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.role)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.reasoning)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageEmbeddedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
