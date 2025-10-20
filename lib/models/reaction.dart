enum ReactionType {
  feliz,        // carita feliz
  cool,         // cool/genial
  enojado,      // enojado
  triste,       // triste
  sorprendido;  // sorprendido

  String get iconPath {
    switch (this) {
      case ReactionType.feliz:
        return 'assets/icon/Feliz.png';
      case ReactionType.cool:
        return 'assets/icon/Cool.png';
      case ReactionType.enojado:
        return 'assets/icon/Enojado.png';
      case ReactionType.triste:
        return 'assets/icon/Triste.png';
      case ReactionType.sorprendido:
        return 'assets/icon/Sorprendido.png';
    }
  }

  String get name {
    switch (this) {
      case ReactionType.feliz:
        return 'feliz';
      case ReactionType.cool:
        return 'cool';
      case ReactionType.enojado:
        return 'enojado';
      case ReactionType.triste:
        return 'triste';
      case ReactionType.sorprendido:
        return 'sorprendido';
    }
  }

  static ReactionType fromString(String value) {
    switch (value) {
      case 'feliz':
        return ReactionType.feliz;
      case 'cool':
        return ReactionType.cool;
      case 'enojado':
        return ReactionType.enojado;
      case 'triste':
        return ReactionType.triste;
      case 'sorprendido':
        return ReactionType.sorprendido;
      // Mantener compatibilidad con datos antiguos
      case 'encantado':
      case 'heart':
        return ReactionType.feliz;
      case 'like':
        return ReactionType.cool;
      case 'smile':
        return ReactionType.feliz;
      case 'angry':
        return ReactionType.enojado;
      case 'carcajada':
        return ReactionType.feliz;
      default:
        return ReactionType.feliz;
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

