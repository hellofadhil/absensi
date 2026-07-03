class AiTransportResponse {
  const AiTransportResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

abstract interface class AiPromptTransport {
  Future<AiTransportResponse> postJson(Uri uri, String body);
}

class AiTransportException implements Exception {
  const AiTransportException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class AiTransportConnectionException extends AiTransportException {
  const AiTransportConnectionException(super.message, [super.cause]);
}
