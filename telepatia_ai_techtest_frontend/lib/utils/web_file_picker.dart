// lib/utils/web_file_picker.dart
//
// Utilidad solo para Flutter Web.
// Abre el selector de archivos del navegador, lee el archivo como bytes
// y devuelve su contenido en Base64 junto con metadata.
//
// Nota: Esto compila en Web. Si querés compatibilidad móvil/escritorio,
// se puede agregar el package file_picker y un branch por plataforma.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PickedWebFile {
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final String base64; // contenido del archivo en Base64, sin encabezados

  PickedWebFile({
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    required this.base64,
  });
}

/// Abre un selector de archivo (único) y devuelve el archivo leído en Base64.
/// [accept] es un string con el filtro MIME, por ejemplo: "audio/*".
Future<PickedWebFile?> pickSingleFileAsBase64({
  String accept = "audio/*",
}) async {
  final input =
      html.FileUploadInputElement()
        ..accept = accept
        ..multiple = false;

  // Dispara el diálogo
  input.click();

  // Esperamos a que el usuario seleccione algo o cancele
  await input.onChange.first;

  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) {
    return null; // usuario canceló
  }

  final reader = html.FileReader();
  final completer = Completer<PickedWebFile?>();

  reader.onError.first.then((_) {
    completer.completeError(StateError("No se pudo leer el archivo."));
  });

  reader.onLoad.first.then((_) {
    // Leímos como ArrayBuffer para obtener bytes puros
    final result = reader.result;
    if (result is ByteBuffer) {
      final bytes = Uint8List.view(result);
      final b64 = base64Encode(bytes);
      completer.complete(
        PickedWebFile(
          filename: file.name,
          mimeType: file.type ?? "application/octet-stream",
          sizeBytes: file.size,
          base64: b64,
        ),
      );
    } else {
      completer.completeError(
        StateError("Formato de lectura inesperado. Se esperaba ByteBuffer."),
      );
    }
  });

  // Iniciamos la lectura binaria
  reader.readAsArrayBuffer(file);

  return completer.future;
}
