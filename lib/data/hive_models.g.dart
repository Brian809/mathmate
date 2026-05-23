// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MathHistoryAdapter extends TypeAdapter<MathHistory> {
  @override
  final int typeId = 0;

  @override
  MathHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MathHistory()
      ..id = fields[0] as int
      ..timestamp = fields[1] as DateTime
      ..originalImagePath = fields[2] as String
      ..ocrContent = fields[3] as String
      ..solutionMarkdown = fields[4] as String
      ..latexResult = fields[5] as String
      ..title = fields[6] as String
      ..geometryScene = fields[7] as GeometrySceneEmbedded?;
  }

  @override
  void write(BinaryWriter writer, MathHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.originalImagePath)
      ..writeByte(3)
      ..write(obj.ocrContent)
      ..writeByte(4)
      ..write(obj.solutionMarkdown)
      ..writeByte(5)
      ..write(obj.latexResult)
      ..writeByte(6)
      ..write(obj.title)
      ..writeByte(7)
      ..write(obj.geometryScene);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MathHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GeometrySceneEmbeddedAdapter extends TypeAdapter<GeometrySceneEmbedded> {
  @override
  final int typeId = 1;

  @override
  GeometrySceneEmbedded read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeometrySceneEmbedded()
      ..viewport = fields[0] as ViewportEmbedded?
      ..elements = (fields[1] as List).cast<GeometryElementEmbedded>();
  }

  @override
  void write(BinaryWriter writer, GeometrySceneEmbedded obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.viewport)
      ..writeByte(1)
      ..write(obj.elements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeometrySceneEmbeddedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ViewportEmbeddedAdapter extends TypeAdapter<ViewportEmbedded> {
  @override
  final int typeId = 2;

  @override
  ViewportEmbedded read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ViewportEmbedded()
      ..xMin = fields[0] as double
      ..xMax = fields[1] as double
      ..yMin = fields[2] as double
      ..yMax = fields[3] as double;
  }

  @override
  void write(BinaryWriter writer, ViewportEmbedded obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.xMin)
      ..writeByte(1)
      ..write(obj.xMax)
      ..writeByte(2)
      ..write(obj.yMin)
      ..writeByte(3)
      ..write(obj.yMax);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewportEmbeddedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GeometryElementEmbeddedAdapter
    extends TypeAdapter<GeometryElementEmbedded> {
  @override
  final int typeId = 3;

  @override
  GeometryElementEmbedded read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeometryElementEmbedded()
      ..id = fields[0] as String
      ..type = fields[1] as String
      ..label = fields[2] as String
      ..p1 = fields[3] as String
      ..p2 = fields[4] as String
      ..targetId = fields[5] as String
      ..constraint = fields[6] as String
      ..style = fields[7] as String
      ..visible = fields[8] as bool
      ..initialT = fields[9] as double
      ..radius = fields[10] as double
      ..posX = fields[11] as double
      ..posY = fields[12] as double
      ..centerX = fields[13] as double
      ..centerY = fields[14] as double
      ..offsetX = fields[15] as double
      ..offsetY = fields[16] as double;
  }

  @override
  void write(BinaryWriter writer, GeometryElementEmbedded obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.label)
      ..writeByte(3)
      ..write(obj.p1)
      ..writeByte(4)
      ..write(obj.p2)
      ..writeByte(5)
      ..write(obj.targetId)
      ..writeByte(6)
      ..write(obj.constraint)
      ..writeByte(7)
      ..write(obj.style)
      ..writeByte(8)
      ..write(obj.visible)
      ..writeByte(9)
      ..write(obj.initialT)
      ..writeByte(10)
      ..write(obj.radius)
      ..writeByte(11)
      ..write(obj.posX)
      ..writeByte(12)
      ..write(obj.posY)
      ..writeByte(13)
      ..write(obj.centerX)
      ..writeByte(14)
      ..write(obj.centerY)
      ..writeByte(15)
      ..write(obj.offsetX)
      ..writeByte(16)
      ..write(obj.offsetY);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeometryElementEmbeddedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
