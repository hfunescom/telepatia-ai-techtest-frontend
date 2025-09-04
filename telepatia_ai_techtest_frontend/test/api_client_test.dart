import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:telepatia_ai_techtest_frontend/api/client.dart';

void main() {
  group('ApiClient.pipelineFromText', () {
    test('returns decoded json on success', () async {
      final mock = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost/pipeline');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['input']['text'], 'hola');
        return http.Response('{"ok": true}', 200);
      });

      final client = ApiClient(baseUrl: 'http://localhost', httpClient: mock);
      final res = await client.pipelineFromText(text: 'hola');
      expect(res['ok'], true);
    });

    test('throws ApiException on http error', () async {
      final mock = MockClient((request) async {
        return http.Response('ups', 500);
      });

      final client = ApiClient(baseUrl: 'http://localhost', httpClient: mock);
      expect(
        () => client.pipelineFromText(text: 'hola'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

