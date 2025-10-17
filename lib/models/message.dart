import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? id;
  final String emisorId;
  final String receptorId;
  final String texto;
  final DateTime fecha;
  final String? imageUrl;

  Message({
    this.id,
    required this.emisorId,
    required this.receptorId,
    required this.texto,
    required this.fecha,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'emisor_id': emisorId,
      'receptor_id': receptorId,
      'texto': texto,
      'fecha': FieldValue.serverTimestamp(), // Usar timestamp del servidor
      'image_url': imageUrl,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    // Manejar timestamp de Firestore
    DateTime parsedDate;
    final fechaData = map['fecha'];
    
    if (fechaData is Timestamp) {
      parsedDate = fechaData.toDate();
    } else if (fechaData is String) {
      parsedDate = DateTime.parse(fechaData);
    } else {
      parsedDate = DateTime.now();
    }

    return Message(
      id: map['id'] as String?,
      emisorId: map['emisor_id'] as String,
      receptorId: map['receptor_id'] as String,
      texto: map['texto'] as String,
      fecha: parsedDate,
      imageUrl: map['image_url'] as String?,
    );
  }
}

