import 'package:image_picker/image_picker.dart';
import 'package:mathmate/models/pipeline_models.dart';
import 'package:mathmate/models/pipeline_stage.dart';
import 'package:mathmate/services/app_logger.dart';
import 'package:mathmate/services/ocr_service.dart';
import 'package:mathmate/services/solver_service.dart';
import 'package:mathmate/services/visualization_service.dart';

class MathPipelineService {
  final OcrService _ocrService;
  final SolverService _solverService;
  final VisualizationService _visualizationService;

  MathPipelineService({
    OcrService? ocrService,
    SolverService? solverService,
    VisualizationService? visualizationService,
  }) : _ocrService = ocrService ?? OcrService(),
       _solverService = solverService ?? SolverService(),
       _visualizationService = visualizationService ?? VisualizationService();

  Future<PipelineResult> runFromImage(
    XFile image, {
    void Function(PipelineStage stage)? onStageChanged,
  }) async {
    final List<String> stageErrors = <String>[];
    RecognizeResult? recognize;
    SolveResult? solve;
    VisualizeResult? visualize;

    try {
      onStageChanged?.call(PipelineStage.recognizing);
      AppLogger.instance.info('[Pipeline] ========== 阶段1: OCR识别 开始 ==========');
      recognize = await _ocrService.recognizeQuestionFromImage(image);
      AppLogger.instance.info('[Pipeline] 识别完成: questionMarkdown=${recognize.questionMarkdown.length} 字符, rawOutput=${recognize.rawOutput.length} 字符');
    } catch (e, stack) {
      AppLogger.instance.error('[Pipeline] 识别阶段失败: $e');
      AppLogger.instance.error('[Pipeline] 堆栈: $stack');
      stageErrors.add('识别阶段失败: $e');
      onStageChanged?.call(PipelineStage.failed);
      return PipelineResult(
        recognize: null,
        solve: null,
        visualize: null,
        stageErrors: stageErrors,
      );
    }

    try {
      onStageChanged?.call(PipelineStage.solving);
      AppLogger.instance.info('[Pipeline] ========== 阶段2: 解题 开始 ==========');
      AppLogger.instance.info('[Pipeline] 输入 questionMarkdown 长度: ${recognize.questionMarkdown.length} 字符');
      solve = await _solverService.solveQuestionMarkdown(
        recognize.questionMarkdown,
      );
      AppLogger.instance.info('[Pipeline] 解题完成: solutionMarkdown=${solve.solutionMarkdown.length} 字符, rawOutput=${solve.rawOutput.length} 字符');
    } catch (e, stack) {
      AppLogger.instance.error('[Pipeline] 解题阶段失败: $e');
      AppLogger.instance.error('[Pipeline] 堆栈: $stack');
      stageErrors.add('解题阶段失败: $e');
      onStageChanged?.call(PipelineStage.failed);
      return PipelineResult(
        recognize: recognize,
        solve: null,
        visualize: null,
        stageErrors: stageErrors,
      );
    }

    try {
      onStageChanged?.call(PipelineStage.visualizing);
      AppLogger.instance.info('[Pipeline] ========== 阶段3: 可视化 开始 ==========');
      visualize = await _visualizationService.buildGeometryScene(
        questionMarkdown: recognize.questionMarkdown,
        solutionMarkdown: solve.solutionMarkdown,
      );
      if (visualize.error != null) {
        AppLogger.instance.warn('[Pipeline] 可视化提示: ${visualize.error}');
        stageErrors.add('可视化阶段提示: ${visualize.error}');
      }
      AppLogger.instance.info('[Pipeline] 可视化完成: scene=${visualize.scene != null ? "有" : "无"}');
    } catch (e, stack) {
      AppLogger.instance.error('[Pipeline] 可视化阶段异常: $e');
      AppLogger.instance.error('[Pipeline] 堆栈: $stack');
      stageErrors.add('可视化阶段失败: $e');
    }

    onStageChanged?.call(PipelineStage.completed);
    AppLogger.instance.info('[Pipeline] ========== 全部阶段完成 ==========');
    AppLogger.instance.info('[Pipeline] 阶段错误数: ${stageErrors.length}');
    for (int i = 0; i < stageErrors.length; i++) {
      AppLogger.instance.error('[Pipeline] 错误${i + 1}: ${stageErrors[i]}');
    }
    return PipelineResult(
      recognize: recognize,
      solve: solve,
      visualize: visualize,
      stageErrors: stageErrors,
    );
  }
}
