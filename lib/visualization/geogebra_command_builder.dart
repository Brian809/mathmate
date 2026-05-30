import 'dart:math' as math;

import 'models.dart';
import 'safe_json_parser.dart';

/// 将 [GeometryScene] 转换为 GeoGebra 可执行命令列表。
///
/// 用途：在 Web 端通过 GeoGebra 在线 API（而非 Canvas CustomPainter）
/// 渲染 AI 生成的几何图形。每条命令对应一个 GeoGebra 对象的构造语句。
class GeoGebraCommandBuilder {
  const GeoGebraCommandBuilder();

  /// 从原始 JSON Map 一次性解析并构建命令。
  /// 返回分为三部分：
  /// - [viewportSetup]：视口设置命令（先执行）
  /// - [constructionCommands]：构造命令（按顺序执行）
  /// - [styleCommands]：样式命令（最后执行，避免被覆盖）
  static ({List<String> viewport, List<String> constructions, List<String> styles})
      buildFromMap(Map<String, dynamic> json) {
    final scene = SafeJsonParser.parseSceneFromMap(json);
    return build(scene);
  }

  /// 从已解析的 [GeometryScene] 构建命令。
  static ({List<String> viewport, List<String> constructions, List<String> styles})
      build(GeometryScene scene) {
    final constructions = <String>[];
    final styles = <String>[];
    final nameMap = <String, String>{}; // 原始 id → GeoGebra 对象名

    int pointCount = 0;
    int circleCount = 0;
    int lineCount = 0;
    int curveCount = 0;

    for (final e in scene.elements) {
      final String geoName;
      final String? cmd;

      switch (e) {
        case PointElement():
          pointCount++;
          geoName = _sanitizeId(e.id, 'P$pointCount');
          cmd = _buildPoint(e, geoName);

        case CircleElement():
          circleCount++;
          geoName = _sanitizeId(e.id, 'c$circleCount');
          cmd = _buildCircle(e, geoName);

        case LineElement():
          lineCount++;
          geoName = _sanitizeId(e.id, 'f$lineCount');
          cmd = _buildLine(e, geoName, nameMap);

        case EllipseElement():
          curveCount++;
          geoName = _sanitizeId(e.id, 'cur$curveCount');
          cmd = _buildEllipseCmd(e, geoName);

        case HyperbolaElement():
          curveCount++;
          geoName = _sanitizeId(e.id, 'cur$curveCount');
          cmd = _buildHyperbolaCmd(e, geoName);

        case ParabolaElement():
          curveCount++;
          geoName = _sanitizeId(e.id, 'cur$curveCount');
          cmd = _buildParabolaCmd(e, geoName);

        case GliderElement():
          // glider 的 targetId 引用另一个图元
          final targetName = nameMap[e.targetId] ?? e.targetId;
          geoName = _sanitizeId(e.id, 'G${pointCount + 1}');
          final t = e.t;
          cmd = '$geoName = Point($targetName, $t)';
          pointCount++;

        default:
          continue;
      }

      nameMap[e.id] = geoName;

      if (cmd != null && cmd.isNotEmpty) {
        constructions.add(cmd);
      }

      // 颜色
      if (e.colorArgb != null) {
        final hex = _argbToHex(e.colorArgb!);
        styles.add('SetColor($geoName, "$hex")');
      }

      // 虚线样式
      if (e.style == 'dashed') {
        // GeoGebra line style: 0=solid, 1=dashed, 2=dotted, 3=dash-dot
        styles.add('SetLineStyle($geoName, 1)');
      }

      // 标签
      if (e.label != null && e.label!.isNotEmpty) {
        styles.add('SetCaption($geoName, "${_escapeJs(e.label!)}")');
      }
    }

    // 视口设置
    final v = scene.viewport;
    final viewport = <String>[
      'ZoomIn(${v.xmin}, ${v.ymin}, ${v.xmax}, ${v.ymax})',
    ];

    return (viewport: viewport, constructions: constructions, styles: styles);
  }

  // -------------------- 各图元构造命令 --------------------

  static String? _buildPoint(PointElement e, String name) {
    return '$name = (${_n(e.x)}, ${_n(e.y)})';
  }

  static String? _buildCircle(CircleElement e, String name) {
    return '$name: Circle((${_n(e.cx)}, ${_n(e.cy)}), ${_n(e.radius)})';
  }

