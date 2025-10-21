class Story {
  final String? id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String? imageUrl;
  final String? videoUrl;
  final String? text;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers; // IDs de usuarios que vieron la historia

  Story({
    this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    this.imageUrl,
    this.videoUrl,
    this.text,
    required this.createdAt,
    required this.expiresAt,
    this.viewers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_photo': userPhoto,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'viewers': viewers,
    };
  }

  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userPhoto: map['user_photo'] as String?,
      imageUrl: map['image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      text: map['text'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      viewers: map['viewers'] != null 
          ? List<String>.from(map['viewers'] as List)
          : [],
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasText => text != null && text!.isNotEmpty;
}
