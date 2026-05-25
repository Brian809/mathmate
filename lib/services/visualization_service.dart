import 'dart:convert';

import 'package:mathmate/models/pipeline_models.dart';
import 'package:mathmate/services/app_logger.dart';
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
    AppLogger.instance.info('[Visualization] 开始，userText 总长度: ${userText.length} 字符');

    final String raw = await _client.callTextPrompt(
      prompt: visualizationPrompt,
      userText: userText,
    );

    final String? geometryText = ResponseExtractor.extractGeometryJsonText(raw);
    AppLogger.instance.info('[Visualization] json 提取结果: ${geometryText != null ? "成功(${geometryText.length}字符)" : "失败(未检测到geometryjson块)"}');
    if (geometryText == null || geometryText.isEmpty) {
      AppLogger.instance.warn('[Visualization] 未检测到 geometryjson，原始输出预览(前500字): ${raw.substring(0, raw.length > 500 ? 500 : raw.length)}...');
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
      AppLogger.instance.warn('[Visualization] 首次解析失败: ${firstResult.error}，开始重试...');
      final String retryRaw = await _client.callTextPrompt(
        prompt: visualizationPrompt,
        userText:
            '$userText\n\n上一轮输出格式有误: ${firstResult.error}。请严格按照格式重新输出。',
      );

      final String? retryGeometryText =
          ResponseExtractor.extractGeometryJsonText(retryRaw);
      AppLogger.instance.info('[Visualization] 重试json提取: ${retryGeometryText != null ? "成功(${retryGeometryText.length}字符)" : "失败"}');
      if (retryGeometryText != null && retryGeometryText.isNotEmpty) {
        final VisualizeResult retryResult = parseGeometry(retryGeometryText, retryRaw);
        AppLogger.instance.info('[Visualization] 重试结果: ${retryResult.error ?? "成功"}');
        return retryResult;
      }
      AppLogger.instance.warn('[Visualization] 重试也失败了，返回首次结果');
    }

    return firstResult;
  }
}
