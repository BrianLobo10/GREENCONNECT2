import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user.dart';
import '../models/like.dart';
import '../models/message.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirestoreService._init();

  // Colecciones
  CollectionReference get _usersCollection => _firestore.collection('usuarios');
  CollectionReference get _likesCollection => _firestore.collection('likes');
  CollectionReference get _messagesCollection => _firestore.collection('mensajes');

  // ==================== USUARIOS ====================

  /// Crear usuario
  Future<String> createUser(User user) async {
    try {
      final docRef = await _usersCollection.add(user.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  /// Obtener usuario por email
  Future<User?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return User.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario por email: $e');
    }
  }

  /// Obtener usuario por ID
  Future<User?> getUserById(String id) async {
    try {
      final doc = await _usersCollection.doc(id).get();
      if (doc.exists) {
        return User.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario por ID: $e');
    }
  }

  /// Obtener todos los usuarios excepto el actual
  Future<List<User>> getUsersExcept(String userId) async {
    try {
      final querySnapshot = await _usersCollection.get();
      final users = <User>[];

      for (var doc in querySnapshot.docs) {
        if (doc.id != userId) {
          users.add(User.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}));
        }
      }

      return users;
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  /// Actualizar usuario
  Future<void> updateUser(User user) async {
    try {
      if (user.id == null) throw Exception('ID de usuario no puede ser null');
      await _usersCollection.doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  /// Obtener cantidad de likes recibidos por un usuario
  Future<int> getUserLikesCount(String userId) async {
    try {
      final querySnapshot = await _likesCollection
          .where('id_usuario_like', isEqualTo: userId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Error al obtener contador de likes: $e');
    }
  }

  // ==================== LIKES ====================

  /// Crear like
  Future<String> createLike(Like like) async {
    try {
      final docRef = await _likesCollection.add(like.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear like: $e');
    }
  }

  /// Verificar si un usuario le dio like a otro
  Future<bool> hasLiked(String userId, String targetUserId) async {
    try {
      final querySnapshot = await _likesCollection
          .where('id_usuario', isEqualTo: userId)
          .where('id_usuario_like', isEqualTo: targetUserId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar like: $e');
    }
  }

  /// Obtener IDs de usuarios que le dieron like al usuario actual
  Future<List<String>> getLikedUserIds(String userId) async {
    try {
      final querySnapshot = await _likesCollection
          .where('id_usuario', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['id_usuario_like'] as String)
          .toList();
    } catch (e) {
      throw Exception('Error al obtener likes: $e');
    }
  }

  /// Eliminar like
  Future<void> deleteLike(String userId, String targetUserId) async {
    try {
      final querySnapshot = await _likesCollection
          .where('id_usuario', isEqualTo: userId)
          .where('id_usuario_like', isEqualTo: targetUserId)
          .limit(1)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error al eliminar like: $e');
    }
  }

  // ==================== MENSAJES ====================

  /// Subir imagen a Firebase Storage
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('chat_images/$userId/$fileName');
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Enviar mensaje
  Future<String> sendMessage(Message message) async {
    try {
      final docRef = await _messagesCollection.add(message.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  /// Enviar mensaje con imagen
  Future<String> sendMessageWithImage(Message message, File imageFile) async {
    try {
      // Subir imagen primero
      final imageUrl = await uploadImage(imageFile, message.emisorId);
      
      // Crear mensaje con URL de imagen
      final messageWithImage = Message(
        emisorId: message.emisorId,
        receptorId: message.receptorId,
        texto: message.texto,
        fecha: message.fecha,
        imageUrl: imageUrl,
      );
      
      final docRef = await _messagesCollection.add(messageWithImage.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al enviar mensaje con imagen: $e');
    }
  }

  /// Obtener mensajes entre dos usuarios (tiempo real)
  Stream<List<Message>> getMessagesStream(String user1Id, String user2Id) {
    return _messagesCollection
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromMap({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }))
              .where((msg) =>
                  (msg.emisorId == user1Id && msg.receptorId == user2Id) ||
                  (msg.emisorId == user2Id && msg.receptorId == user1Id))
              .toList()
            ..sort((a, b) => a.fecha.compareTo(b.fecha));
        });
  }

  /// Obtener mensajes entre dos usuarios (una vez)
  Future<List<Message>> getMessages(String user1Id, String user2Id) async {
    try {
      // Query sin whereIn para evitar necesidad de índices
      final querySnapshot = await _messagesCollection.get();

      final messages = querySnapshot.docs
          .map((doc) => Message.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .where((msg) =>
              (msg.emisorId == user1Id && msg.receptorId == user2Id) ||
              (msg.emisorId == user2Id && msg.receptorId == user1Id))
          .toList();
      
      // Ordenar por fecha
      messages.sort((a, b) => a.fecha.compareTo(b.fecha));
      
      return messages;
    } catch (e) {
      throw Exception('Error al obtener mensajes: $e');
    }
  }

  /// Obtener IDs de usuarios con los que has chateado
  Future<List<String>> getConversationUserIds(String userId) async {
    try {
      final sentMessages = await _messagesCollection
          .where('emisor_id', isEqualTo: userId)
          .get();

      final receivedMessages = await _messagesCollection
          .where('receptor_id', isEqualTo: userId)
          .get();

      final userIds = <String>{};

      for (var doc in sentMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        userIds.add(data['receptor_id'] as String);
      }

      for (var doc in receivedMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        userIds.add(data['emisor_id'] as String);
      }

      return userIds.toList();
    } catch (e) {
      throw Exception('Error al obtener conversaciones: $e');
    }
  }

  /// Obtener último mensaje entre dos usuarios
  Future<Message?> getLastMessage(String user1Id, String user2Id) async {
    try {
      // Obtener todos los mensajes y filtrar en cliente para evitar índices
      final querySnapshot = await _messagesCollection.get();

      final messages = querySnapshot.docs
          .map((doc) => Message.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .where((msg) =>
              (msg.emisorId == user1Id && msg.receptorId == user2Id) ||
              (msg.emisorId == user2Id && msg.receptorId == user1Id))
          .toList();

      if (messages.isEmpty) return null;

      // Ordenar por fecha descendente y tomar el primero
      messages.sort((a, b) => b.fecha.compareTo(a.fecha));
      return messages.first;
    } catch (e) {
      throw Exception('Error al obtener último mensaje: $e');
    }
  }

  /// Eliminar mensaje
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messagesCollection.doc(messageId).delete();
    } catch (e) {
      throw Exception('Error al eliminar mensaje: $e');
    }
  }
}

