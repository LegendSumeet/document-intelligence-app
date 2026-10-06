import 'package:flutter/foundation.dart';

/// Who authored a chat message.
enum ChatAuthor { user, askDocs }

/// A tappable source reference attached to an AskDocs answer.
@immutable
class Citation {
  const Citation({
    required this.label,
    required this.detail,
    this.page,
    this.lines,
    this.documentId,
  });

  /// Page and `start-end` line range, used to match inline `<cite>` tags.
  final int? page;
  final String? lines;
  final String? documentId;

  /// Short chip text, e.g. "Page 4" or "Section 2".
  final String label;

  /// Longer description shown in the source sheet,
  /// e.g. "Page 4 of Research Paper.pdf".
  final String detail;
}

/// One message in the document chat.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.author,
    required this.text,
    this.citations = const [],
    this.isThinking = false,
    this.isStreaming = false,
    this.isError = false,
  });

  final String id;
  final ChatAuthor author;

  /// Markdown body rendered in assistant messages.
  final String text;
  final List<Citation> citations;

  /// Renders the animated "AskDocs is thinking…" state instead of text.
  final bool isThinking;

  /// The answer is still being typed out; shows a caret.
  final bool isStreaming;
  final bool isError;

  bool get isUser => author == ChatAuthor.user;

  factory ChatMessage.user(String text) => ChatMessage(
    id: 'u-${DateTime.now().microsecondsSinceEpoch}',
    author: ChatAuthor.user,
    text: text,
  );

  factory ChatMessage.thinking() => ChatMessage(
    id: 'thinking-${DateTime.now().microsecondsSinceEpoch}',
    author: ChatAuthor.askDocs,
    text: '',
    isThinking: true,
  );
}
