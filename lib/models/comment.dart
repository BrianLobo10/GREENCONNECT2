class Comment {
  final String? id;
  final String postId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String texto;
  final DateTime fecha;
  final int likes;
  final int dislikes;

  Comment({
    this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.texto,
    required this.fecha,
    this.likes = 0,
    this.dislikes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'post_id': postId,
      'user_id': userId,
      'user_name': userName,
      'user_photo': userPhoto,
      'texto': texto,
      'fecha': fecha.toIso8601String(),
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String?,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userPhoto: map['user_photo'] as String?,
      texto: map['texto'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      likes: map['likes'] as int? ?? 0,
      dislikes: map['dislikes'] as int? ?? 0,
    );
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userPhoto,
    String? texto,
    DateTime? fecha,
    int? likes,
    int? dislikes,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      texto: texto ?? this.texto,
      fecha: fecha ?? this.fecha,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
    );
  }
}

