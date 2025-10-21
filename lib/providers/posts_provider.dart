import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../models/reaction.dart';
import '../models/comment.dart';
import '../models/comment_vote.dart';
import '../services/firestore_service.dart';

class PostsProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;
  
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Cargar posts (usando stream)
  void loadPosts() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _firestoreService.getPostsStream().listen(
      (posts) {
        _posts = posts;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Crear post sin imagen
  Future<bool> createPost({
    required String userId,
    required String userName,
    String? userPhoto,
    required String contenido,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final post = Post(
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        contenido: contenido,
        fecha: DateTime.now(),
      );

      await _firestoreService.createPost(post);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Crear post con imagen
  Future<bool> createPostWithImage({
    required String userId,
    required String userName,
    String? userPhoto,
    required String contenido,
    required File imageFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final post = Post(
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        contenido: contenido,
        mediaType: MediaType.image,
        fecha: DateTime.now(),
      );

      await _firestoreService.createPostWithImage(post, imageFile);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Crear post con video
  Future<bool> createPostWithVideo({
    required String userId,
    required String userName,
    String? userPhoto,
    required String contenido,
    required File videoFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final post = Post(
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        contenido: contenido,
        mediaType: MediaType.video,
        fecha: DateTime.now(),
      );

      await _firestoreService.createPostWithVideo(post, videoFile);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Eliminar post
  Future<bool> deletePost(String postId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestoreService.deletePost(postId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Agregar o actualizar reacción
  Future<bool> addOrUpdateReaction({
    required String postId,
    required String userId,
    required ReactionType type,
  }) async {
    try {
      final reaction = Reaction(
        postId: postId,
        userId: userId,
        type: type,
      );

      await _firestoreService.addOrUpdateReaction(reaction);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Eliminar reacción
  Future<bool> removeReaction({
    required String postId,
    required String userId,
  }) async {
    try {
      await _firestoreService.removeReaction(postId, userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Obtener stream de reacciones de un post
  Stream<List<Reaction>> getPostReactionsStream(String postId) {
    return _firestoreService.getPostReactionsStream(postId);
  }

  /// Obtener reacción del usuario en un post
  Future<Reaction?> getUserReaction(String postId, String userId) {
    return _firestoreService.getUserReaction(postId, userId);
  }

  /// Crear comentario
  Future<bool> createComment({
    required String postId,
    required String userId,
    required String userName,
    String? userPhoto,
    required String texto,
  }) async {
    try {
      final comment = Comment(
        postId: postId,
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        texto: texto,
        fecha: DateTime.now(),
      );

      await _firestoreService.createComment(comment);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Obtener stream de comentarios de un post
  Stream<List<Comment>> getPostCommentsStream(String postId) {
    return _firestoreService.getPostCommentsStream(postId);
  }

  /// Eliminar comentario
  Future<bool> deleteComment(String commentId) async {
    try {
      await _firestoreService.deleteComment(commentId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Votar en un comentario
  Future<bool> voteComment({
    required String commentId,
    required String userId,
    required VoteType type,
  }) async {
    try {
      final vote = CommentVote(
        commentId: commentId,
        userId: userId,
        type: type,
      );

      await _firestoreService.addOrUpdateCommentVote(vote);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Obtener voto del usuario en un comentario
  Future<CommentVote?> getUserCommentVote(String commentId, String userId) {
    return _firestoreService.getUserCommentVote(commentId, userId);
  }

  /// Obtener posts de un usuario específico
  Stream<List<Post>> getUserPostsStream(String userId) {
    return _firestoreService.getUserPostsStream(userId);
  }

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