  static String? _buildLine(
    LineElement e,
    String name,
    Map<String, String> nameMap,
  ) {
    final p1 = _resolveCoord(e.p1, nameMap);
    final p2 = _resolveCoord(e.p2, nameMap);
    if (p1 == null || p2 == null) return null;
    return '$name: Line($p1, $p2)';
  }

  /// 椭圆：用中心+半径+旋转角度 → 使用 Parametric Curve
  /// GeoGebra ellips 命令为 `Ellipse(焦点1, 焦点2, 椭圆上一点)`，
  /// 此处用 Curve 做参数化绘制更为通用。
  static String? _buildEllipseCmd(EllipseElement e, String name) {
    final cx = _n(e.cx);
    final cy = _n(e.cy);
    final rx = _n(e.rx);
    final ry = _n(e.ry);
    if (e.rotation.abs() < 1e-9) {
      // 无旋转→标准椭圆
      return '$name: Ellipse(($cx, $cy), (${_n(e.cx + e.rx)}, $cy), ($cx, ${_n(e.cy + e.ry)}))';
    }
    // 有旋转→参数曲线
    final cosR = math.cos(e.rotation);
    final sinR = math.sin(e.rotation);
    return '$name = Curve($cx + $rx * cos(t) * $cosR - $ry * sin(t) * $sinR, '
        '$cy + $rx * cos(t) * $sinR + $ry * sin(t) * $cosR, t, 0, 2 * pi)';
  }

  /// 双曲线：参数曲线 (a*cosh(t), b*sinh(t)) 绕中心旋转。
  static String? _buildHyperbolaCmd(HyperbolaElement e, String name) {
    final cosR = math.cos(e.rotation);
    final sinR = math.sin(e.rotation);
    final cx = _n(e.cx);
    final cy = _n(e.cy);
    final a = _n(e.a);
    final b = _n(e.b);

    // 右支
    final rightBranch =
        '$name = Curve($cx + $a * cosh(t) * $cosR - $b * sinh(t) * $sinR, '
        '$cy + $a * cosh(t) * $sinR + $b * sinh(t) * $cosR, t, -5, 5)';

    return rightBranch;
  }

  /// 抛物线：参数曲线 x=p*t², y=2p*t。
  static String? _buildParabolaCmd(ParabolaElement e, String name) {
    double p = e.p;
    double rot = e.rotation;
    if (p < 0) {
      p = -p;
      rot += math.pi;
    }
    if (p < 1e-9) return null;

    final cosR = math.cos(rot);
    final sinR = math.sin(rot);
    final vx = _n(e.vx);
    final vy = _n(e.vy);
    final pp = _n(p);

    return '$name = Curve($vx + $pp * t^2 * $cosR - 2 * $pp * t * $sinR, '
        '$vy + $pp * t^2 * $sinR + 2 * $pp * t * $cosR, t, -5, 5)';
  }

  // -------------------- 工具方法 --------------------

  /// 将端点引用解析为 GeoGebra 坐标字符串。
  /// 可以是字面坐标 `(x, y)` 或另一个 GeoGebra 对象名。
  static String? _resolveCoord(EndpointRef ref, Map<String, String> nameMap) {
    if (ref.isReference) {
      return nameMap[ref.refId] ?? ref.refId;
    }
    if (ref.x != null && ref.y != null) {
      return '(${_n(ref.x!)}, ${_n(ref.y!)})';
    }
    return null;
  }

  /// 清理 id 为合法的 GeoGebra 对象名（字母开头，不含特殊字符）。
  static String _sanitizeId(String rawId, String fallback) {
    final cleaned = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (cleaned.isNotEmpty && RegExp(r'^[a-zA-Z]').hasMatch(cleaned)) {
      return cleaned;
    }
    return fallback;
  }

  /// 数字格式化，去掉多余的小数位。
  static String _n(double v) {
    if (v == v.roundToDouble() && v.isFinite) {
      return v.round().toString();
    }
    return v.toStringAsFixed(6);
  }

  /// ARGB int → #RRGGBB 十六进制字符串。
  static String _argbToHex(int argb) {
    // 去掉 alpha 通道，只保留 RGB
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  /// 转义 JS 字符串中的特殊字符。
  static String _escapeJs(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n');
  }
}
