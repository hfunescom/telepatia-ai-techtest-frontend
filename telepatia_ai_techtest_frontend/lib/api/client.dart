import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const String apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5005/telepatia-ai-techtest-hfunes',
  );
  static const String region = String.fromEnvironment(
    'FIREBASE_DEFAULT_REGION',
    defaultValue: 'us-central1',
  );

  static const String baseUrl = '$apiBase/$region';
}

class ApiClient {
  final String baseUrl;
  final http.Client _http;

  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  Future<Map<String, dynamic>> pipelineFromText({
    required String text,
    String language = "es-AR",
    String? correlationId,
  }) async {
    final uri = Uri.parse("$baseUrl/pipeline");
    final payload = <String, dynamic>{
      "input": {
        "text": text,
        "language": language,
        if (correlationId != null) "correlationId": correlationId,
      },
    };

    final res = await _http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        message: "Error ${res.statusCode} calling text pipeline: ${res.body}",
        statusCode: res.statusCode,
        body: res.body,
      );
    }

    return _decodeJson(res.body);
  }

  Future<Map<String, dynamic>> pipelineFromAudioUrl({
    required String url,
    String? filename,
    String language = "es-AR",
    String? correlationId,
  }) async {
    final uri = Uri.parse("$baseUrl/pipeline");
    final payload = <String, dynamic>{
      "input": {
        "audio": {"type": "url", "value": url},
        if (filename != null) "filename": filename,
        "language": language,
        if (correlationId != null) "correlationId": correlationId,
      },
    };

    final res = await _http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        message: "Error ${res.statusCode} calling audio pipeline: ${res.body}",
        statusCode: res.statusCode,
        body: res.body,
      );
    }

    return _decodeJson(res.body);
  }

  void dispose() {
    _http.close();
  }

  Map<String, dynamic> _decodeJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException(
      message: "Unexpected server response (not a JSON object).",
      statusCode: 200,
      body: body,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException({required this.message, this.statusCode, this.body});

  @override
  String toString() =>
      "ApiException(statusCode=$statusCode, message=$message, body=$body)";
}
