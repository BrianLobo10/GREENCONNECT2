class User {
  final String? id;
  final String nombre;
  final String email;
  final String contrasena;
  final int edad;
  final String intereses;
  final String? foto;

  User({
    this.id,
    required this.nombre,
    required this.email,
    required this.contrasena,
    required this.edad,
    required this.intereses,
    this.foto,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'nombre': nombre,
      'email': email,
      'contrasena': contrasena,
      'edad': edad,
      'intereses': intereses,
      'foto': foto,
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
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      contrasena: contrasena ?? this.contrasena,
      edad: edad ?? this.edad,
      intereses: intereses ?? this.intereses,
      foto: foto ?? this.foto,
    );
  }
}

