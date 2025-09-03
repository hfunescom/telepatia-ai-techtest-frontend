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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
            // Habilita selección de texto en toda la pantalla:
            child: SelectionArea(
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
                            DropdownMenuItem(
                              value: "es",
                              child: Text("Español"),
                            ),
                            DropdownMenuItem(
                              value: "en",
                              child: Text("Inglés"),
                            ),
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
                    "Seleccioná un archivo de audio (.ogg, .wav, .mp3, etc.). "
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
                                    try {
                                      // Acepta TODOS los formatos de audio
                                      final picked = await pickSingleFileAsBase64(
                                        accept: "audio/*",
                                        // opcional: subí el límite si necesitas más (por defecto 15MB en util)
                                      );
                                      if (picked == null) {
                                        // usuario canceló
                                        return;
                                      }
                                      setState(() {
                                        _pickedFileName = picked.filename;
                                        _pickedFileSize = picked.sizeBytes;
                                        // IMPORTANTE: es solo el payload base64 (sin "data:...;base64,")
                                        _pickedFileB64 = picked.base64;
                                      });
                                    } catch (e) {
                                      _showSnack(
                                        'No se pudo leer el archivo: $e',
                                      );
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
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tamaño: ${_formatBytes(_pickedFileSize ?? 0)}",
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
                                try {
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
                                } catch (e) {
                                  _showSnack('No se pudo enviar el audio: $e');
                                }
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
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
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
    // Campos esperados:
    final transcript = data["transcript"];
    final extracted = data["extracted"];
    // Backend actual usa "diagnosis"; toleramos "diagnose" por compatibilidad:
    final diagnosis =
        (data["diagnosis"] ?? data["diagnose"]) as Map<String, dynamic>?;
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
              child: SelectableText("Tiempos (ms):\n${pretty(timings)}"),
            ),
          ),

        if (transcript != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SelectableText("Transcript:\n${pretty(transcript)}"),
            ),
          ),
        ],

        if (extracted != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SelectableText("Extracted:\n${pretty(extracted)}"),
            ),
          ),
        ],

        if (diagnosis != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _DiagnosisView(diagnosis: diagnosis, pretty: pretty),
            ),
          ),
        ],

        // Fallback: si no hay campos conocidos, mostramos todo:
        if (transcript == null && extracted == null && diagnosis == null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SelectableText("Respuesta completa:\n${pretty(data)}"),
            ),
          ),
        ],
      ],
    );
  }
}

class _DiagnosisView extends StatelessWidget {
  final Map<String, dynamic> diagnosis;
  final String Function(Object?) pretty;
  const _DiagnosisView({required this.diagnosis, required this.pretty});

  @override
  Widget build(BuildContext context) {
    final summary = diagnosis["summary"] as String?;
    final severity = diagnosis["severity"] as String?;
    final differentials =
        (diagnosis["differentials"] as List?)?.cast<dynamic>() ?? const [];
    final recommendations =
        (diagnosis["recommendations"] as List?)?.cast<dynamic>() ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Diagnóstico", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (summary != null) SelectableText("Resumen: $summary"),
        if (severity != null) ...[
          const SizedBox(height: 8),
          SelectableText("Severidad: $severity"),
        ],
        if (differentials.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text("Diferenciales:"),
          const SizedBox(height: 4),
          SelectableText(differentials.map((e) => "• $e").join("\n")),
        ],
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text("Recomendaciones:"),
          const SizedBox(height: 4),
          SelectableText(recommendations.map((e) => "• $e").join("\n")),
        ],
        if (summary == null &&
            severity == null &&
            differentials.isEmpty &&
            recommendations.isEmpty)
          SelectableText("Diagnóstico (raw):\n${pretty(diagnosis)}"),
      ],
    );
  }
}
