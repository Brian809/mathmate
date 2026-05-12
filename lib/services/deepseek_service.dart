import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const String _apiKeyEnv = 'DEEPSEEK_API_KEY';
  static const String _modelIdEnv = 'DEEPSEEK_MODEL_ID';
  static const String _baseUrlEnv = 'DEEPSEEK_BASE_URL';
  static const String _defaultBaseUrl = 'https://api.deepseek.com/chat/completions';

  static bool _dotenvLoaded = false;

  Future<void> _ensureEnvLoaded() async {
    if (_dotenvLoaded) return;
    await dotenv.load(fileName: '.env');
    _dotenvLoaded = true;
  }

  Future<String> callTextPrompt({
    required String prompt,
    required String userText,
  }) async {
    await _ensureEnvLoaded();

    final String apiKey = (dotenv.env[_apiKeyEnv] ?? '').trim();
    final String modelId = (dotenv.env[_modelIdEnv] ?? '').trim();
    final String baseUrl = (dotenv.env[_baseUrlEnv] ?? _defaultBaseUrl).trim();

    if (apiKey.isEmpty) {
      throw Exception('Missing env config: DEEPSEEK_API_KEY');
    }
    if (modelId.isEmpty) {
      throw Exception('Missing env config: DEEPSEEK_MODEL_ID');
    }

    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final List<Map<String, String>> messages = <Map<String, String>>[
      <String, String>{'role': 'system', 'content': prompt},
      <String, String>{'role': 'user', 'content': userText},
    ];

    final http.Response response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(<String, dynamic>{
        'model': modelId,
        'messages': messages,
      }),
    ).timeout(const Duration(seconds: 60), onTimeout: () {
      throw Exception('DeepSeek API 请求超时（60秒）');
    });

    if (response.statusCode != 200) {
      final String detail = utf8.decode(response.bodyBytes);
      debugPrint('DeepSeek API error: $detail');
      throw Exception('DeepSeek API error: $detail');
    }

    final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
    final String parsed = _extractContentFromResponse(data).trim();
    if (parsed.isEmpty) {
      throw Exception('DeepSeek API returned empty content.');
    }
    return parsed;
  }

  String _extractContentFromResponse(dynamic data) {
    final dynamic chatContent = data['choices']?[0]?['message']?['content'];
    if (chatContent is String && chatContent.trim().isNotEmpty) {
      return chatContent.trim();
    }
    return '';
  }
}
