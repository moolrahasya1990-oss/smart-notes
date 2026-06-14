class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int colorValue; // Hex color value stored as int
  final String categoryName;
  final bool isPinned;
  final bool isFavorite;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.colorValue = 0xFFFFFFFF, // Default white
    this.categoryName = 'Personal',
    this.isPinned = false,
    this.isFavorite = false,
  });

  int get wordCount => content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;
  int get charCount => content.length;

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? colorValue,
    String? categoryName,
    bool? isPinned,
    bool? isFavorite,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorValue: colorValue ?? this.colorValue,
      categoryName: categoryName ?? this.categoryName,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'colorValue': colorValue,
      'categoryName': categoryName,
      'isPinned': isPinned ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Note.fromJson(Map<dynamic, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      colorValue: json['colorValue'] as int? ?? 0xFFFFFFFF,
      categoryName: json['categoryName'] as String? ?? 'Personal',
      isPinned: json['isPinned'] == 1 || json['isPinned'] == true,
      isFavorite: json['isFavorite'] == 1 || json['isFavorite'] == true,
    );
  }
}
