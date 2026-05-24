import 'package:image_picker/image_picker.dart';
import 'package:mathmate/models/pipeline_models.dart';
import 'package:mathmate/services/app_logger.dart';
import 'package:mathmate/services/prompts/ocr_prompt.dart';
import 'package:mathmate/services/volc_ai_client_service.dart';

class OcrService {
  static const String _ocrModelEnv = 'VOLC_OCR_MODEL_ID';

  final VolcAiClientService _client;

  OcrService({VolcAiClientService? client})
    : _client = client ?? VolcAiClientService();

  Future<RecognizeResult> recognizeQuestionFromImage(XFile image) async {
    AppLogger.instance.info('[OCR] 开始识别，图片路径: ${image.path}');
    final Stopwatch sw = Stopwatch()..start();

    final String raw = await _client.callVisionPrompt(
      imageFile: image,
      prompt: ocrPrompt,
      modelEnv: _ocrModelEnv,
    );

    sw.stop();
    final String trimmed = raw.trim();
    AppLogger.instance.info('[OCR] 耗时 ${sw.elapsedMilliseconds}ms，返回 ${raw.length} 字符（trim后 ${trimmed.length} 字符）');
    if (trimmed.length <= 500) {
      AppLogger.instance.info('[OCR] 原始输出: $trimmed');
    } else {
      AppLogger.instance.info('[OCR] 输出预览(前500字): ${trimmed.substring(0, 500)}...');
    }

    if (trimmed.isEmpty) {
      AppLogger.instance.warn('[OCR] API 返回空内容，原始响应长度=${raw.length}，原始内容="$raw"');
      throw Exception('OCR 识别结果为空，请检查图片是否清晰或重试');
    }

    return RecognizeResult(
      questionMarkdown: trimmed,
      rawOutput: raw,
    );
  }
}
