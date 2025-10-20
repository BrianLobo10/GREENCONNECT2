enum ReactionType {
  heart,     // corazón
  like,      // like/pulgar
  smile,     // carita sonriente
  angry;     // carita enojada

  String get emoji {
    switch (this) {
      case ReactionType.heart:
        return '❤️';
      case ReactionType.like:
        return '👍';
      case ReactionType.smile:
        return '😊';
      case ReactionType.angry:
        return '😠';
    }
  }

  String get name {
    switch (this) {
      case ReactionType.heart:
        return 'heart';
      case ReactionType.like:
        return 'like';
      case ReactionType.smile:
        return 'smile';
      case ReactionType.angry:
        return 'angry';
    }
  }

  static ReactionType fromString(String value) {
    switch (value) {
      case 'heart':
        return ReactionType.heart;
      case 'like':
        return ReactionType.like;
      case 'smile':
        return ReactionType.smile;
      case 'angry':
        return ReactionType.angry;
      default:
        return ReactionType.like;
    }
  }
}

class Reaction {
  final String? id;
  final String postId;
  final String userId;
  final ReactionType type;

  Reaction({
    this.id,
    required this.postId,
    required this.userId,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'post_id': postId,
      'user_id': userId,
      'type': type.name,
    };
  }

  factory Reaction.fromMap(Map<String, dynamic> map) {
    return Reaction(
      id: map['id'] as String?,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      type: ReactionType.fromString(map['type'] as String),
    );
  }
}

