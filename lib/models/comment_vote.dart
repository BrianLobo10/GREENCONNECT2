enum VoteType {
  like,
  dislike;

  String get name {
    switch (this) {
      case VoteType.like:
        return 'like';
      case VoteType.dislike:
        return 'dislike';
    }
  }

  static VoteType fromString(String value) {
    switch (value) {
      case 'like':
        return VoteType.like;
      case 'dislike':
        return VoteType.dislike;
      default:
        return VoteType.like;
    }
  }
}

class CommentVote {
  final String? id;
  final String commentId;
  final String userId;
  final VoteType type;

  CommentVote({
    this.id,
    required this.commentId,
    required this.userId,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'comment_id': commentId,
      'user_id': userId,
      'type': type.name,
    };
  }

  factory CommentVote.fromMap(Map<String, dynamic> map) {
    return CommentVote(
      id: map['id'] as String?,
      commentId: map['comment_id'] as String,
      userId: map['user_id'] as String,
      type: VoteType.fromString(map['type'] as String),
    );
  }
}

