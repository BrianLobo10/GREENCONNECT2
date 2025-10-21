import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/message.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Configurar notificaciones locales
    await _initializeLocalNotifications();
    
    // Solicitar permisos
    await _requestPermissions();
    
    // Obtener token FCM
    await _getFCMToken();
    
    // Configurar manejadores de notificaciones
    _setupNotificationHandlers();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } else if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  void _setupNotificationHandlers() {
    // Manejar notificaciones cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Manejar notificaciones cuando la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Manejar notificaciones cuando la app se abre desde una notificación
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Mensaje recibido en primer plano: ${message.notification?.title}');
    
    // Mostrar notificación local
    await _showLocalNotification(message);
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Mensaje recibido en segundo plano: ${message.notification?.title}');
    // La navegación se maneja en _onNotificationTapped
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'wayira_space_channel',
      'Wayira Space Notifications',
      channelDescription: 'Notificaciones de mensajes y actividades',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Wayira Space',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificación tocada: ${response.payload}');
    
    // Aquí puedes manejar la navegación basada en el payload
    // Por ejemplo, abrir el chat específico
    if (response.payload != null) {
      // Parsear datos y navegar
      // Esto se implementará en el provider principal
    }
  }

  // Guardar token FCM en Firestore
  Future<void> saveFCMToken(String userId) async {
    if (_fcmToken != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'fcm_token': _fcmToken,
          'last_seen': FieldValue.serverTimestamp(),
        });
        debugPrint('Token FCM guardado para usuario: $userId');
      } catch (e) {
        debugPrint('Error guardando token FCM: $e');
      }
    }
  }

  // Enviar notificación de mensaje
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String senderId,
  }) async {
    try {
      // Obtener token FCM del receptor
      final userDoc = await _firestore.collection('users').doc(receiverId).get();
      final receiverToken = userDoc.data()?['fcm_token'] as String?;
      
      if (receiverToken == null) {
        debugPrint('No se encontró token FCM para el receptor');
        return;
      }

      // Crear notificación local para el receptor
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'wayira_space_channel',
        'Wayira Space Notifications',
        channelDescription: 'Notificaciones de mensajes y actividades',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.wav',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Nuevo mensaje de $senderName',
        messageText.length > 50 ? '${messageText.substring(0, 50)}...' : messageText,
        details,
        payload: 'chat_$senderId',
      );
      
      debugPrint('Notificación enviada a $receiverId: $messageText');
      
    } catch (e) {
      debugPrint('Error enviando notificación: $e');
    }
  }

  // Suscribirse a un tema (opcional)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Suscrito al tema: $topic');
    } catch (e) {
      debugPrint('Error suscribiéndose al tema: $e');
    }
  }

  // Desuscribirse de un tema
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Desuscrito del tema: $topic');
    } catch (e) {
      debugPrint('Error desuscribiéndose del tema: $e');
    }
  }
}

// Manejador de notificaciones en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Manejando mensaje en segundo plano: ${message.messageId}');
}
