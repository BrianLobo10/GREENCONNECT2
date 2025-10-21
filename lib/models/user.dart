class User {
  final String? id;
  final String nombre;
  final String email;
  final String contrasena;
  final int edad;
  final String intereses;
  final String? foto;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? bio;

  User({
    this.id,
    required this.nombre,
    required this.email,
    required this.contrasena,
    required this.edad,
    required this.intereses,
    this.foto,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.bio,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'nombre': nombre,
      'email': email,
      'contrasena': contrasena,
      'edad': edad,
      'intereses': intereses,
      'foto': foto,
      'is_verified': isVerified,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'bio': bio,
    };
    // No incluir ID en el map para Firestore
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String?,
      nombre: map['nombre'] as String,
      email: map['email'] as String,
      contrasena: map['contrasena'] as String,
      edad: map['edad'] as int,
      intereses: map['intereses'] as String,
      foto: map['foto'] as String?,
      isVerified: map['is_verified'] as bool? ?? false,
      isOnline: map['is_online'] as bool? ?? false,
      lastSeen: map['last_seen'] != null ? DateTime.parse(map['last_seen'] as String) : null,
      bio: map['bio'] as String?,
    );
  }

  User copyWith({
    String? id,
    String? nombre,
    String? email,
    String? contrasena,
    int? edad,
    String? intereses,
    String? foto,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
    String? bio,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      contrasena: contrasena ?? this.contrasena,
      edad: edad ?? this.edad,
      intereses: intereses ?? this.intereses,
      foto: foto ?? this.foto,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      bio: bio ?? this.bio,
    );
  }
}


