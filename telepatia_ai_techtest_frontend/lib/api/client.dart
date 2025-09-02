import 'dart:convert';
import 'package:http/http.dart' as http;

/// Configuración de endpoints del backend (Firebase Functions v2).
class ApiConfig {
  /// URL base local del emulador (ajustada a lo que usaste en backend).
  static const String baseUrlLocal =
      "http://127.0.0.1:5005/telepatia-ai-techtest-hfunes/us-central1";

  /// URL base en producción (reemplaza <tu-proyecto> por tu GCP projectId).
  static const String baseUrlProd =
      "https://us-central1-<tu-proyecto>.cloudfunctions.net";
}

/// Cliente HTTP simple para hablar con el pipeline del backend.
class ApiClient {
  final String baseUrl;
  final http.Client _http;

  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  /// Llama al pipeline con texto plano.
  ///
  /// Contrato esperado (según lo que definimos en backend):
  /// POST {baseUrl}/pipeline
  /// body:
  /// {
  ///   "input": {
  ///     "text": {"type": "plain", "value": "<texto>"},
  ///     "language": "es-AR",
  ///     "correlationId": "opcional"
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
        "text": {"type": "plain", "value": text},
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
            "Error ${res.statusCode} al llamar pipelineFromText: ${res.body}",
        statusCode: res.statusCode,
        body: res.body,
      );
    }

    return _decodeJson(res.body);
  }

  /// Llama al pipeline con audio codificado en Base64.
  ///
  /// Ejemplo de body que ya probaste desde curl:
  /// {
  ///   "input": {
  ///     "audio": {"type": "base64", "value": "<B64>"},
  ///     "filename": "archivo.ogg",
  ///     "language": "es-AR",
  ///     "correlationId": "opcional"
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
            "Error ${res.statusCode} al llamar pipelineFromAudioBase64: ${res.body}",
        statusCode: res.statusCode,
        body: res.body,
      );
    }

    return _decodeJson(res.body);
  }

  /// Cierra el cliente HTTP (usá esto si creás/descartás instancias dinámicamente).
  void dispose() {
    _http.close();
  }

  Map<String, dynamic> _decodeJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException(
      message: "Respuesta inesperada del servidor (no es JSON objeto).",
      statusCode: 200,
      body: body,
    );
  }
}

/// Excepción simple para errores de API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException({required this.message, this.statusCode, this.body});

  @override
  String toString() =>
      "ApiException(statusCode=$statusCode, message=$message, body=$body)";
}
