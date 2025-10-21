enum MediaType {
  none,
  image,
  video;

  String get name {
    switch (this) {
      case MediaType.none:
        return 'none';
      case MediaType.image:
        return 'image';
      case MediaType.video:
        return 'video';
    }
  }

  static MediaType fromString(String value) {
    switch (value) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      default:
        return MediaType.none;
    }
  }
}

class Post {
  final String? id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String contenido;
  final String? imageUrl;
  final String? videoUrl;
  final List<String>? imageUrls; // Para carrusel
  final MediaType mediaType;
  final DateTime fecha;
  final DateTime? editedAt;
  final List<String> hashtags;
  final List<String> mentions;
  final String? sharedFromPostId; // Si es un repost
  final String? sharedFromUserName;
  final List<String> savedByUsers; // Usuarios que guardaron el post

  Post({
    this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.contenido,
    this.imageUrl,
    this.videoUrl,
    this.imageUrls,
    this.mediaType = MediaType.none,
    required this.fecha,
    this.editedAt,
        this.hashtags = const [],
        this.mentions = const [],
        this.sharedFromPostId,
        this.sharedFromUserName,
        this.savedByUsers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_photo': userPhoto,
      'contenido': contenido,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'image_urls': imageUrls,
      'media_type': mediaType.name,
      'fecha': fecha.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
            'hashtags': hashtags,
            'mentions': mentions,
            'shared_from_post_id': sharedFromPostId,
            'shared_from_user_name': sharedFromUserName,
            'saved_by_users': savedByUsers,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userPhoto: map['user_photo'] as String?,
      contenido: map['contenido'] as String,
      imageUrl: map['image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      imageUrls: map['image_urls'] != null 
          ? List<String>.from(map['image_urls'] as List)
          : null,
      mediaType: MediaType.fromString(map['media_type'] as String? ?? 'none'),
      fecha: DateTime.parse(map['fecha'] as String),
      editedAt: map['edited_at'] != null ? DateTime.parse(map['edited_at'] as String) : null,
      hashtags: map['hashtags'] != null 
          ? List<String>.from(map['hashtags'] as List)
          : [],
            mentions: map['mentions'] != null 
                ? List<String>.from(map['mentions'] as List)
                : [],
            sharedFromPostId: map['shared_from_post_id'] as String?,
            sharedFromUserName: map['shared_from_user_name'] as String?,
            savedByUsers: map['saved_by_users'] != null 
                ? List<String>.from(map['saved_by_users'] as List)
                : [],
    );
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhoto,
    String? contenido,
    String? imageUrl,
    String? videoUrl,
    List<String>? imageUrls,
    MediaType? mediaType,
    DateTime? fecha,
    DateTime? editedAt,
          List<String>? hashtags,
          List<String>? mentions,
          String? sharedFromPostId,
          String? sharedFromUserName,
          List<String>? savedByUsers,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      contenido: contenido ?? this.contenido,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      mediaType: mediaType ?? this.mediaType,
      fecha: fecha ?? this.fecha,
      editedAt: editedAt ?? this.editedAt,
            hashtags: hashtags ?? this.hashtags,
            mentions: mentions ?? this.mentions,
            sharedFromPostId: sharedFromPostId ?? this.sharedFromPostId,
            sharedFromUserName: sharedFromUserName ?? this.sharedFromUserName,
            savedByUsers: savedByUsers ?? this.savedByUsers,
    );
  }

  bool get isEdited => editedAt != null;
  bool get isShared => sharedFromPostId != null;
}

