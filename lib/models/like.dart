class Like {
  final String? id;
  final String idUsuario;
  final String idUsuarioLike;

  Like({
    this.id,
    required this.idUsuario,
    required this.idUsuarioLike,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'id_usuario_like': idUsuarioLike,
    };
  }

  factory Like.fromMap(Map<String, dynamic> map) {
    return Like(
      id: map['id'] as String?,
      idUsuario: map['id_usuario'] as String,
      idUsuarioLike: map['id_usuario_like'] as String,
    );
  }
}

