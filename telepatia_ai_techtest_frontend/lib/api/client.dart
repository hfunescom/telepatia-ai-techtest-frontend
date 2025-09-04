import 'dart:convert';
import 'package:http/http.dart' as http;

/// Configuration for backend endpoints (Firebase Functions v2).
class ApiConfig {
  /// Local base URL for the emulator (adjust to match your backend).
  static const String baseUrlLocal =
      "http://127.0.0.1:5005/telepatia-ai-techtest-hfunes/us-central1";

  /// Production base URL (replace <your-project> with your GCP projectId).
  static const String baseUrlProd =
      "https://us-central1-<your-project>.cloudfunctions.net";
}

/// Simple HTTP client to communicate with the backend pipeline.
class ApiClient {
  final String baseUrl;
  final http.Client _http;

  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  /// Calls the pipeline with plain text.
  ///
  /// POST {baseUrl}/pipeline
  /// body:
  /// {
  ///   "input": {
  ///     "text": "<text>",
  ///     "language": "es-AR",
  ///     "correlationId": "optional"
  ///   }
  /// }
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
        message:
            "Error ${res.statusCode} calling pipelineFromText: ${res.body}",
        statusCode: res.statusCode,
        body: res.body,
      );
    }

    return _decodeJson(res.body);
  }

  /// Calls the pipeline with audio encoded in Base64.
  ///
  /// POST {baseUrl}/pipeline
  /// body:
  /// {
  ///   "input": {
  ///     "audio": {"type": "base64", "value": "<B64>"},
  ///     "filename": "file.ogg",
  ///     "language": "es-AR",
  ///     "correlationId": "optional"
  ///   }
  /// }
  Future<Map<String, dynamic>> pipelineFromAudioBase64({
    required String base64Audio,
    required String filename,
    String language = "es-AR",
    String? correlationId,
  }) async {
    final uri = Uri.parse("$baseUrl/pipeline");
    final payload = <String, dynamic>{
      "input": {
        "audio": {"type": "base64", "value": base64Audio},
        "filename": filename,
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
        message:
            "Error ${res.statusCode} calling pipelineFromAudioBase64: ${res.body}",
        statusCode: res.statusCode,
        body: res.body,
      );
    }

    return _decodeJson(res.body);
  }

  /// NEW: Calls the pipeline with audio via public URL (mp3/ogg/wav, etc.)
  ///
  /// POST {baseUrl}/pipeline
  /// body:
  /// {
  ///   "input": {
  ///     "audio": {"type": "url", "value": "<URL>"},
  ///     "filename": "optional",
  ///     "language": "es-AR",
  ///     "correlationId": "optional"
  ///   }
  /// }
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
        message:
            "Error ${res.statusCode} calling pipelineFromAudioUrl: ${res.body}",
        statusCode: res.statusCode,
        body: res.body,
      );
    }

    return _decodeJson(res.body);
  }

  /// Closes the HTTP client (use this if you create/discard instances dynamically).
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

/// Simple exception for API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException({required this.message, this.statusCode, this.body});

  @override
  String toString() =>
      "ApiException(statusCode=$statusCode, message=$message, body=$body)";
}
