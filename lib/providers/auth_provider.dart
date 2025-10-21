import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  int _likesCount = 0;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  int get likesCount => _likesCount;

  final FirestoreService _firestore = FirestoreService.instance;
  final NotificationService _notificationService = NotificationService();

  // Cargar usuario guardado al iniciar la app
  Future<void> loadSavedUser() async {
    _isLoading = true;
    notifyListeners();
    
    // Inicializar notificaciones
    await _notificationService.initialize();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null) {
        _currentUser = await _firestore.getUserById(userId);
        if (_currentUser != null) {
          await _loadLikesCount();
          
          // Guardar token FCM para notificaciones
          await _notificationService.saveFCMToken(_currentUser!.id!);
        }
      }
    } catch (e) {
      debugPrint('Error loading saved user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Cargar contador de likes
  Future<void> _loadLikesCount() async {
    if (_currentUser?.id != null) {
      try {
        _likesCount = await _firestore.getUserLikesCount(_currentUser!.id!);
      } catch (e) {
        debugPrint('Error loading likes count: $e');
      }
    }
  }

  // Refrescar contador de likes
  Future<void> refreshLikesCount() async {
    await _loadLikesCount();
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _firestore.getUserByEmail(email);

      if (user != null && user.contrasena == password) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user.id!);
        await _loadLikesCount();
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error during login: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Registro
  Future<bool> register(User user) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar si el email ya existe
      final existingUser = await _firestore.getUserByEmail(user.email);
      if (existingUser != null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Crear nuevo usuario
      final userId = await _firestore.createUser(user);
      _currentUser = user.copyWith(id: userId);

      // Guardar sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await _loadLikesCount();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error during registration: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar perfil
  Future<bool> updateProfile(User updatedUser) async {
    try {
      await _firestore.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    notifyListeners();
  }
}

