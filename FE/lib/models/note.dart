class Note {
  final String id;
  final String paperId;
  final String paperTitle;
  final int page;
  final String sectionTitle;
  String content;
  final DateTime createdAt;
  
  Note({
    required this.id,
    required this.paperId,
    required this.paperTitle,
    required this.page,
    required this.sectionTitle,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'paperId': paperId,
    'paperTitle': paperTitle,
    'page': page,
    'sectionTitle': sectionTitle,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    paperId: json['paperId'] as String,
    paperTitle: json['paperTitle'] as String,
    page: json['page'] as int,
    sectionTitle: json['sectionTitle'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
