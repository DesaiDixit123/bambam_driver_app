import 'dart:convert';

import 'package:http/http.dart' as http;

/// Logs every HTTP request and response passing through this client.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final requestBody = _extractRequestBody(request);
    _printRequest(request, requestBody);

    try {
      final streamedResponse = await _inner.send(request);
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseBody = _isTextResponse(streamedResponse.headers)
          ? utf8.decode(responseBytes, allowMalformed: true)
          : '<binary ${responseBytes.length} bytes>';

      _printResponse(request, streamedResponse, responseBody);

      return http.StreamedResponse(
        Stream<List<int>>.value(responseBytes),
        streamedResponse.statusCode,
        contentLength: responseBytes.length,
        request: streamedResponse.request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
    } catch (e) {
      print(
        '===== API ERROR =====\n'
        'METHOD: ${request.method}\n'
        'URL: ${request.url}\n'
        'ERROR: $e\n'
        '=====================',
      );
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  String? _extractRequestBody(http.BaseRequest request) {
    if (request is http.Request) {
      return request.body.isEmpty ? null : request.body;
    }

    if (request is http.MultipartRequest) {
      final fieldText =
          request.fields.isEmpty ? '{}' : jsonEncode(request.fields);
      final fileText = request.files.isEmpty
          ? '[]'
          : jsonEncode(
              request.files
                  .map(
                    (file) => {
                      'field': file.field,
                      'filename': file.filename,
                      'contentType': file.contentType?.toString(),
                      'length': file.length,
                    },
                  )
                  .toList(),
            );
      return 'fields: $fieldText, files: $fileText';
    }

    return null;
  }

  void _printRequest(http.BaseRequest request, String? body) {
    print(
      '===== API REQUEST =====\n'
      'METHOD: ${request.method}\n'
      'URL: ${request.url}\n'
      'HEADERS: ${jsonEncode(_maskHeaders(request.headers))}\n'
      'BODY: ${body ?? '-'}\n'
      '=======================',
    );
  }

  void _printResponse(
    http.BaseRequest request,
    http.StreamedResponse response,
    String body,
  ) {
    print(
      '===== API RESPONSE =====\n'
      'METHOD: ${request.method}\n'
      'URL: ${request.url}\n'
      'STATUS: ${response.statusCode}\n'
      'HEADERS: ${jsonEncode(response.headers)}\n'
      'BODY: $body\n'
      '========================',
    );
  }

  Map<String, String> _maskHeaders(Map<String, String> headers) {
    final masked = Map<String, String>.from(headers);

    for (final entry in masked.entries.toList()) {
      if (entry.key.toLowerCase() == 'authorization') {
        masked[entry.key] = _maskToken(entry.value);
      }
    }

    return masked;
  }

  String _maskToken(String value) {
    if (value.length <= 12) return '***';
    final start = value.substring(0, 8);
    final end = value.substring(value.length - 4);
    return '$start...$end';
  }

  bool _isTextResponse(Map<String, String> headers) {
    String? contentType;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'content-type') {
        contentType = entry.value.toLowerCase();
        break;
      }
    }

    if (contentType == null) return true;
    return contentType.startsWith('text/') ||
        contentType.contains('application/json') ||
        contentType.contains('application/xml') ||
        contentType.contains('application/javascript') ||
        contentType.contains('application/x-www-form-urlencoded');
  }
}
