import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? id;
  final String emisorId;
  final String receptorId;
  final String texto;
  final DateTime fecha;
  final String? imageUrl;
  final bool isForwarded;
  final String? originalSenderId;
  final String? originalSenderName;
  final DateTime? originalDate;
  final bool leido;

  Message({
    this.id,
    required this.emisorId,
    required this.receptorId,
    required this.texto,
    required this.fecha,
    this.imageUrl,
    this.isForwarded = false,
    this.originalSenderId,
    this.originalSenderName,
    this.originalDate,
    this.leido = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'emisor_id': emisorId,
      'receptor_id': receptorId,
      'texto': texto,
      'fecha': FieldValue.serverTimestamp(), // Usar timestamp del servidor
      'image_url': imageUrl,
      'is_forwarded': isForwarded,
      'original_sender_id': originalSenderId,
      'original_sender_name': originalSenderName,
      'original_date': originalDate != null ? Timestamp.fromDate(originalDate!) : null,
      'leido': leido,
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

    // Manejar fecha original
    DateTime? parsedOriginalDate;
    final originalDateData = map['original_date'];
    if (originalDateData is Timestamp) {
      parsedOriginalDate = originalDateData.toDate();
    } else if (originalDateData is String) {
      parsedOriginalDate = DateTime.parse(originalDateData);
    }

    return Message(
      id: map['id'] as String?,
      emisorId: map['emisor_id'] as String,
      receptorId: map['receptor_id'] as String,
      texto: map['texto'] as String,
      fecha: parsedDate,
      imageUrl: map['image_url'] as String?,
      isForwarded: map['is_forwarded'] as bool? ?? false,
      originalSenderId: map['original_sender_id'] as String?,
      originalSenderName: map['original_sender_name'] as String?,
      originalDate: parsedOriginalDate,
      leido: map['leido'] as bool? ?? false,
    );
  }
}

