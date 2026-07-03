import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ai_prompt_transport.dart';

AiPromptTransport createAiPromptTransport() => _IoAiPromptTransport();

class _IoAiPromptTransport implements AiPromptTransport {
  @override
  Future<AiTransportResponse> postJson(Uri uri, String body) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 20));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.add(utf8.encode(body));

      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 20));
      return AiTransportResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );
    } on TimeoutException {
      rethrow;
    } on SocketException catch (error) {
      throw AiTransportConnectionException(error.message, error);
    } on HttpException catch (error) {
      throw AiTransportException(error.message, error);
    } finally {
      client.close(force: true);
    }
  }
}
