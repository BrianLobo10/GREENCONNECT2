class Follow {
  final String? id;
  final String followerId; // Quien sigue
  final String followedId; // A quien sigue
  final DateTime createdAt;

  Follow({
    this.id,
    required this.followerId,
    required this.followedId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'follower_id': followerId,
      'followed_id': followedId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Follow.fromMap(Map<String, dynamic> map) {
    return Follow(
      id: map['id'] as String?,
      followerId: map['follower_id'] as String,
      followedId: map['followed_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

