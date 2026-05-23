// Web-compatible MathHistory and related models
// Used when compiling to Web (Isar doesn't support Web)

class MathHistory {
  int id = 0;
  DateTime timestamp = DateTime.now();
  String originalImagePath = '';
  String ocrContent = '';
  String solutionMarkdown = '';
  String latexResult = '';
  String title = '';
  GeometrySceneEmbedded? geometryScene;
}

class GeometrySceneEmbedded {
  ViewportEmbedded? viewport;
  List<GeometryElementEmbedded> elements = [];

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
          <String, dynamic>{
            'xMin': -5.0,
            'xMax': 5.0,
            'yMin': -5.0,
            'yMax': 5.0,
          },
      'elements': elements.map((GeometryElementEmbedded e) => e.toMap()).toList(),
    };
  }
}

class ViewportEmbedded {
  double xMin = -5.0;
  double xMax = 5.0;
  double yMin = -5.0;
  double yMax = 5.0;

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

class GeometryElementEmbedded {
  String id = '';
  String type = '';
  String label = '';
  String p1 = '';
  String p2 = '';
  String targetId = '';
  String constraint = '';
  String style = '';
  bool visible = true;
  double initialT = 0.25;
  double radius = 1.0;
  double posX = 0.0;
  double posY = 0.0;
  double centerX = 0.0;
  double centerY = 0.0;
  double offsetX = 0.0;
  double offsetY = 0.0;

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