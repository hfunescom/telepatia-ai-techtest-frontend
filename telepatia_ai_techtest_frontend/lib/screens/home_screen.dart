import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pipeline_provider.dart';
import '../utils/bullet_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController(
    text: "I'm feeling a bit unwell; my head hurts and I have a lot of mucus.",
  );

  final _audioUrlController = TextEditingController();
  String? _audioFilename;

  @override
  void dispose() {
    _textController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _isValidUrl(String s) {
    if (s.trim().isEmpty) return false;
    final uri = Uri.tryParse(s.trim());
    if (uri == null) return false;
    if (!(uri.isScheme("http") || uri.isScheme("https"))) return false;
    return uri.host.isNotEmpty;
  }

  String? _inferFilenameFromUrl(String url) {
    try {
      final u = Uri.parse(url);
      final path = u.path;
      if (path.isEmpty || path == "/") return null;
      final name = path.split("/").last;
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  String _detectLanguage(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'[áéíóúñ]').hasMatch(lower)) return 'es-AR';
    final words = lower.split(RegExp(r'\s+'));
    const spanishWords = {
      'el',
      'la',
      'de',
      'que',
      'y',
      'los',
      'las',
      'un',
      'una',
      'tengo',
    };
    const englishWords = {'the', 'and', 'is', 'are', 'to', 'have'};
    final spanishCount = words.where((w) => spanishWords.contains(w)).length;
    final englishCount = words.where((w) => englishWords.contains(w)).length;
    return spanishCount >= englishCount ? 'es-AR' : 'en';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PipelineProvider>();
    final audioUrl = _audioUrlController.text.trim();
    final isAudioUrlValid = _isValidUrl(audioUrl);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/telepatia_logo.png', height: 32),
            const SizedBox(width: 8),
            const Text('Doctor Helper'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16.0),

            child: SelectionArea(
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Diagnosis from text",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Describe your symptoms (text)',
                      hintText:
                          'E.g., My head hurts and I have a lot of mucus...',
                    ),
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
                                final p = context.read<PipelineProvider>();
                                await p.runFromText(
                                  text: _textController.text,
                                  language: _detectLanguage(
                                    _textController.text,
                                  ),
                                  correlationId: p.nextCorrelationId(),
                                );
                              },
                      icon: const Icon(Icons.medical_services),
                      label:
                          provider.isLoading
                              ? const Text("Processing…")
                              : const Text("Diagnose"),
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    "Diagnosis from audio (URL)",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Paste the public link to your audio (.ogg, .mp3, .wav, etc.). "
                    "We'll use the direct URL to transcribe and diagnose.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _audioUrlController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Audio URL',
                      hintText: 'https://.../my_audio.ogg',
                      errorText:
                          audioUrl.isEmpty || isAudioUrlValid
                              ? null
                              : 'Enter a valid URL (http/https).',
                      suffixIcon:
                          audioUrl.isEmpty
                              ? null
                              : IconButton(
                                tooltip: "Clear",
                                onPressed:
                                    provider.isLoading
                                        ? null
                                        : () {
                                          setState(() {
                                            _audioUrlController.clear();
                                            _audioFilename = null;
                                          });
                                        },
                                icon: const Icon(Icons.clear),
                              ),
                    ),
                    onChanged: (_) {
                      final inferred = _inferFilenameFromUrl(
                        _audioUrlController.text,
                      );
                      setState(() => _audioFilename = inferred);
                    },
                  ),

                  if (_audioFilename != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Inferred name: ${_audioFilename!}",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed:
                          provider.isLoading || !isAudioUrlValid
                              ? null
                              : () async {
                                FocusScope.of(context).unfocus();
                                try {
                                  await context
                                      .read<PipelineProvider>()
                                      .runFromAudioUrl(
                                        url: audioUrl,
                                        filename: _audioFilename,
                                        language: _detectLanguage(
                                          _textController.text,
                                        ),
                                        correlationId:
                                            provider.nextCorrelationId(),
                                      );
                                } catch (e) {
                                  _showSnack('Could not send audio: $e');
                                }
                              },
                      icon: const Icon(Icons.link),
                      label:
                          provider.isLoading
                              ? const Text("Processing audio…")
                              : const Text("Diagnose from URL"),
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
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                          child: buildBulletList(
                              provider.error ?? {"message": "Unknown error"}),
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

  /* BORRAR
  String _formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return "0 B";
    const k = 1024;
    const sizes = ["B", "KB", "MB", "GB", "TB"];
    final i = (math.log(bytes) / math.log(k)).floor();
    final p = bytes / math.pow(k, i);
    return "${p.toStringAsFixed(decimals)} ${sizes[i]}";
  }
*/
}

class _ResultBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(Object?) pretty;

  const _ResultBlock({required this.data, required this.pretty});

  @override
  Widget build(BuildContext context) {
    final transcript = data["transcript"];
    final extracted = data["extracted"];

    final diagnosis =
        (data["diagnosis"] ?? data["diagnose"]) as Map<String, dynamic>?;
    final timings =
        (data["pipeline"] is Map) ? data["pipeline"]["timingsMs"] : null;

    final bold = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Diagnosis", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),

        if (diagnosis != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _DiagnosisView(diagnosis: diagnosis),
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (timings != null || transcript != null || extracted != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Metrics",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      final itemWidth =
                          isWide
                              ? (constraints.maxWidth - 24) / 3
                              : constraints.maxWidth;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (timings != null)
                            SizedBox(
                              width: itemWidth,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        "Timing (ms):",
                                        style: bold,
                                      ),
                                      const SizedBox(height: 4),
                                      buildBulletList(timings),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (transcript != null)
                            SizedBox(
                              width: itemWidth,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        "Transcript:",
                                        style: bold,
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(pretty(transcript)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (extracted != null)
                            SizedBox(
                              width: itemWidth,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SelectableText("Extracted:", style: bold),
                                      const SizedBox(height: 4),
                                      buildBulletList(extracted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

        if (transcript == null && extracted == null && diagnosis == null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SelectableText("Full response:\n${pretty(data)}"),
            ),
          ),
        ],
      ],
    );
  }
}

class _DiagnosisView extends StatelessWidget {
  final Map<String, dynamic> diagnosis;
  const _DiagnosisView({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final summary = diagnosis["summary"] as String?;
    final severity = diagnosis["severity"] as String?;
    final differentials =
        (diagnosis["differentials"] as List?)?.cast<dynamic>() ?? const [];
    final recommendations =
        (diagnosis["recommendations"] as List?)?.cast<dynamic>() ?? const [];

    final bold = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
    final normal = Theme.of(context).textTheme.bodyMedium!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary != null) ...[
          SelectableText("Summary", style: bold),
          const SizedBox(height: 4),
          SelectableText(summary, style: normal),
          const SizedBox(height: 12),
        ],

        if (severity != null) ...[
          SelectableText("Severity", style: bold),
          const SizedBox(height: 4),
          SelectableText(severity, style: normal),
          const SizedBox(height: 12),
        ],

        if (differentials.isNotEmpty) ...[
          SelectableText("Differentials", style: bold),
          const SizedBox(height: 4),
          SelectableText(
            differentials.map((e) => "• $e").join("\n"),
            style: normal,
          ),
          const SizedBox(height: 12),
        ],

        if (recommendations.isNotEmpty) ...[
          SelectableText("Recommendations", style: bold),
          const SizedBox(height: 4),
          SelectableText(
            recommendations.map((e) => "• $e").join("\n"),
            style: normal,
          ),
        ],
      ],
    );
  }
}
