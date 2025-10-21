import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class CallNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Enviar notificación de llamada entrante
  Future<void> sendIncomingCallNotification({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String channelName,
    required String callType, // 'voice' o 'video'
  }) async {
    try {
      // Crear notificación en Firestore
      await _firestore.collection('call_notifications').add({
        'caller_id': callerId,
        'caller_name': callerName,
        'receiver_id': receiverId,
        'channel_name': channelName,
        'call_type': callType,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, answered, declined, missed
      });

      // Obtener token FCM del receptor
      final userDoc = await _firestore.collection('users').doc(receiverId).get();
      final receiverToken = userDoc.data()?['fcm_token'] as String?;
      
      if (receiverToken != null) {
        // Enviar notificación push
        await _sendPushNotification(
          token: receiverToken,
          callerName: callerName,
          callType: callType,
          channelName: channelName,
        );
      }

      // Crear notificación local
      await _createLocalCallNotification(
        callerName: callerName,
        callType: callType,
        channelName: channelName,
      );

      debugPrint('Notificación de llamada enviada a $receiverId');
    } catch (e) {
      debugPrint('Error enviando notificación de llamada: $e');
    }
  }

  /// Enviar notificación push
  Future<void> _sendPushNotification({
    required String token,
    required String callerName,
    required String callType,
    required String channelName,
  }) async {
    try {
      // Aquí implementarías el envío de notificación push
      // usando Firebase Cloud Messaging o tu servicio preferido
      debugPrint('Enviando push notification a $token');
    } catch (e) {
      debugPrint('Error enviando push notification: $e');
    }
  }

  /// Crear notificación local
  Future<void> _createLocalCallNotification({
    required String callerName,
    required String callType,
    required String channelName,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'incoming_calls',
        'Llamadas Entrantes',
        channelDescription: 'Notificaciones de llamadas de voz y video',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: RawResourceAndroidNotificationSound('incoming_call'),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        actions: [
          AndroidNotificationAction('answer', 'Contestar'),
          AndroidNotificationAction('decline', 'Rechazar'),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'incoming_call.wav',
        categoryIdentifier: 'INCOMING_CALL',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Llamada ${callType == 'voice' ? 'de voz' : 'de video'}',
        '$callerName te está llamando',
        details,
        payload: 'call_$channelName',
      );
    } catch (e) {
      debugPrint('Error creando notificación local: $e');
    }
  }

  /// Marcar llamada como contestada
  Future<void> markCallAsAnswered(String channelName) async {
    try {
      final query = await _firestore
          .collection('call_notifications')
          .where('channel_name', isEqualTo: channelName)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({'status': 'answered'});
      }
    } catch (e) {
      debugPrint('Error marcando llamada como contestada: $e');
    }
  }

  /// Marcar llamada como rechazada
  Future<void> markCallAsDeclined(String channelName) async {
    try {
      final query = await _firestore
          .collection('call_notifications')
          .where('channel_name', isEqualTo: channelName)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({'status': 'declined'});
      }
    } catch (e) {
      debugPrint('Error marcando llamada como rechazada: $e');
    }
  }

  /// Obtener llamadas pendientes
  Stream<List<Map<String, dynamic>>> getPendingCalls(String userId) {
    return _firestore
        .collection('call_notifications')
        .where('receiver_id', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }
}
