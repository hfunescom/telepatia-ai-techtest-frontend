// lib/utils/web_file_picker.dart
// File picker exclusivo para Flutter Web (usa dart:html).
import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;

/// Resultado al elegir un archivo
class PickedWebFile {
  final String filename;
  final int sizeBytes;
  final String base64; // SOLO el payload base64 (sin "data:...;base64,")

  PickedWebFile({
    required this.filename,
    required this.sizeBytes,
    required this.base64,
  });
}

/// Lanza un <input type="file"> y devuelve el archivo como Base64 (sin prefijo).
/// [accept] por ejemplo: "audio/*" o "audio/ogg".
/// [maxBytes] para limitar tamaño (por defecto 15 MB).
Future<PickedWebFile?> pickSingleFileAsBase64({
  String accept = '*/*',
  int maxBytes = 15 * 1024 * 1024,
}) async {
  final completer = Completer<PickedWebFile?>();
  try {
    final input =
        html.FileUploadInputElement()
          ..accept = accept
          ..multiple = false;

    input.click();

    input.onChange.first.then((_) async {
      if (input.files == null || input.files!.isEmpty) {
        completer.complete(null);
        return;
      }
      final file = input.files!.first;

      final name = file.name ?? 'archivo';
      final size = file.size ?? 0;

      if (size <= 0) {
        completer.completeError(StateError('El archivo está vacío.'));
        return;
      }
      if (size > maxBytes) {
        completer.completeError(
          StateError(
            'El archivo supera el máximo permitido (${_fmtBytes(maxBytes)}). Tamaño: ${_fmtBytes(size)}',
          ),
        );
        return;
      }

      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onError.first.then((_) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('No se pudo leer el archivo.'));
        }
      });

      reader.onLoad.first.then((_) {
        try {
          final result = reader.result?.toString() ?? '';
          if (result.isEmpty || !result.contains(',')) {
            throw StateError('Formato de DataURL inválido.');
          }
          final base64Payload = result.split(',').last.trim();
          if (base64Payload.isEmpty) {
            throw StateError('Payload base64 vacío.');
          }
          completer.complete(
            PickedWebFile(
              filename: name,
              sizeBytes: size,
              base64: base64Payload,
            ),
          );
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      });
    });
  } catch (e) {
    if (!completer.isCompleted) completer.completeError(e);
  }
  return completer.future;
}

String _fmtBytes(int bytes, [int decimals = 1]) {
  if (bytes <= 0) return "0 B";
  const k = 1024;
  const sizes = ["B", "KB", "MB", "GB", "TB"];
  final i = (math.log(bytes) / math.log(k)).floor();
  final p = bytes / math.pow(k, i);
  return "${p.toStringAsFixed(decimals)} ${sizes[i]}";
}
