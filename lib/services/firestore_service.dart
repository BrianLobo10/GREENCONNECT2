import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/like.dart';
import '../models/message.dart';
import '../models/post.dart';
import '../models/reaction.dart';
import '../models/comment.dart';
import '../models/comment_vote.dart';
import '../models/follow.dart';
import '../models/notification.dart';
import '../utils/text_utils.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirestoreService._init();

  // Colecciones
  CollectionReference get _usersCollection => _firestore.collection('usuarios');
  CollectionReference get _likesCollection => _firestore.collection('likes');
  CollectionReference get _messagesCollection => _firestore.collection('mensajes');
  CollectionReference get _postsCollection => _firestore.collection('posts');
  CollectionReference get _reactionsCollection => _firestore.collection('reactions');
  CollectionReference get _commentsCollection => _firestore.collection('comments');
  CollectionReference get _commentVotesCollection => _firestore.collection('comment_votes');
  CollectionReference get _followsCollection => _firestore.collection('follows');
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _storiesCollection => _firestore.collection('stories');

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

  /// Reenviar mensaje
  Future<void> forwardMessage(Message originalMessage, String newReceiverId) async {
    try {
      final forwardedMessage = Message(
        emisorId: originalMessage.emisorId,
        receptorId: newReceiverId,
        texto: originalMessage.texto,
        fecha: DateTime.now(),
        imageUrl: originalMessage.imageUrl,
        isForwarded: true,
        originalSenderId: originalMessage.originalSenderId ?? originalMessage.emisorId,
        originalSenderName: originalMessage.originalSenderName ?? originalMessage.emisorId,
        originalDate: originalMessage.originalDate ?? originalMessage.fecha,
      );
      
      await _messagesCollection.add(forwardedMessage.toMap());
    } catch (e) {
      throw Exception('Error al reenviar mensaje: $e');
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
        .orderBy('fecha', descending: false)
        .snapshots()
        .map((snapshot) {
          final messages = <Message>[];
          
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final emisorId = data['emisor_id'] as String?;
              final receptorId = data['receptor_id'] as String?;
              
              // Verificar que el mensaje es entre los dos usuarios
              if ((emisorId == user1Id && receptorId == user2Id) ||
                  (emisorId == user2Id && receptorId == user1Id)) {
                
                // Verificar si está oculto para el usuario actual
                final hiddenBy = data['hidden_by'] as List<dynamic>? ?? [];
                if (!hiddenBy.contains(user1Id)) {
                  final message = Message.fromMap({
                    ...data,
                    'id': doc.id,
                  });
                  messages.add(message);
                }
              }
            } catch (e) {
              debugPrint('Error procesando mensaje ${doc.id}: $e');
              continue;
            }
          }
          
          // Ordenar por fecha
          messages.sort((a, b) => a.fecha.compareTo(b.fecha));
          debugPrint('Stream actualizado: ${messages.length} mensajes para $user1Id <-> $user2Id');
          return messages;
        })
        .handleError((error) {
          debugPrint('Error en stream de mensajes: $error');
          return <Message>[];
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
          .where((msg) {
            // Filtrar mensajes entre los dos usuarios
            final isBetweenUsers = (msg.emisorId == user1Id && msg.receptorId == user2Id) ||
                                  (msg.emisorId == user2Id && msg.receptorId == user1Id);
            
            if (!isBetweenUsers) return false;
            
            // Filtrar mensajes ocultos para el usuario actual
            final hiddenBy = (msg as dynamic).hiddenBy as List<dynamic>? ?? [];
            return !hiddenBy.contains(user1Id);
          })
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

  /// Obtener usuarios con los que el usuario actual tiene chats
  Future<List<User>> getChatUsers(String currentUserId) async {
    try {
      // Obtener todos los mensajes donde el usuario es emisor o receptor
      final sentMessages = await _messagesCollection
          .where('emisor_id', isEqualTo: currentUserId)
          .get();
      
      final receivedMessages = await _messagesCollection
          .where('receptor_id', isEqualTo: currentUserId)
          .get();

      // Recopilar IDs únicos de usuarios
      final Set<String> userIds = {};
      
      for (final doc in sentMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final receiverId = data['receptor_id'] as String;
        if (receiverId != currentUserId) {
          userIds.add(receiverId);
        }
      }
      
      for (final doc in receivedMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['emisor_id'] as String;
        if (senderId != currentUserId) {
          userIds.add(senderId);
        }
      }

      // Obtener datos de usuarios
      final List<User> users = [];
      for (final userId in userIds) {
        final user = await getUserById(userId);
        if (user != null) {
          users.add(user);
        }
      }

      // Ordenar por nombre
      users.sort((a, b) => a.nombre.compareTo(b.nombre));
      
      return users;
    } catch (e) {
      throw Exception('Error al obtener usuarios de chat: $e');
    }
  }

  /// Vaciar mensajes de un chat (solo para el usuario actual)
  Future<void> clearChatMessages(String currentUserId, String otherUserId) async {
    try {
      // Obtener todos los mensajes entre los dos usuarios
      final querySnapshot = await _messagesCollection.get();
      
      final messagesToDelete = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final emisorId = data['emisor_id'] as String;
        final receptorId = data['receptor_id'] as String;
        
        return (emisorId == currentUserId && receptorId == otherUserId) ||
               (emisorId == otherUserId && receptorId == currentUserId);
      }).toList();

      // En lugar de eliminar, marcar como ocultos para el usuario actual
      for (final doc in messagesToDelete) {
        final data = doc.data() as Map<String, dynamic>;
        final hiddenBy = data['hidden_by'] as List<dynamic>? ?? [];
        
        // Agregar el usuario actual a la lista de usuarios que ocultaron el mensaje
        if (!hiddenBy.contains(currentUserId)) {
          hiddenBy.add(currentUserId);
          await doc.reference.update({
            'hidden_by': hiddenBy,
          });
        }
      }
    } catch (e) {
      throw Exception('Error al vaciar mensajes del chat: $e');
    }
  }

  // ==================== POSTS ====================

  /// Subir imagen de post a Firebase Storage
  Future<String> uploadPostImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('post_images/$userId/$fileName');
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir imagen de post: $e');
    }
  }

  /// Subir video de post a Firebase Storage
  Future<String> uploadPostVideo(File videoFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child('post_videos/$userId/$fileName');
      
      final uploadTask = await ref.putFile(videoFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir video de post: $e');
    }
  }

  /// Crear post
  Future<String> createPost(Post post) async {
    try {
      // Extraer hashtags y menciones
      final hashtags = TextUtils.extractHashtags(post.contenido);
      final mentions = TextUtils.extractMentions(post.contenido);
      
      final postWithExtras = post.copyWith(
        hashtags: hashtags,
        mentions: mentions,
      );
      
      final docRef = await _postsCollection.add(postWithExtras.toMap());
      
      // Notificar a usuarios mencionados
      for (var mention in mentions) {
        final users = await searchUsers(mention);
        for (var user in users) {
          if (user.id != null && user.id != post.userId) {
            await _createNotification(
              userId: user.id!,
              fromUserId: post.userId,
              type: NotificationType.mention,
              message: 'te mencionó en una publicación',
              postId: docRef.id,
            );
          }
        }
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear post: $e');
    }
  }

  /// Crear post con imagen
  Future<String> createPostWithImage(Post post, File imageFile) async {
    try {
      // Subir imagen primero
      final imageUrl = await uploadPostImage(imageFile, post.userId);
      
      // Extraer hashtags y menciones
      final hashtags = TextUtils.extractHashtags(post.contenido);
      final mentions = TextUtils.extractMentions(post.contenido);
      
      // Crear post con URL de imagen
      final postWithImage = post.copyWith(
        imageUrl: imageUrl,
        mediaType: MediaType.image,
        hashtags: hashtags,
        mentions: mentions,
      );
      
      final docRef = await _postsCollection.add(postWithImage.toMap());
      
      // Notificar a usuarios mencionados
      for (var mention in mentions) {
        final users = await searchUsers(mention);
        for (var user in users) {
          if (user.id != null && user.id != post.userId) {
            await _createNotification(
              userId: user.id!,
              fromUserId: post.userId,
              type: NotificationType.mention,
              message: 'te mencionó en una publicación',
              postId: docRef.id,
            );
          }
        }
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear post con imagen: $e');
    }
  }

  /// Crear post con video
  Future<String> createPostWithVideo(Post post, File videoFile) async {
    try {
      // Subir video primero
      final videoUrl = await uploadPostVideo(videoFile, post.userId);
      
      // Extraer hashtags y menciones
      final hashtags = TextUtils.extractHashtags(post.contenido);
      final mentions = TextUtils.extractMentions(post.contenido);
      
      // Crear post con URL de video
      final postWithVideo = post.copyWith(
        videoUrl: videoUrl,
        mediaType: MediaType.video,
        hashtags: hashtags,
        mentions: mentions,
      );
      
      final docRef = await _postsCollection.add(postWithVideo.toMap());
      
      // Notificar a usuarios mencionados
      for (var mention in mentions) {
        final users = await searchUsers(mention);
        for (var user in users) {
          if (user.id != null && user.id != post.userId) {
            await _createNotification(
              userId: user.id!,
              fromUserId: post.userId,
              type: NotificationType.mention,
              message: 'te mencionó en una publicación',
              postId: docRef.id,
            );
          }
        }
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear post con video: $e');
    }
  }

  /// Obtener todos los posts (stream para tiempo real)
  Stream<List<Post>> getPostsStream() {
    return _postsCollection
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map((doc) => Post.fromMap({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }))
              .toList();
          
          // Ordenar en cliente para evitar necesidad de índice
          posts.sort((a, b) => b.fecha.compareTo(a.fecha));
          return posts;
        });
  }

  /// Obtener posts de un usuario específico
  Stream<List<Post>> getUserPostsStream(String userId) {
    return _postsCollection
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map((doc) => Post.fromMap({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }))
              .toList();
          
          // Ordenar en cliente para evitar necesidad de índice
          posts.sort((a, b) => b.fecha.compareTo(a.fecha));
          return posts;
        });
  }

  /// Obtener un post específico por ID
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();
      if (doc.exists) {
        return Post.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener post: $e');
    }
  }

  /// Obtener contador de mensajes no leídos
  Stream<int> getUnreadMessagesCount(String userId) {
    return _messagesCollection
        .where('receptor_id', isEqualTo: userId)
        .where('leido', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Marcar mensajes como leídos
  Future<void> markMessagesAsRead(String userId, String otherUserId) async {
    try {
      final query = await _messagesCollection
          .where('emisor_id', isEqualTo: otherUserId)
          .where('receptor_id', isEqualTo: userId)
          .where('leido', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'leido': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error marcando mensajes como leídos: $e');
    }
  }


  /// Actualizar post
  Future<void> updatePost(Post post) async {
    try {
      if (post.id == null) throw Exception('ID de post no puede ser null');
      await _postsCollection.doc(post.id).update(post.toMap());
    } catch (e) {
      throw Exception('Error al actualizar post: $e');
    }
  }

  /// Eliminar post
  Future<void> deletePost(String postId) async {
    try {
      // Eliminar post
      await _postsCollection.doc(postId).delete();
      
      // Eliminar reacciones asociadas
      final reactions = await _reactionsCollection
          .where('post_id', isEqualTo: postId)
          .get();
      for (var doc in reactions.docs) {
        await doc.reference.delete();
      }
      
      // Eliminar comentarios asociados
      final comments = await _commentsCollection
          .where('post_id', isEqualTo: postId)
          .get();
      for (var doc in comments.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error al eliminar post: $e');
    }
  }

  // ==================== REACTIONS ====================

  /// Agregar o actualizar reacción a un post
  Future<String> addOrUpdateReaction(Reaction reaction) async {
    try {
      // Buscar si ya existe una reacción del usuario en este post
      final querySnapshot = await _reactionsCollection
          .where('post_id', isEqualTo: reaction.postId)
          .where('user_id', isEqualTo: reaction.userId)
          .limit(1)
          .get();

      String docId;
      bool isNew = false;

      if (querySnapshot.docs.isNotEmpty) {
        // Si ya existe, actualizar
        docId = querySnapshot.docs.first.id;
        await _reactionsCollection.doc(docId).update(reaction.toMap());
      } else {
        // Si no existe, crear nueva
        final docRef = await _reactionsCollection.add(reaction.toMap());
        docId = docRef.id;
        isNew = true;
      }
      
      // Crear notificación solo si es nueva reacción
      if (isNew) {
        final post = await _postsCollection.doc(reaction.postId).get();
        if (post.exists) {
          final postData = post.data() as Map<String, dynamic>;
          final postOwnerId = postData['user_id'] as String;
          
          // No notificar si reaccionas tu propia publicación
          if (postOwnerId != reaction.userId) {
            await _createNotification(
              userId: postOwnerId,
              fromUserId: reaction.userId,
              type: NotificationType.reaction,
              message: 'reaccionó a tu publicación',
              postId: reaction.postId,
            );
          }
        }
      }
      
      return docId;
    } catch (e) {
      throw Exception('Error al agregar reacción: $e');
    }
  }

  /// Eliminar reacción
  Future<void> removeReaction(String postId, String userId) async {
    try {
      final querySnapshot = await _reactionsCollection
          .where('post_id', isEqualTo: postId)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error al eliminar reacción: $e');
    }
  }

  /// Obtener reacciones de un post (stream)
  Stream<List<Reaction>> getPostReactionsStream(String postId) {
    return _reactionsCollection
        .where('post_id', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Reaction.fromMap({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }))
              .toList();
        });
  }

  /// Obtener reacción del usuario en un post
  Future<Reaction?> getUserReaction(String postId, String userId) async {
    try {
      final querySnapshot = await _reactionsCollection
          .where('post_id', isEqualTo: postId)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Reaction.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener reacción del usuario: $e');
    }
  }

  // ==================== COMMENTS ====================

  /// Crear comentario
  Future<String> createComment(Comment comment) async {
    try {
      final docRef = await _commentsCollection.add(comment.toMap());
      
      // Crear notificación
      final post = await _postsCollection.doc(comment.postId).get();
      if (post.exists) {
        final postData = post.data() as Map<String, dynamic>;
        final postOwnerId = postData['user_id'] as String;
        
        // No notificar si comentas tu propia publicación
        if (postOwnerId != comment.userId) {
          await _createNotification(
            userId: postOwnerId,
            fromUserId: comment.userId,
            type: NotificationType.comment,
            message: 'comentó en tu publicación',
            postId: comment.postId,
            commentId: docRef.id,
          );
        }
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear comentario: $e');
    }
  }

  /// Obtener comentarios de un post (stream)
  Stream<List<Comment>> getPostCommentsStream(String postId) {
    return _commentsCollection
        .where('post_id', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs
              .map((doc) => Comment.fromMap({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }))
              .toList();
          
          // Ordenar en cliente para evitar necesidad de índice
          comments.sort((a, b) => a.fecha.compareTo(b.fecha));
          return comments;
        });
  }

  /// Actualizar comentario
  Future<void> updateComment(Comment comment) async {
    try {
      if (comment.id == null) throw Exception('ID de comentario no puede ser null');
      await _commentsCollection.doc(comment.id).update(comment.toMap());
    } catch (e) {
      throw Exception('Error al actualizar comentario: $e');
    }
  }

  /// Eliminar comentario
  Future<void> deleteComment(String commentId) async {
    try {
      await _commentsCollection.doc(commentId).delete();
      
      // Eliminar votos asociados
      final votes = await _commentVotesCollection
          .where('comment_id', isEqualTo: commentId)
          .get();
      for (var doc in votes.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error al eliminar comentario: $e');
    }
  }

  // ==================== COMMENT VOTES ====================

  /// Agregar o actualizar voto a un comentario
  Future<void> addOrUpdateCommentVote(CommentVote vote) async {
    try {
      // Buscar si ya existe un voto del usuario en este comentario
      final querySnapshot = await _commentVotesCollection
          .where('comment_id', isEqualTo: vote.commentId)
          .where('user_id', isEqualTo: vote.userId)
          .limit(1)
          .get();

      // Obtener el comentario actual
      final commentDoc = await _commentsCollection.doc(vote.commentId).get();
      if (!commentDoc.exists) throw Exception('Comentario no encontrado');
      
      final comment = Comment.fromMap({
        ...commentDoc.data() as Map<String, dynamic>,
        'id': commentDoc.id,
      });

      if (querySnapshot.docs.isNotEmpty) {
        // Ya existe un voto
        final existingVote = CommentVote.fromMap({
          ...querySnapshot.docs.first.data() as Map<String, dynamic>,
          'id': querySnapshot.docs.first.id,
        });

        if (existingVote.type == vote.type) {
          // Si es el mismo tipo, eliminar el voto
          await querySnapshot.docs.first.reference.delete();
          
          // Decrementar contador
          if (vote.type == VoteType.like) {
            await _commentsCollection.doc(vote.commentId).update({
              'likes': comment.likes - 1 < 0 ? 0 : comment.likes - 1,
            });
          } else {
            await _commentsCollection.doc(vote.commentId).update({
              'dislikes': comment.dislikes - 1 < 0 ? 0 : comment.dislikes - 1,
            });
          }
        } else {
          // Si es diferente tipo, actualizar
          await querySnapshot.docs.first.reference.update(vote.toMap());
          
          // Actualizar contadores
          if (vote.type == VoteType.like) {
            await _commentsCollection.doc(vote.commentId).update({
              'likes': comment.likes + 1,
              'dislikes': comment.dislikes - 1 < 0 ? 0 : comment.dislikes - 1,
            });
          } else {
            await _commentsCollection.doc(vote.commentId).update({
              'likes': comment.likes - 1 < 0 ? 0 : comment.likes - 1,
              'dislikes': comment.dislikes + 1,
            });
          }
        }
      } else {
        // No existe voto, crear nuevo
        await _commentVotesCollection.add(vote.toMap());
        
        // Incrementar contador
        if (vote.type == VoteType.like) {
          await _commentsCollection.doc(vote.commentId).update({
            'likes': comment.likes + 1,
          });
        } else {
          await _commentsCollection.doc(vote.commentId).update({
            'dislikes': comment.dislikes + 1,
          });
        }
      }
    } catch (e) {
      throw Exception('Error al agregar voto: $e');
    }
  }

  /// Obtener voto del usuario en un comentario
  Future<CommentVote?> getUserCommentVote(String commentId, String userId) async {
    try {
      final querySnapshot = await _commentVotesCollection
          .where('comment_id', isEqualTo: commentId)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return CommentVote.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener voto del usuario: $e');
    }
  }

  // ==================== FOLLOWS ====================

  /// Seguir a un usuario
  Future<void> followUser(String followerId, String followedId) async {
    try {
      final follow = Follow(
        followerId: followerId,
        followedId: followedId,
        createdAt: DateTime.now(),
      );
      await _followsCollection.add(follow.toMap());
      
      // Crear notificación
      await _createNotification(
        userId: followedId,
        fromUserId: followerId,
        type: NotificationType.follow,
        message: 'comenzó a seguirte',
      );
    } catch (e) {
      throw Exception('Error al seguir usuario: $e');
    }
  }

  /// Dejar de seguir a un usuario
  Future<void> unfollowUser(String followerId, String followedId) async {
    try {
      final querySnapshot = await _followsCollection
          .where('follower_id', isEqualTo: followerId)
          .where('followed_id', isEqualTo: followedId)
          .get();
      
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error al dejar de seguir: $e');
    }
  }

  /// Verificar si un usuario sigue a otro
  Future<bool> isFollowing(String followerId, String followedId) async {
    try {
      final querySnapshot = await _followsCollection
          .where('follower_id', isEqualTo: followerId)
          .where('followed_id', isEqualTo: followedId)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtener conteo de seguidores
  Future<int> getFollowersCount(String userId) async {
    try {
      final querySnapshot = await _followsCollection
          .where('followed_id', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtener conteo de seguidos
  Future<int> getFollowingCount(String userId) async {
    try {
      final querySnapshot = await _followsCollection
          .where('follower_id', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Stream de seguidos para feed personalizado
  Stream<List<String>> getFollowingIdsStream(String userId) {
    return _followsCollection
        .where('follower_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['followed_id'] as String)
            .toList());
  }

  /// Obtener posts de usuarios seguidos
  Stream<List<Post>> getFollowingPostsStream(String userId) {
    return getFollowingIdsStream(userId).asyncExpand((followingIds) {
      if (followingIds.isEmpty) {
        return Stream.value([]);
      }
      
      return _postsCollection
          .where('user_id', whereIn: followingIds)
          .snapshots()
          .map((snapshot) {
            final posts = snapshot.docs
                .map((doc) => Post.fromMap({
                      ...doc.data() as Map<String, dynamic>,
                      'id': doc.id,
                    }))
                .toList();
            
            posts.sort((a, b) => b.fecha.compareTo(a.fecha));
            return posts;
          });
    });
  }

  // ==================== NOTIFICACIONES ====================

  /// Crear notificación
  Future<void> _createNotification({
    required String userId,
    required String fromUserId,
    required NotificationType type,
    required String message,
    String? postId,
    String? commentId,
  }) async {
    try {
      // Solo crear notificaciones para tipos específicos
      if (type != NotificationType.reaction && 
          type != NotificationType.follow && 
          type != NotificationType.comment) {
        return;
      }

      // Obtener datos del usuario que genera la notificación
      final fromUser = await getUserById(fromUserId);
      
      final notification = AppNotification(
        userId: userId,
        fromUserId: fromUserId,
        fromUserName: fromUser?.nombre ?? 'Usuario',
        fromUserPhoto: fromUser?.foto,
        type: type,
        message: message,
        postId: postId,
        commentId: commentId,
        createdAt: DateTime.now(),
      );
      
      await _notificationsCollection.add(notification.toMap());
    } catch (e) {
      // No fallar si falla la notificación
      debugPrint('Error creando notificación: $e');
    }
  }

  /// Stream de notificaciones (solo últimas 10)
  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _notificationsCollection
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }))
            .toList());
  }

  /// Cargar más notificaciones (paginación)
  Future<List<AppNotification>> loadMoreNotifications(String userId, DocumentSnapshot? lastDoc) async {
    Query query = _notificationsCollection
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(10);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => AppNotification.fromMap({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    })).toList();
  }

  /// Contar notificaciones no leídas
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('user_id', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Marcar notificación como leída
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({'read': true});
    } catch (e) {
      throw Exception('Error al marcar notificación: $e');
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('user_id', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      
      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      throw Exception('Error al marcar notificaciones: $e');
    }
  }

  // ==================== POSTS GUARDADOS ====================

  /// Guardar/desmarcar publicación (sistema simplificado)
  Future<void> toggleSavePost(String userId, String postId) async {
    try {
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) return;
      
      final postData = postDoc.data() as Map<String, dynamic>;
      final savedByUsers = List<String>.from(postData['saved_by_users'] ?? []);
      
      if (savedByUsers.contains(userId)) {
        // Desmarcar
        savedByUsers.remove(userId);
      } else {
        // Marcar
        savedByUsers.add(userId);
      }
      
      await _postsCollection.doc(postId).update({
        'saved_by_users': savedByUsers,
      });
    } catch (e) {
      throw Exception('Error al guardar/desmarcar publicación: $e');
    }
  }

  /// Verificar si un post está guardado
  Future<bool> isPostSaved(String userId, String postId) async {
    try {
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) return false;
      
      final postData = postDoc.data() as Map<String, dynamic>;
      final savedByUsers = List<String>.from(postData['saved_by_users'] ?? []);
      
      return savedByUsers.contains(userId);
    } catch (e) {
      return false;
    }
  }

  /// Obtener publicaciones guardadas
  Stream<List<Post>> getSavedPostsStream(String userId) {
    return _postsCollection
        .where('saved_by_users', arrayContains: userId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }))
            .toList());
  }

  // ==================== EDITAR POST ====================

  /// Editar publicación
  Future<void> editPost(String postId, String newContent) async {
    try {
      await _postsCollection.doc(postId).update({
        'contenido': newContent,
        'edited_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al editar publicación: $e');
    }
  }

  // ==================== ESTADO ONLINE ====================

  /// Actualizar estado online
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _usersCollection.doc(userId).update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  // ==================== BÚSQUEDA ====================

  /// Buscar usuarios por nombre
  Future<List<User>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final querySnapshot = await _usersCollection.get();
      final users = querySnapshot.docs
          .map((doc) => User.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .where((user) => user.nombre.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      return users;
    } catch (e) {
      throw Exception('Error al buscar usuarios: $e');
    }
  }

  /// Buscar publicaciones por contenido o hashtags
  Future<List<Post>> searchPosts(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final querySnapshot = await _postsCollection.get();
      final posts = querySnapshot.docs
          .map((doc) => Post.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .where((post) =>
              post.contenido.toLowerCase().contains(query.toLowerCase()) ||
              post.hashtags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
      
      posts.sort((a, b) => b.fecha.compareTo(a.fecha));
      return posts;
    } catch (e) {
      throw Exception('Error al buscar publicaciones: $e');
    }
  }

  /// Buscar por hashtag específico
  Future<List<Post>> searchByHashtag(String hashtag) async {
    try {
      final cleanHashtag = hashtag.replaceAll('#', '').toLowerCase();
      
      final querySnapshot = await _postsCollection
          .where('hashtags', arrayContains: cleanHashtag)
          .get();
      
      final posts = querySnapshot.docs
          .map((doc) => Post.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
      
      posts.sort((a, b) => b.fecha.compareTo(a.fecha));
      return posts;
    } catch (e) {
      throw Exception('Error al buscar por hashtag: $e');
    }
  }

  /// Obtener IDs de seguidores de un usuario
  Future<List<String>> getFollowersIds(String userId) async {
    try {
      final querySnapshot = await _followsCollection
          .where('followed_id', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['follower_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener IDs de usuarios que sigue un usuario
  Future<List<String>> getFollowingIds(String userId) async {
    try {
      final querySnapshot = await _followsCollection
          .where('follower_id', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['followed_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Crear una nueva historia
  Future<void> createStory(
    String userId,
    String userName,
    String userPhoto,
    String imageUrl,
  ) async {
    try {
      await _storiesCollection.add({
        'user_id': userId,
        'user_name': userName,
        'user_photo': userPhoto,
        'image_url': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
      });
    } catch (e) {
      throw Exception('Error al crear historia: $e');
    }
  }

  /// Obtener historias no expiradas
  Future<List<Map<String, dynamic>>> getStories() async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('expires_at', isGreaterThan: DateTime.now())
          .orderBy('expires_at')
          .get();
      
      return snapshot.docs.map((doc) => {
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      }).toList();
    } catch (e) {
      return [];
    }
  }
}


