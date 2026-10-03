import '../../data/models/citation_item.dart';
import '../../data/models/document_item.dart';

/// Rewrites `<cite .../>` tags into tappable markdown links that reference
/// entries in [citations] by index.
String answerWithCitationLinks(String answer, List<CitationItem> citations) {
  var citationIndex = 0;
  return answer
      .replaceAllMapped(
        RegExp(r'<cite\s+doc="[^"]+"\s+page="\d+"\s+lines="[^"]+"\s*/>'),
        (_) {
          if (citationIndex >= citations.length) return '';
          final currentIndex = citationIndex;
          final citation = citations[citationIndex++];
          return ' [${citation.inlineLabel}](citation:$currentIndex)';
        },
      )
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// Removes `<cite .../>` tags entirely (used when citations are not shown).
String cleanAnswer(String answer) => answer
    .replaceAll(
      RegExp(r'<cite\s+doc="[^"]+"\s+page="\d+"\s+lines="[^"]+"\s*/>'),
      '',
    )
    .replaceAll(RegExp(r'[ \t]+\n'), '\n')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

/// Extracts the citation index encoded in a `citation:<n>` link href.
int? citationIndexFromHref(String? href) {
  if (href == null || !href.startsWith('citation:')) return null;
  return int.tryParse(href.substring('citation:'.length));
}

/// Maps a streaming stage identifier to a human-readable progress label.
String chatProgressLabel(String? stage) => switch (stage) {
  'conversation' => 'Preparing a response...',
  'scope' => 'Checking your selected documents...',
  'retrieval' => 'Finding relevant information...',
  'evidence' => 'Reviewing the source details...',
  'generation' => 'Writing your answer...',
  'validation' => 'Checking the source references...',
  'complete' => 'Finishing your answer...',
  _ => 'Getting your answer ready...',
};

/// A partially streamed answer with the citations resolved so far.
class StreamingAnswer {
  const StreamingAnswer({required this.markdown, required this.citations});

  final String markdown;
  final List<CitationItem> citations;
}

/// Parses a partially streamed answer, resolving `<cite .../>` tags against
/// the known [documents] and dropping any trailing incomplete tag.
StreamingAnswer parseStreamingAnswer(
  String answer,
  List<DocumentItem> documents,
) {
  final citations = <CitationItem>[];
  final citationPattern = RegExp(
    r'<cite\s+doc="([^"]+)"\s+page="(\d+)"\s+lines="(\d+)-(\d+)"\s*/>',
  );
  var markdown = answer.replaceAllMapped(citationPattern, (match) {
    final documentName = match.group(1)!;
    DocumentItem? document;
    for (final item in documents) {
      if (item.name == documentName) {
        document = item;
        break;
      }
    }
    if (document == null) return '';
    final citation = CitationItem(
      document: documentName,
      docId: document.id,
      page: int.parse(match.group(2)!),
      startLine: int.parse(match.group(3)!),
      endLine: int.parse(match.group(4)!),
      text: 'Open the source to inspect this evidence.',
      locationVerified: false,
    );
    final index = citations.length;
    citations.add(citation);
    return ' [${citation.inlineLabel}](citation:$index)';
  });

  final incompleteTag = markdown.lastIndexOf('<cite');
  if (incompleteTag != -1) markdown = markdown.substring(0, incompleteTag);
  return StreamingAnswer(markdown: markdown, citations: citations);
}
