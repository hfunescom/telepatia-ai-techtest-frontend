import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api/client.dart';

/// Estados simples del provider para manejar el ciclo de llamada.
enum PipelineStatus { idle, loading, success, error }

class PipelineProvider extends ChangeNotifier {
  final ApiClient _api;

  int _correlationCounter = 0;

  PipelineStatus _status = PipelineStatus.idle;
  String? _errorMessage;

  /// Respuesta cruda del backend (la guardamos como Map para mostrarlo fácil en la UI).
  Map<String, dynamic>? _lastResponse;

  PipelineProvider.local() : _api = ApiClient(baseUrl: ApiConfig.baseUrlLocal);

  PipelineProvider.prod(String projectId)
    : _api = ApiClient(
        baseUrl: "https://us-central1-$projectId.cloudfunctions.net",
      );

  PipelineStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get lastResponse => _lastResponse;

  bool get isIdle => _status == PipelineStatus.idle;
  bool get isLoading => _status == PipelineStatus.loading;
  bool get isSuccess => _status == PipelineStatus.success;
  bool get isError => _status == PipelineStatus.error;

  String nextCorrelationId() {
    _correlationCounter++;
    return 'ui-corr-${_correlationCounter.toString().padLeft(3, '0')}';
  }

  /// Llama al pipeline con texto plano.
  Future<void> runFromText({
    required String text,
    String language = "es-AR",
    String? correlationId,
  }) async {
    if (text.trim().isEmpty) {
      _setError("El texto no puede estar vacío.");
      return;
    }
    _setLoading();
    try {
      final res = await _api.pipelineFromText(
        text: text.trim(),
        language: language,
        correlationId: correlationId,
      );
      // Logs útiles en dev:
      // print("API keys -> ${res.keys.toList()}");
      // print("Diagnosis present? ${res['diagnosis'] != null}");
      _setSuccess(res);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Llama al pipeline con audio base64 (UI opcional).
  Future<void> runFromAudioBase64({
    required String base64Audio,
    required String filename,
    String language = "es-AR",
    String? correlationId,
  }) async {
    if (base64Audio.trim().isEmpty) {
      _setError("El audio base64 no puede estar vacío.");
      return;
    }
    if (filename.trim().isEmpty) {
      _setError("El filename no puede estar vacío.");
      return;
    }
    _setLoading();
    try {
      final res = await _api.pipelineFromAudioBase64(
        base64Audio: base64Audio,
        filename: filename,
        language: language,
        correlationId: correlationId,
      );
      _setSuccess(res);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// NUEVO: Llama al pipeline con audio por URL pública (mp3/ogg/wav, etc.)
  Future<void> runFromAudioUrl({
    required String url,
    String? filename,
    String language = "es-AR",
    String? correlationId,
  }) async {
    if (url.trim().isEmpty) {
      _setError("La URL no puede estar vacía.");
      return;
    }
    _setLoading();
    try {
      final res = await _api.pipelineFromAudioUrl(
        url: url.trim(),
        filename: filename,
        language: language,
        correlationId: correlationId,
      );
      _setSuccess(res);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Helper para formatear cualquier Map/JSON bonito en la UI.
  String prettyJson([Object? data]) {
    try {
      if (data == null) return "{}";
      if (data is String) {
        final parsed = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  void _setLoading() {
    _status = PipelineStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setSuccess(Map<String, dynamic> res) {
    _status = PipelineStatus.success;
    _lastResponse = res;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = PipelineStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
