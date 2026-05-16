class ParsedGroupCommand {
  final String name;
  final String description;

  ParsedGroupCommand({required this.name, this.description = ''});
}

ParsedGroupCommand parseGroupCommand(String text) {
  String raw = text.trim();
  if (raw.isEmpty) return ParsedGroupCommand(name: '');

  raw = raw.replaceAll(RegExp(r'^[\.\s,\-]+'), '');
  raw = raw.replaceAll(RegExp(r'[\.\s,\-]+$'), '');

  final prefixPattern = RegExp(
    r'^(create|make|add|start|new)\s+'
    r'(a|an|the|my|our|new)?\s*'
    r'(group|trip|bill|expense|split|plan|project)?\s*'
    r'(called|named|titled|entitled|for|:\s*)?\s*',
    caseSensitive: false,
  );
  raw = raw.replaceFirst(prefixPattern, '').trim();

  if (raw.isEmpty) return ParsedGroupCommand(name: '');

  final purposeDelimiters = [
    RegExp(r'\s+for\s+', caseSensitive: false),
    RegExp(r'\s+to\s+(split|share|pay|divide|manage|track)\s+',
        caseSensitive: false),
  ];

  for (final delim in purposeDelimiters) {
    final match = delim.firstMatch(raw);
    if (match != null && match.start > 0) {
      final name = raw.substring(0, match.start).trim();
      final desc = raw.substring(match.end).trim();
      if (name.isNotEmpty) {
        return ParsedGroupCommand(
          name: _capitalize(name),
          description: _capitalize(desc),
        );
      }
    }
  }

  return ParsedGroupCommand(name: _capitalize(raw));
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
