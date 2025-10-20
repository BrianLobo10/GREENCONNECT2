class Post {
  final String? id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String contenido;
  final String? imageUrl;
  final DateTime fecha;

  Post({
    this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.contenido,
    this.imageUrl,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_photo': userPhoto,
      'contenido': contenido,
      'image_url': imageUrl,
      'fecha': fecha.toIso8601String(),
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
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhoto,
    String? contenido,
    String? imageUrl,
    DateTime? fecha,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      contenido: contenido ?? this.contenido,
      imageUrl: imageUrl ?? this.imageUrl,
      fecha: fecha ?? this.fecha,
    );
  }
}

