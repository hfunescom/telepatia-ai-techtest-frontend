import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pipeline_provider.dart';
import '../utils/web_file_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estado para TEXT → pipeline
  final _textController = TextEditingController(
    text:
        "Me estoy sintiendo un poco mal, me duele la cabeza y tengo mucho moco.",
  );
  final _corrController = TextEditingController(text: "ui-corr-001");
  String _language = "es-AR";

  // Estado para AUDIO → pipeline
  String? _pickedFileName;
  int? _pickedFileSize;
  String? _pickedFileB64;

  @override
  void dispose() {
    _textController.dispose();
    _corrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PipelineProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Telepatía AI — Frontend')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const SizedBox(height: 8),
                Text(
                  "Diagnóstico desde texto",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Describe tus síntomas (texto)',
                    hintText: 'Ej: Me duele la cabeza y tengo mucho moco...',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _language,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Idioma",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "es-AR",
                            child: Text("Español (AR)"),
                          ),
                          DropdownMenuItem(value: "es", child: Text("Español")),
                          DropdownMenuItem(value: "en", child: Text("Inglés")),
                        ],
                        onChanged:
                            (v) => setState(() => _language = v ?? "es-AR"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _corrController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Correlation ID (opcional)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed:
                        provider.isLoading
                            ? null
                            : () async {
                              FocusScope.of(context).unfocus();
                              await context
                                  .read<PipelineProvider>()
                                  .runFromText(
                                    text: _textController.text,
                                    language: _language,
                                    correlationId:
                                        _corrController.text.trim().isEmpty
                                            ? null
                                            : _corrController.text.trim(),
                                  );
                            },
                    icon: const Icon(Icons.medical_services),
                    label:
                        provider.isLoading
                            ? const Text("Procesando…")
                            : const Text("Diagnosticar"),
                  ),
                ),

                // ==========================
                // Sección: Diagnóstico desde AUDIO
                // ==========================
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  "Diagnóstico desde audio",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  "Seleccioná un archivo de audio (por ejemplo .ogg, .wav, .mp3). "
                  "Lo convertiremos a Base64 en el navegador y llamaremos al pipeline.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            provider.isLoading
                                ? null
                                : () async {
                                  final picked = await pickSingleFileAsBase64(
                                    accept: "audio/*",
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _pickedFileName = picked.filename;
                                      _pickedFileSize = picked.sizeBytes;
                                      _pickedFileB64 = picked.base64;
                                    });
                                  }
                                },
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Elegir audio"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_pickedFileName != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.audiotrack),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedFileName!,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Tamaño: ${_formatBytes(_pickedFileSize ?? 0)}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: "Quitar archivo",
                            onPressed:
                                provider.isLoading
                                    ? null
                                    : () {
                                      setState(() {
                                        _pickedFileName = null;
                                        _pickedFileSize = null;
                                        _pickedFileB64 = null;
                                      });
                                    },
                            icon: const Icon(Icons.clear),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed:
                        provider.isLoading ||
                                _pickedFileB64 == null ||
                                _pickedFileName == null
                            ? null
                            : () async {
                              FocusScope.of(context).unfocus();
                              await context
                                  .read<PipelineProvider>()
                                  .runFromAudioBase64(
                                    base64Audio: _pickedFileB64!,
                                    filename: _pickedFileName!,
                                    language: _language,
                                    correlationId:
                                        _corrController.text.trim().isEmpty
                                            ? null
                                            : _corrController.text.trim(),
                                  );
                            },
                    icon: const Icon(Icons.medical_information),
                    label:
                        provider.isLoading
                            ? const Text("Procesando audio…")
                            : const Text("Diagnosticar audio"),
                  ),
                ),

                const SizedBox(height: 20),
                if (provider.isLoading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
                if (provider.isError) ...[
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        provider.errorMessage ?? "Error desconocido",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
                if (provider.isSuccess && provider.lastResponse != null)
                  _ResultBlock(
                    data: provider.lastResponse!,
                    pretty: provider.prettyJson,
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Formatea bytes en B/KB/MB/GB.
  String _formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return "0 B";
    const k = 1024;
    const sizes = ["B", "KB", "MB", "GB", "TB"];
    final i = (math.log(bytes) / math.log(k)).floor();
    final p = bytes / math.pow(k, i);
    return "${p.toStringAsFixed(decimals)} ${sizes[i]}";
  }
}

class _ResultBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(Object?) pretty;

  const _ResultBlock({required this.data, required this.pretty});

  @override
  Widget build(BuildContext context) {
    // Intentamos mostrar campos conocidos si existen; sino, el JSON completo.
    final transcript = data["transcript"];
    final extracted = data["extracted"];
    final diagnose = data["diagnose"];
    final timings =
        (data["pipeline"] is Map) ? data["pipeline"]["timingsMs"] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Resultado", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (timings != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("Tiempos (ms):\n${pretty(timings)}"),
            ),
          ),
        if (transcript != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("Transcript:\n${pretty(transcript)}"),
            ),
          ),
        ],
        if (extracted != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("Extracted:\n${pretty(extracted)}"),
            ),
          ),
        ],
        if (diagnose != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("Diagnose:\n${pretty(diagnose)}"),
            ),
          ),
        ],
        const SizedBox(height: 8),
        // Fallback: si no hay campos conocidos, mostramos todo:
        if (transcript == null && extracted == null && diagnose == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("Respuesta completa:\n${pretty(data)}"),
            ),
          ),
      ],
    );
  }
}
