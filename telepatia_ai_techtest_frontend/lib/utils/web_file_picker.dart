// lib/utils/web_file_picker.dart
// File picker exclusive to Flutter Web (uses dart:html).
import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;

/// Result when picking a file
class PickedWebFile {
  final String filename;
  final int sizeBytes;
  final String base64; // ONLY the base64 payload (without "data:...;base64,")

  PickedWebFile({
    required this.filename,
    required this.sizeBytes,
    required this.base64,
  });
}

/// Opens an <input type="file"> and returns the file as Base64 (without prefix).
/// [accept] e.g. "audio/*" or "audio/ogg".
/// [maxBytes] to limit size (default 15 MB).
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

      final name = file.name ?? 'file';
      final size = file.size ?? 0;

      if (size <= 0) {
        completer.completeError(StateError('The file is empty.'));
        return;
      }
      if (size > maxBytes) {
        completer.completeError(
          StateError(
            'The file exceeds the maximum allowed (${_fmtBytes(maxBytes)}). Size: ${_fmtBytes(size)}',
          ),
        );
        return;
      }

      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onError.first.then((_) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Could not read the file.'));
        }
      });

      reader.onLoad.first.then((_) {
        try {
          final result = reader.result?.toString() ?? '';
          if (result.isEmpty || !result.contains(',')) {
            throw StateError('Invalid DataURL format.');
          }
          final base64Payload = result.split(',').last.trim();
          if (base64Payload.isEmpty) {
            throw StateError('Empty base64 payload.');
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
