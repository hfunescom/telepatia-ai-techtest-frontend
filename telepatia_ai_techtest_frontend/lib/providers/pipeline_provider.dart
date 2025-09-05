import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api/client.dart';

/// Simple provider states to manage the call lifecycle.
enum PipelineStatus { idle, loading, success, error }

class PipelineProvider extends ChangeNotifier {
  final ApiClient _api;

  int _correlationCounter = 0;

  PipelineStatus _status = PipelineStatus.idle;
  String? _errorMessage;

  Map<String, dynamic>? _lastResponse;

  PipelineProvider.withDefaultApi()
    : _api = ApiClient(baseUrl: ApiConfig.baseUrl);

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

  Future<void> runFromText({
    required String text,
    String language = "es-AR",
    String? correlationId,
  }) async {
    if (text.trim().isEmpty) {
      _setError("Text cannot be empty.");
      return;
    }
    _setLoading();
    try {
      final res = await _api.pipelineFromText(
        text: text.trim(),
        language: language,
        correlationId: correlationId,
      );

      _setSuccess(res);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /* BORRAR
  Future<void> runFromAudioBase64({
    required String base64Audio,
    required String filename,
    String language = "es-AR",
    String? correlationId,
  }) async {
    if (base64Audio.trim().isEmpty) {
      _setError("Base64 audio cannot be empty.");
      return;
    }
    if (filename.trim().isEmpty) {
      _setError("Filename cannot be empty.");
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
*/
  Future<void> runFromAudioUrl({
    required String url,
    String? filename,
    String language = "es-AR",
    String? correlationId,
  }) async {
    if (url.trim().isEmpty) {
      _setError("URL cannot be empty.");
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
