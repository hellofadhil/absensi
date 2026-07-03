import 'dart:async';
import 'dart:convert';

import '../constants/api_endpoints.dart';
import '../errors/app_exception.dart';
import 'transport/ai_prompt_transport.dart';
import 'transport/ai_prompt_transport_factory.dart';

class AiPromptApiClient {
  AiPromptApiClient({
    AiPromptTransport? transport,
    Future<void> Function(Duration duration)? delay,
  }) : _transport = transport ?? createAiPromptTransport(),
       _delay = delay ?? ((duration) => Future<void>.delayed(duration));

  final AiPromptTransport _transport;
  final Future<void> Function(Duration duration) _delay;

  static const _maximumAttempts = 3;
  static const _retryDelays = [
    Duration(milliseconds: 700),
    Duration(milliseconds: 1600),
  ];

  Future<String> sendPrompt(
    String prompt, {
    required double temperature,
    String endpoint = ApiEndpoints.aiGateway,
  }) async {
    final uri = Uri.parse(endpoint);
    final requestBody = jsonEncode({
      'message': prompt,
      'temperature': temperature,
    });

    for (var attempt = 0; attempt < _maximumAttempts; attempt++) {
      try {
        final response = await _transport.postJson(uri, requestBody);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.body;
        }
        if (_isRetryableStatus(response.statusCode) &&
            attempt < _maximumAttempts - 1) {
          await _waitBeforeRetry(attempt);
          continue;
        }
        throw AppException(
          _messageForStatus(response.statusCode),
          cause: 'HTTP ${response.statusCode}',
        );
      } on AppException {
        rethrow;
      } on TimeoutException catch (error) {
        if (attempt < _maximumAttempts - 1) {
          await _waitBeforeRetry(attempt);
          continue;
        }
        throw AppException(
          'AI belum merespons setelah beberapa percobaan. Coba lagi.',
          cause: error,
        );
      } on AiTransportConnectionException catch (error) {
        if (attempt < _maximumAttempts - 1) {
          await _waitBeforeRetry(attempt);
          continue;
        }
        throw AppException(
          'Koneksi ke AI belum berhasil. Periksa internet lalu coba lagi.',
          cause: error,
        );
      } on AiTransportException catch (error) {
        if (attempt < _maximumAttempts - 1) {
          await _waitBeforeRetry(attempt);
          continue;
        }
        throw AppException(
          'Koneksi AI gagal setelah dicoba ulang. Silakan coba lagi.',
          cause: error,
        );
      }
    }

    throw const AppException('AI belum dapat merespons. Silakan coba lagi.');
  }

  bool _isRetryableStatus(int statusCode) => switch (statusCode) {
    408 || 425 || 429 || 500 || 502 || 503 || 504 => true,
    _ => false,
  };

  Future<void> _waitBeforeRetry(int attempt) => _delay(_retryDelays[attempt]);

  String _messageForStatus(int statusCode) => switch (statusCode) {
    400 => 'Input belum dapat diproses. Coba tulis lebih sederhana.',
    401 || 403 => 'Layanan AI belum dapat diakses saat ini.',
    408 => 'Permintaan AI kehabisan waktu setelah dicoba ulang.',
    425 => 'Permintaan AI belum siap diproses. Coba lagi sebentar.',
    429 => 'Batas penggunaan AI masih tercapai setelah dicoba ulang.',
    500 => 'Gateway AI gagal memproses permintaan setelah dicoba ulang.',
    502 || 503 || 504 => 'Gateway AI belum tersedia setelah dicoba ulang.',
    >= 500 => 'Gateway AI mengembalikan kegagalan yang tidak terduga.',
    _ => 'Konten AI belum dapat dibuat. Silakan coba lagi.',
  };
}
