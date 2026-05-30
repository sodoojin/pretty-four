class ConversationSummary {
  final String tone;
  final List<String> patterns;
  final List<String> improvements;

  const ConversationSummary({
    required this.tone,
    required this.patterns,
    required this.improvements,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        tone: json['tone'] as String,
        patterns: (json['patterns'] as List).cast<String>(),
        improvements: (json['improvements'] as List).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'tone': tone,
        'patterns': patterns,
        'improvements': improvements,
      };
}
