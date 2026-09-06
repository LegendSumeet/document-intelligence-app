import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class DocumentApi {
  DocumentApi({http.Client? client}) : _client = client ?? http.Client() {
    ApiConfig.validate();
  }

  final http.Client _client;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${ApiConfig.apiToken}',
    'Content-Type': 'application/json',
  };

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<bool> health() async {
    final response = await _client.get(_uri('/health'), headers: _headers);
    return _decode(response)['status'] == 'ok';
  }

  Future<List<DocumentItem>> listDocuments() async {
    final response = await _client.get(_uri('/documents'), headers: _headers);
    final body = _decode(response);
    final records = (body['documents'] as List).cast<Map<String, dynamic>>();
    return Future.wait(
      records.map((record) async {
        if (record['status'] != 'completed' ||
            record.containsKey('retrievalReady')) {
          return DocumentItem.fromJson(record);
        }
        final id = (record['id'] ?? record['doc_id']) as String;
        try {
          return DocumentItem.fromJson(await getDocument(id));
        } on ApiException {
          return DocumentItem.fromJson(record);
        }
      }),
    );
  }

  Future<Map<String, dynamic>> getDocument(String documentId) async {
    final response = await _client.get(
      _uri('/documents/$documentId'),
      headers: _headers,
    );
    return _decode(response);
  }

  Future<List<dynamic>> getStructure(String documentId) async {
    final response = await _client.get(
      _uri('/documents/$documentId/structure'),
      headers: _headers,
    );
    final body = _decodeAny(response);
    if (body is! List) {
      throw const ApiException(500, 'Invalid document structure response.');
    }
    return body;
  }

  Future<NumberedPagesResult> getPages(
    String documentId,
    String pageSpec,
  ) async {
    final response = await _client.get(
      _uri('/documents/$documentId/pages/${Uri.encodeComponent(pageSpec)}'),
      headers: _headers,
    );
    return NumberedPagesResult.fromJson(_decode(response));
  }

  Future<PageEvidenceResult> getPageEvidence(
    String documentId,
    int page,
  ) async {
    final response = await _client.get(
      _uri('/documents/$documentId/evidence/$page'),
      headers: _headers,
    );
    return PageEvidenceResult.fromJson(_decode(response));
  }

  Future<Uint8List> getDocumentFile(String documentId) async {
    final response = await _client.get(
      _uri('/documents/$documentId/file'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decode(response);
    }
    return response.bodyBytes;
  }

  Future<DocumentUploadResult> uploadPdf(
    String filename,
    Uint8List bytes,
  ) async {
    final request = http.MultipartRequest('POST', _uri('/documents'))
      ..headers['Authorization'] = 'Bearer ${ApiConfig.apiToken}'
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    return DocumentUploadResult.fromJson(_decode(response));
  }

  Future<ChatSession> createSession(List<String> documentIds) async {
    final response = await _client.post(
      _uri('/chat/sessions'),
      headers: _headers,
      body: jsonEncode({'document_ids': documentIds}),
    );
    return ChatSession.fromJson(_decode(response));
  }

  Future<ChatSession> getSession(String sessionId) async {
    final response = await _client.get(
      _uri('/chat/sessions/$sessionId'),
      headers: _headers,
    );
    return ChatSession.fromJson(_decode(response));
  }

  Future<ChatSession> updateSessionDocuments(
    String sessionId,
    List<String> documentIds,
  ) async {
    final response = await _client.put(
      _uri('/chat/sessions/$sessionId/documents'),
      headers: _headers,
      body: jsonEncode({'document_ids': documentIds}),
    );
    return ChatSession.fromJson(_decode(response));
  }

  Future<QueryResult> sendMessage(
    String sessionId,
    String message, {
    String reasoningEffort = 'medium',
  }) async {
    final response = await _client.post(
      _uri('/chat/sessions/$sessionId/messages'),
      headers: _headers,
      body: jsonEncode({
        'message': message,
        'reasoning_effort': reasoningEffort,
      }),
    );
    return QueryResult.fromJson(_decode(response));
  }

  Future<QueryResult> query(
    List<String> documentIds,
    String question, {
    String? reasoningEffort,
  }) async {
    final response = await _client.post(
      _uri('/queries'),
      headers: _headers,
      body: jsonEncode({
        'document_ids': documentIds,
        'question': question,
        'reasoning_effort': ?reasoningEffort,
      }),
    );
    return QueryResult.fromJson(_decode(response));
  }

  Future<ExtractionResult> extract(
    List<String> documentIds,
    String instruction, {
    String schemaName = 'custom',
  }) async {
    final response = await _client.post(
      _uri('/extractions'),
      headers: _headers,
      body: jsonEncode({
        'document_ids': documentIds,
        'instruction': instruction,
        'schema_name': schemaName,
      }),
    );
    return ExtractionResult.fromJson(_decode(response));
  }

  Stream<ChatStreamEvent> streamMessage(
    String sessionId,
    String message, {
    String reasoningEffort = 'medium',
  }) async* {
    final request =
        http.Request('POST', _uri('/chat/sessions/$sessionId/messages/stream'))
          ..headers.addAll({..._headers, 'Accept': 'text/event-stream'})
          ..body = jsonEncode({
            'message': message,
            'reasoning_effort': reasoningEffort,
          });
    final response = await _client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        await response.stream.bytesToString(),
      );
    }

    String? eventName;
    final dataLines = <String>[];
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.isEmpty) {
        if (eventName != null && dataLines.isNotEmpty) {
          yield ChatStreamEvent(
            type: eventName,
            data: jsonDecode(dataLines.join('\n')) as Map<String, dynamic>,
          );
        }
        eventName = null;
        dataLines.clear();
      } else if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }
    if (eventName != null && dataLines.isNotEmpty) {
      yield ChatStreamEvent(
        type: eventName,
        data: jsonDecode(dataLines.join('\n')) as Map<String, dynamic>,
      );
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final response = await _client.delete(
      _uri('/chat/sessions/$sessionId'),
      headers: _headers,
    );
    if (response.statusCode != 204) _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = _decodeAny(response);
    if (body is! Map<String, dynamic>) {
      throw ApiException(
        response.statusCode,
        'Invalid API response (${response.statusCode}).',
      );
    }
    return body;
  }

  dynamic _decodeAny(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        response.statusCode,
        'The server returned an unreadable response (${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body is Map<String, dynamic> ? body['detail'] : null;
      throw ApiException(
        response.statusCode,
        detail is String ? detail : 'Request failed (${response.statusCode}).',
      );
    }
    return body;
  }

  void close() => _client.close();
}
