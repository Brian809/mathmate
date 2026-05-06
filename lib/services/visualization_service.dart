import 'dart:convert';

import 'package:mathmate/models/pipeline_models.dart';
import 'package:mathmate/services/deepseek_service.dart';
import 'package:mathmate/services/prompts/visualization_prompt.dart';
import 'package:mathmate/visualization/geometry_validator.dart';
import 'package:mathmate/visualization/response_extractor.dart';

class VisualizationService {
  final DeepSeekService _client;

  VisualizationService({DeepSeekService? client})
    : _client = client ?? DeepSeekService();

  Future<VisualizeResult> buildGeometryScene({
    required String questionMarkdown,
    required String solutionMarkdown,
  }) async {
    final String userText =
        '题目(Markdown):\n$questionMarkdown\n\n解答(Markdown):\n$solutionMarkdown';

    final String raw = await _client.callTextPrompt(
      prompt: visualizationPrompt,
      userText: userText,
    );

    final String? geometryText = ResponseExtractor.extractGeometryJsonText(raw);
    if (geometryText == null || geometryText.isEmpty) {
      return VisualizeResult(
        scene: null,
        rawOutput: raw,
        error: '未检测到 geometryjson 输出。',
      );
    }

    VisualizeResult parseGeometry(String geometryText, String raw) {
      try {
        final dynamic decoded = jsonDecode(geometryText);
        if (decoded is! Map<String, dynamic>) {
          return VisualizeResult(
            scene: null,
            rawOutput: raw,
            error: 'geometryjson 根节点必须是对象。',
          );
        }
        final GeometryValidationResult validation =
            const GeometryValidator().validate(decoded);
        if (!validation.isValid) {
          return VisualizeResult(
            scene: null,
            rawOutput: raw,
            error: validation.error ?? 'geometryjson 校验失败。',
          );
        }
        return VisualizeResult(
          scene: decoded, // 存储原始 Map，渲染时再解析为 GeometryScene
          rawOutput: raw,
        );
      } catch (e) {
        return VisualizeResult(
          scene: null,
          rawOutput: raw,
          error: 'geometryjson 解析失败: $e',
        );
      }
    }

    VisualizeResult firstResult = parseGeometry(geometryText, raw);

    // 解析失败时重试一次
    if (firstResult.error != null) {
      final String retryRaw = await _client.callTextPrompt(
        prompt: visualizationPrompt,
        userText:
            '$userText\n\n上一轮输出格式有误: ${firstResult.error}。请严格按照格式重新输出。',
      );

      final String? retryGeometryText =
          ResponseExtractor.extractGeometryJsonText(retryRaw);
      if (retryGeometryText != null && retryGeometryText.isNotEmpty) {
        return parseGeometry(retryGeometryText, retryRaw);
      }
    }

    return firstResult;
  }
}
