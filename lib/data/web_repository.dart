import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathmate/data/models_web.dart';

class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  bool get isReady => true;

  Future<void> init() async {}

  Future<void> saveHistory({
    required dynamic sourceImage,
    required String ocrContent,
    required String solutionMarkdown,
    required String latexResult,
    Map<String, dynamic>? sceneMap,
  }) async {}

  Stream<List<MathHistory>> watchHistories() async* {
    yield [];
  }

  Future<void> deleteHistory(int id) async {}

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_first_launch') ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);
  }

  Future<int?> getGradeLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('grade_level');
  }

  Future<void> setGradeLevel(int grade) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grade_level', grade);
  }

  Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_completed') ?? false;
  }

  Future<void> setTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }
}