// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:html';

import 'ai_prompt_transport.dart';

AiPromptTransport createAiPromptTransport() => _WebAiPromptTransport();

class _WebAiPromptTransport implements AiPromptTransport {
  @override
  Future<AiTransportResponse> postJson(Uri uri, String body) async {
    try {
      final response = await HttpRequest.request(
        uri.toString(),
        method: 'POST',
        requestHeaders: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        sendData: body,
      ).timeout(const Duration(seconds: 80));
      return AiTransportResponse(
        statusCode: response.status ?? 0,
        body: response.responseText ?? '',
      );
    } on TimeoutException {
      rethrow;
    } catch (error) {
      throw AiTransportConnectionException(
        'Browser tidak dapat menjangkau layanan AI.',
        error,
      );
    }
  }
}
