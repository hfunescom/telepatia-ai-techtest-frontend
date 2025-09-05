import 'package:flutter_test/flutter_test.dart';

import 'package:telepatia_ai_techtest_frontend/providers/pipeline_provider.dart';

void main() {
  test('nextCorrelationId increments sequentially', () {
    final provider = PipelineProvider.withDefaultApi();
    expect(provider.nextCorrelationId(), 'ui-corr-001');
    expect(provider.nextCorrelationId(), 'ui-corr-002');
  });

  test('runFromText with empty string sets error state', () async {
    final provider = PipelineProvider.withDefaultApi();
    await provider.runFromText(text: '');
    expect(provider.isError, true);
    expect(provider.errorMessage, 'El texto no puede estar vacío.');
  });

  test('runFromAudioUrl with empty url sets error state', () async {
    final provider = PipelineProvider.withDefaultApi();
    await provider.runFromAudioUrl(url: '');
    expect(provider.isError, true);
    expect(provider.errorMessage, 'La URL no puede estar vacía.');
  });
}
