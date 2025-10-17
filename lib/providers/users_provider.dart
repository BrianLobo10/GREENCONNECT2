import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/like.dart';
import '../services/firestore_service.dart';

class UsersProvider with ChangeNotifier {
  List<User> _users = [];
  List<String> _likedUserIds = [];
  bool _isLoading = false;

  List<User> get users => _users;
  List<String> get likedUserIds => _likedUserIds;
  bool get isLoading => _isLoading;

  final FirestoreService _firestore = FirestoreService.instance;

  // Cargar usuarios (excepto el usuario actual)
  Future<void> loadUsers(String currentUserId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await _firestore.getUsersExcept(currentUserId);
      await loadLikes(currentUserId);
    } catch (e) {
      debugPrint('Error loading users: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Cargar likes del usuario actual
  Future<void> loadLikes(String currentUserId) async {
    try {
      _likedUserIds = await _firestore.getLikedUserIds(currentUserId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading likes: $e');
    }
  }

  // Dar like a un usuario
  Future<void> likeUser(String currentUserId, String targetUserId) async {
    try {
      final hasLiked = await _firestore.hasLiked(currentUserId, targetUserId);
      
      if (hasLiked) {
        // Si ya le dio like, quitar el like
        await _firestore.deleteLike(currentUserId, targetUserId);
        _likedUserIds.remove(targetUserId);
      } else {
        // Si no le ha dado like, agregarlo
        final like = Like(
          idUsuario: currentUserId,
          idUsuarioLike: targetUserId,
        );
        await _firestore.createLike(like);
        _likedUserIds.add(targetUserId);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error liking user: $e');
    }
  }

  // Verificar si le dio like a un usuario
  bool hasLiked(String userId) {
    return _likedUserIds.contains(userId);
  }

  // Refrescar lista de usuarios
  Future<void> refreshUsers(String currentUserId) async {
    await loadUsers(currentUserId);
  }
}
