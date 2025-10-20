enum ReactionType {
  feliz,        // carita feliz
  encantado,    // encantado/enamorado
  carcajada,    // risa a carcajadas
  cool,         // cool/genial
  enojado;      // enojado

  String get iconPath {
    switch (this) {
      case ReactionType.feliz:
        return 'assets/icon/feliz.png';
      case ReactionType.encantado:
        return 'assets/icon/encantado.png';
      case ReactionType.carcajada:
        return 'assets/icon/carcajada.png';
      case ReactionType.cool:
        return 'assets/icon/cool.png';
      case ReactionType.enojado:
        return 'assets/icon/enojado.png';
    }
  }

  String get name {
    switch (this) {
      case ReactionType.feliz:
        return 'feliz';
      case ReactionType.encantado:
        return 'encantado';
      case ReactionType.carcajada:
        return 'carcajada';
      case ReactionType.cool:
        return 'cool';
      case ReactionType.enojado:
        return 'enojado';
    }
  }

  static ReactionType fromString(String value) {
    switch (value) {
      case 'feliz':
        return ReactionType.feliz;
      case 'encantado':
        return ReactionType.encantado;
      case 'carcajada':
        return ReactionType.carcajada;
      case 'cool':
        return ReactionType.cool;
      case 'enojado':
        return ReactionType.enojado;
      // Mantener compatibilidad con datos antiguos
      case 'heart':
        return ReactionType.encantado;
      case 'like':
        return ReactionType.cool;
      case 'smile':
        return ReactionType.feliz;
      case 'angry':
        return ReactionType.enojado;
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

