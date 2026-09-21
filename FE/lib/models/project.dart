class Project {
  final String id;
  final String title;
  final String description;
  final List<String> paperIds;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.paperIds,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'paperIds': paperIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        paperIds: List<String>.from(json['paperIds'] as List? ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Project copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? paperIds,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      paperIds: paperIds ?? List<String>.from(this.paperIds),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

