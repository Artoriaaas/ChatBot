class Citation {
  final String paperId;
  final int page;
  final String excerpt;
  final String label; // e.g., '[1]'
  
  const Citation({
    required this.paperId,
    required this.page,
    required this.excerpt,
    required this.label,
  });
}

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  String content;
  final List<Citation> citations;
  final DateTime timestamp;
  final String? selectedText; // context for user questions
  bool isStreaming;
  bool isError;
  
  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.citations = const [],
    DateTime? timestamp,
    this.selectedText,
    this.isStreaming = false,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();
  
  ChatMessage copyWith({
    String? content,
    List<Citation>? citations,
    bool? isStreaming,
    bool? isError,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      timestamp: timestamp,
      selectedText: selectedText,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
    );
  }
}
