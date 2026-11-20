class AssistantReply {
  const AssistantReply({
    required this.text,
    this.listings = const [],
    this.sources = const [],
    this.draft,
    this.suggestions = const [],
  });
  final String text;
  final List<Map<String, dynamic>> listings;
  final List<Map<String, dynamic>> sources;
  final Map<String, dynamic>? draft;
  final List<String> suggestions;
  factory AssistantReply.fromJson(Map<String, dynamic> json) => AssistantReply(
    text: json['text'] as String,
    listings: (json['listings'] as List).cast<Map<String, dynamic>>(),
    sources: (json['sources'] as List).cast<Map<String, dynamic>>(),
    draft: json['draft'] as Map<String, dynamic>?,
    suggestions: (json['suggestions'] as List?)?.cast<String>() ?? const [],
  );
}

class AssistantTurn {
  const AssistantTurn({required this.id, required this.input, this.reply});
  final String id;
  final String input;
  final AssistantReply? reply;
}
