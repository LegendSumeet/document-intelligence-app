import 'citation_item.dart';

/// A backend chat session bound to a set of documents.
class ChatSession {
  const ChatSession({
    required this.id,
    required this.documentIds,
    this.history = const [],
    this.busy = false,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    documentIds: (json['document_ids'] as List).cast<String>(),
    history: (json['history'] as List? ?? const [])
        .map((item) => ChatTurn.fromJson(item as Map<String, dynamic>))
        .toList(),
    busy: json['busy'] as bool? ?? false,
  );

  final String id;
  final List<String> documentIds;
  final List<ChatTurn> history;
  final bool busy;
}

/// A single persisted turn of a chat session.
class ChatTurn {
  const ChatTurn({required this.role, required this.content});

  factory ChatTurn.fromJson(Map<String, dynamic> json) => ChatTurn(
    role: json['role'] as String,
    content: json['content'] as String,
  );

  final String role;
  final String content;
}

/// A server-sent event emitted while streaming a chat answer.
class ChatStreamEvent {
  const ChatStreamEvent({required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;
}

/// A message rendered in the chat transcript (user, assistant, or streaming).
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.verified = false,
    this.citations = const [],
    this.conversational = false,
    this.selectedPages = const {},
    this.usage = const {},
  });

  final String role;
  final String text;
  final bool verified;
  final List<CitationItem> citations;
  final bool conversational;
  final Map<String, List<int>> selectedPages;
  final Map<String, dynamic> usage;
}
