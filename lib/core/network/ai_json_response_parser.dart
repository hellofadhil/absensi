import 'dart:convert';

abstract final class AiJsonResponseParser {
  static Map<String, dynamic> parse(
    String responseBody, {
    required Set<String> requiredKeys,
  }) {
    final normalizedBody = _stripCodeFence(responseBody.trim());
    if (normalizedBody.isEmpty) {
      throw const FormatException('Empty AI response.');
    }

    final decoded = _decodeCandidate(normalizedBody);
    final payload = _findPayload(decoded, requiredKeys);
    if (payload == null) {
      throw FormatException(
        'AI JSON with keys ${requiredKeys.join(', ')} was not found.',
      );
    }
    return payload;
  }

  static Object? _decodeCandidate(String candidate) {
    try {
      return jsonDecode(candidate);
    } on FormatException {
      final start = candidate.indexOf('{');
      final end = candidate.lastIndexOf('}');
      if (start < 0 || end <= start) rethrow;
      return jsonDecode(candidate.substring(start, end + 1));
    }
  }

  static Map<String, dynamic>? _findPayload(
    Object? value,
    Set<String> requiredKeys, [
    int depth = 0,
  ]) {
    if (depth > 8) return null;

    if (value is String) {
      final candidate = _stripCodeFence(value.trim());
      if (candidate.isEmpty) return null;
      try {
        return _findPayload(
          _decodeCandidate(candidate),
          requiredKeys,
          depth + 1,
        );
      } on FormatException {
        return null;
      }
    }

    if (value is List) {
      for (final item in value) {
        final payload = _findPayload(item, requiredKeys, depth + 1);
        if (payload != null) return payload;
      }
      return null;
    }

    if (value is Map) {
      final map = value.map((key, value) => MapEntry(key.toString(), value));
      if (requiredKeys.every(map.containsKey)) return map;

      const envelopeKeys = [
        'response',
        'result',
        'data',
        'text',
        'content',
        'message',
        'output',
        'candidates',
      ];
      for (final key in envelopeKeys) {
        if (!map.containsKey(key)) continue;
        final payload = _findPayload(map[key], requiredKeys, depth + 1);
        if (payload != null) return payload;
      }
      for (final nestedValue in map.values) {
        final payload = _findPayload(nestedValue, requiredKeys, depth + 1);
        if (payload != null) return payload;
      }
    }
    return null;
  }

  static String _stripCodeFence(String value) {
    if (!value.startsWith('```')) return value;
    return value
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }
}
