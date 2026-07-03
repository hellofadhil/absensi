import 'package:absensi/core/errors/app_exception.dart';
import 'package:absensi/core/network/ai_prompt_api_client.dart';
import 'package:absensi/core/network/transport/ai_prompt_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'retries a temporary gateway failure and returns the next response',
    () async {
      final transport = _SequenceTransport([
        const AiTransportResponse(statusCode: 503, body: ''),
        const AiTransportResponse(statusCode: 200, body: '{"ok":true}'),
      ]);
      final client = AiPromptApiClient(
        transport: transport,
        delay: (_) async {},
      );

      final response = await client.sendPrompt('prompt', temperature: 0.5);

      expect(response, '{"ok":true}');
      expect(transport.requestCount, 2);
    },
  );

  test('stops after three persistent gateway failures', () async {
    final transport = _SequenceTransport([
      const AiTransportResponse(statusCode: 500, body: ''),
      const AiTransportResponse(statusCode: 500, body: ''),
      const AiTransportResponse(statusCode: 500, body: ''),
    ]);
    final client = AiPromptApiClient(transport: transport, delay: (_) async {});

    await expectLater(
      client.sendPrompt('prompt', temperature: 0.5),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          contains('setelah dicoba ulang'),
        ),
      ),
    );
    expect(transport.requestCount, 3);
  });

  test('does not retry a permanent authentication failure', () async {
    final transport = _SequenceTransport([
      const AiTransportResponse(statusCode: 401, body: ''),
    ]);
    final client = AiPromptApiClient(transport: transport, delay: (_) async {});

    await expectLater(
      client.sendPrompt('prompt', temperature: 0.5),
      throwsA(isA<AppException>()),
    );
    expect(transport.requestCount, 1);
  });
}

class _SequenceTransport implements AiPromptTransport {
  _SequenceTransport(this._responses);

  final List<AiTransportResponse> _responses;
  int requestCount = 0;

  @override
  Future<AiTransportResponse> postJson(Uri uri, String body) async {
    final response = _responses[requestCount];
    requestCount++;
    return response;
  }
}
