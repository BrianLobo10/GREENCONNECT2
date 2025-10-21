import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class MessagesProvider with ChangeNotifier {
  List<Message> _messages = [];
  final Map<String, User> _conversationUsers = {};
  bool _isLoading = false;
  StreamSubscription<List<Message>>? _messagesSubscription;

  List<Message> get messages => _messages;
  Map<String, User> get conversationUsers => _conversationUsers;
  bool get isLoading => _isLoading;

  final FirestoreService _firestore = FirestoreService.instance;
  final NotificationService _notificationService = NotificationService();

  // Cargar conversaciones del usuario
  Future<void> loadConversations(String currentUserId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userIds = await _firestore.getConversationUserIds(currentUserId);
      _conversationUsers.clear();
      
      for (var userId in userIds) {
        final user = await _firestore.getUserById(userId);
        if (user != null) {
          _conversationUsers[userId] = user;
        }
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Cargar mensajes de una conversación específica (TIEMPO REAL)
  void loadMessagesStream(String currentUserId, String otherUserId) {
    _isLoading = true;
    notifyListeners();

    // Cancelar suscripción anterior si existe
    _messagesSubscription?.cancel();

    try {
      _messagesSubscription = _firestore
          .getMessagesStream(currentUserId, otherUserId)
          .listen(
        (messages) {
          _messages = messages;
          _isLoading = false;
          notifyListeners();
          debugPrint('Mensajes actualizados: ${messages.length}');
        },
        onError: (e) {
          debugPrint('Error loading messages stream: $e');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error setting up messages stream: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar mensajes (versión antigua - mantener por compatibilidad)
  Future<void> loadMessages(String currentUserId, String otherUserId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _messages = await _firestore.getMessages(currentUserId, otherUserId);
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Enviar mensaje
  Future<void> sendMessage(String senderId, String receiverId, String text) async {
    try {
      final message = Message(
        emisorId: senderId,
        receptorId: receiverId,
        texto: text,
        fecha: DateTime.now(),
      );

      final messageId = await _firestore.sendMessage(message);
      _messages.add(message.copyWith(id: messageId));
      
      // Agregar usuario a conversaciones si no existe
      if (!_conversationUsers.containsKey(receiverId)) {
        final user = await _firestore.getUserById(receiverId);
        if (user != null) {
          _conversationUsers[receiverId] = user;
        }
      }
      
      // Enviar notificación push
      final sender = await _firestore.getUserById(senderId);
      if (sender != null) {
        await _notificationService.sendMessageNotification(
          receiverId: receiverId,
          senderName: sender.nombre,
          messageText: text,
          senderId: senderId,
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  // Enviar mensaje con imagen
  Future<void> sendMessageWithImage(String senderId, String receiverId, String text, File imageFile) async {
    try {
      final message = Message(
        emisorId: senderId,
        receptorId: receiverId,
        texto: text,
        fecha: DateTime.now(),
      );

      await _firestore.sendMessageWithImage(message, imageFile);
      
      // No recargar - el stream lo hará automáticamente
      
      // Agregar usuario a conversaciones si no existe
      if (!_conversationUsers.containsKey(receiverId)) {
        final user = await _firestore.getUserById(receiverId);
        if (user != null) {
          _conversationUsers[receiverId] = user;
        }
      }
    } catch (e) {
      debugPrint('Error sending message with image: $e');
      rethrow;
    }
  }

  // Eliminar mensaje
  Future<bool> deleteMessage(String messageId, DateTime messageDate) async {
    try {
      // Verificar que no hayan pasado más de 10 minutos
      final now = DateTime.now();
      final difference = now.difference(messageDate);
      
      if (difference.inMinutes > 10) {
        return false; // No se puede eliminar después de 10 minutos
      }

      await _firestore.deleteMessage(messageId);
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  // Limpiar suscripción al salir
  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  // Obtener último mensaje de una conversación
  Future<Message?> getLastMessage(String user1Id, String user2Id) async {
    try {
      return await _firestore.getLastMessage(user1Id, user2Id);
    } catch (e) {
      debugPrint('Error getting last message: $e');
      return null;
    }
  }

  // Limpiar mensajes
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Reenviar mensaje
  Future<void> forwardMessage(Message originalMessage, String newReceiverId) async {
    try {
      await _firestore.forwardMessage(originalMessage, newReceiverId);
    } catch (e) {
      debugPrint('Error forwarding message: $e');
      rethrow;
    }
  }

  // Vaciar mensajes de un chat
  Future<void> clearChatMessages(String currentUserId, String otherUserId) async {
    try {
      await _firestore.clearChatMessages(currentUserId, otherUserId);
      _messages.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing chat messages: $e');
      rethrow;
    }
  }
}

extension on Message {
  Message copyWith({
    String? id, 
    String? imageUrl,
    bool? isForwarded,
    String? originalSenderId,
    String? originalSenderName,
    DateTime? originalDate,
  }) {
    return Message(
      id: id ?? this.id,
      emisorId: emisorId,
      receptorId: receptorId,
      texto: texto,
      fecha: fecha,
      imageUrl: imageUrl ?? this.imageUrl,
      isForwarded: isForwarded ?? this.isForwarded,
      originalSenderId: originalSenderId ?? this.originalSenderId,
      originalSenderName: originalSenderName ?? this.originalSenderName,
      originalDate: originalDate ?? this.originalDate,
    );
  }
}
