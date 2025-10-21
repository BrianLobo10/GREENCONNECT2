class SavedPost {
  final String? id;
  final String userId;
  final String postId;
  final DateTime savedAt;

  SavedPost({
    this.id,
    required this.userId,
    required this.postId,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'post_id': postId,
      'saved_at': savedAt.toIso8601String(),
    };
  }

  factory SavedPost.fromMap(Map<String, dynamic> map) {
    return SavedPost(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      postId: map['post_id'] as String,
      savedAt: DateTime.parse(map['saved_at'] as String),
    );
  }
}

