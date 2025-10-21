enum NotificationType {
  reaction,
  comment,
  follow,
  mention;

  String get name {
    switch (this) {
      case NotificationType.reaction:
        return 'reaction';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.mention:
        return 'mention';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'reaction':
        return NotificationType.reaction;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      default:
        return NotificationType.comment;
    }
  }
}

class AppNotification {
  final String? id;
  final String userId; // A quien va dirigida
  final String fromUserId; // Quien la genera
  final String fromUserName;
  final String? fromUserPhoto;
  final NotificationType type;
  final String? postId; // Si es de una publicación
  final String? commentId; // Si es de un comentario
  final String message;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    this.id,
    required this.userId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPhoto,
    required this.type,
    this.postId,
    this.commentId,
    required this.message,
    this.read = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'from_user_id': fromUserId,
      'from_user_name': fromUserName,
      'from_user_photo': fromUserPhoto,
      'type': type.name,
      'post_id': postId,
      'comment_id': commentId,
      'message': message,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      fromUserId: map['from_user_id'] as String,
      fromUserName: map['from_user_name'] as String,
      fromUserPhoto: map['from_user_photo'] as String?,
      type: NotificationType.fromString(map['type'] as String),
      postId: map['post_id'] as String?,
      commentId: map['comment_id'] as String?,
      message: map['message'] as String,
      read: map['read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  AppNotification copyWith({
    String? id,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserPhoto: fromUserPhoto,
      type: type,
      postId: postId,
      commentId: commentId,
      message: message,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}

