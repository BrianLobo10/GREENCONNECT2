import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user.dart';
import '../models/like.dart';
import '../models/message.dart';
import '../models/post.dart';
import '../models/reaction.dart';
import '../models/comment.dart';
import '../models/comment_vote.dart';

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

  /// Crear post
  Future<String> createPost(Post post) async {
    try {
      final docRef = await _postsCollection.add(post.toMap());
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
      
      // Crear post con URL de imagen
      final postWithImage = post.copyWith(imageUrl: imageUrl);
      
      final docRef = await _postsCollection.add(postWithImage.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear post con imagen: $e');
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

  /// Obtener un post por ID
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();
      if (doc.exists) {
        return Post.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener post: $e');
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

      if (querySnapshot.docs.isNotEmpty) {
        // Si ya existe, actualizar
        final docId = querySnapshot.docs.first.id;
        await _reactionsCollection.doc(docId).update(reaction.toMap());
        return docId;
      } else {
        // Si no existe, crear nueva
        final docRef = await _reactionsCollection.add(reaction.toMap());
        return docRef.id;
      }
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
}

