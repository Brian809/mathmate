import 'package:hive/hive.dart';

part 'hive_models.g.dart';

@HiveType(typeId: 0)
class MathHistory extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late DateTime timestamp;

  @HiveField(2)
  late String originalImagePath;

  @HiveField(3)
  late String ocrContent;

  @HiveField(4)
  late String solutionMarkdown;

  @HiveField(5)
  late String latexResult;

  @HiveField(6)
  late String title;

  @HiveField(7)
  GeometrySceneEmbedded? geometryScene;

  MathHistory();

  MathHistory.create({
    required this.timestamp,
    required this.originalImagePath,
    required this.ocrContent,
    required this.solutionMarkdown,
    required this.latexResult,
    required this.title,
    this.geometryScene,
  });
}

@HiveType(typeId: 1)
class GeometrySceneEmbedded extends HiveObject {
  @HiveField(0)
  ViewportEmbedded? viewport;

  @HiveField(1)
  late List<GeometryElementEmbedded> elements;

  GeometrySceneEmbedded();

  static GeometrySceneEmbedded fromMap(
    Map<String, dynamic> map,
    dynamic parser,
  ) {
    final GeometrySceneEmbedded scene = GeometrySceneEmbedded();
    if (map['viewport'] != null) {
      scene.viewport = ViewportEmbedded.fromMap(
        map['viewport'] as Map<String, dynamic>,
      );
    }
    final List<dynamic> rawElements = map['elements'] as List<dynamic>? ?? [];
    scene.elements = rawElements
        .map((dynamic item) => GeometryElementEmbedded.fromMap(
              item as Map<String, dynamic>,
            ))
        .toList();
    return scene;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'viewport': viewport?.toMap() ??
          <String, dynamic>{'xMin': -5.0, 'xMax': 5.0, 'yMin': -5.0, 'yMax': 5.0},
      'elements': elements.map((GeometryElementEmbedded e) => e.toMap()).toList(),
    };
  }
}

@HiveType(typeId: 2)
class ViewportEmbedded extends HiveObject {
  @HiveField(0)
  late double xMin;

  @HiveField(1)
  late double xMax;

  @HiveField(2)
  late double yMin;

  @HiveField(3)
  late double yMax;

  ViewportEmbedded();

  static ViewportEmbedded fromMap(Map<String, dynamic> map) {
    final ViewportEmbedded viewport = ViewportEmbedded();
    viewport.xMin = (map['xMin'] ?? map['xmin'] ?? -5.0).toDouble();
    viewport.xMax = (map['xMax'] ?? map['xmax'] ?? 5.0).toDouble();
    viewport.yMin = (map['yMin'] ?? map['ymin'] ?? -5.0).toDouble();
    viewport.yMax = (map['yMax'] ?? map['ymax'] ?? 5.0).toDouble();
    return viewport;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'xMin': xMin,
      'xMax': xMax,
      'yMin': yMin,
      'yMax': yMax,
    };
  }
}

@HiveType(typeId: 3)
class GeometryElementEmbedded extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String type;

  @HiveField(2)
  late String label;

  @HiveField(3)
  late String p1;

  @HiveField(4)
  late String p2;

  @HiveField(5)
  late String targetId;

  @HiveField(6)
  late String constraint;

  @HiveField(7)
  late String style;

  @HiveField(8)
  late bool visible;

  @HiveField(9)
  late double initialT;

  @HiveField(10)
  late double radius;

  @HiveField(11)
  late double posX;

  @HiveField(12)
  late double posY;

  @HiveField(13)
  late double centerX;

  @HiveField(14)
  late double centerY;

  @HiveField(15)
  late double offsetX;

  @HiveField(16)
  late double offsetY;

  GeometryElementEmbedded();

  static GeometryElementEmbedded fromMap(Map<String, dynamic> map) {
    final GeometryElementEmbedded element = GeometryElementEmbedded();
    element.id = map['id'] as String? ?? '';
    element.type = map['type'] as String? ?? '';
    element.label = map['label'] as String? ?? '';
    element.p1 = map['p1'] as String? ?? '';
    element.p2 = map['p2'] as String? ?? '';
    element.targetId = map['targetId'] as String? ?? map['targetid'] as String? ?? '';
    element.constraint = map['constraint'] as String? ?? '';
    element.style = map['style'] as String? ?? '';
    element.visible = map['visible'] as bool? ?? true;
    element.initialT = (map['initialT'] ?? map['initialt'] ?? 0.25).toDouble();
    element.radius = (map['radius'] ?? 1.0).toDouble();
    element.posX = (map['posX'] ?? 0.0).toDouble();
    element.posY = (map['posY'] ?? 0.0).toDouble();
    element.centerX = (map['centerX'] ?? 0.0).toDouble();
    element.centerY = (map['centerY'] ?? 0.0).toDouble();
    element.offsetX = (map['offsetX'] ?? 0.0).toDouble();
    element.offsetY = (map['offsetY'] ?? 0.0).toDouble();
    return element;
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'id': id,
      'type': type,
      'visible': visible,
    };
    if (label.isNotEmpty) map['label'] = label;
    if (p1.isNotEmpty) map['p1'] = p1;
    if (p2.isNotEmpty) map['p2'] = p2;
    if (targetId.isNotEmpty) map['targetId'] = targetId;
    if (constraint.isNotEmpty) map['constraint'] = constraint;
    if (style.isNotEmpty) map['style'] = style;
    if (type == 'point' || type == 'dynamic_point') {
      map['pos'] = <double>[posX, posY];
    }
    if (type == 'circle') {
      map['center'] = <double>[centerX, centerY];
      map['radius'] = radius;
    }
    if (type == 'dynamic_point') {
      map['initialT'] = initialT;
      map['offset'] = <double>[offsetX, offsetY];
    }
    return map;
  }
}