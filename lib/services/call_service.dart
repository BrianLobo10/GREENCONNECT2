import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../config/agora_config.dart';

class CallService {
  static RtcEngine? _engine;
  static bool _isInitialized = false;
  static String? _currentChannel;
  static bool _isInCall = false;

  /// Inicializar el servicio de llamadas
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Configurar eventos
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Canal unido exitosamente: ${connection.channelId}');
            _isInCall = true;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Usuario se unió: $remoteUid');
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('Usuario se desconectó: $remoteUid');
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Error en Agora: $err - $msg');
          },
        ),
      );

      _isInitialized = true;
      debugPrint('Servicio de llamadas inicializado');
    } catch (e) {
      debugPrint('Error inicializando servicio de llamadas: $e');
    }
  }

  /// Solicitar permisos necesarios
  static Future<bool> requestPermissions() async {
    try {
      // Solicitar permisos de micrófono y cámara
      final micPermission = await Permission.microphone.request();
      final cameraPermission = await Permission.camera.request();

      if (micPermission.isGranted && cameraPermission.isGranted) {
        return true;
      } else {
        debugPrint('Permisos denegados: mic=$micPermission, camera=$cameraPermission');
        return false;
      }
    } catch (e) {
      debugPrint('Error solicitando permisos: $e');
      return false;
    }
  }

  /// Unirse a un canal de llamada
  static Future<bool> joinChannel(String channelName, {bool enableVideo = true}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_engine == null) {
      debugPrint('Motor de Agora no inicializado');
      return false;
    }

    try {
      // Configurar video si está habilitado
      if (enableVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.disableVideo();
      }

      // Habilitar audio
      await _engine!.enableAudio();

      // Unirse al canal
      await _engine!.joinChannel(
        token: AgoraConfig.token,
        channelId: channelName,
        uid: AgoraConfig.uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      _currentChannel = channelName;
      return true;
    } catch (e) {
      debugPrint('Error uniéndose al canal: $e');
      return false;
    }
  }

  /// Salir del canal actual
  static Future<void> leaveChannel() async {
    if (_engine != null && _isInCall) {
      try {
        await _engine!.leaveChannel();
        _isInCall = false;
        _currentChannel = null;
        debugPrint('Canal abandonado');
      } catch (e) {
        debugPrint('Error abandonando canal: $e');
      }
    }
  }

  /// Cambiar entre cámara frontal y trasera
  static Future<void> switchCamera() async {
    if (_engine != null) {
      try {
        await _engine!.switchCamera();
      } catch (e) {
        debugPrint('Error cambiando cámara: $e');
      }
    }
  }

  /// Mute/unmute micrófono
  static Future<void> toggleMicrophone() async {
    if (_engine != null) {
      try {
        await _engine!.muteLocalAudioStream(_isInCall);
      } catch (e) {
        debugPrint('Error cambiando micrófono: $e');
      }
    }
  }

  /// Mute/unmute video
  static Future<void> toggleVideo() async {
    if (_engine != null) {
      try {
        await _engine!.muteLocalVideoStream(_isInCall);
      } catch (e) {
        debugPrint('Error cambiando video: $e');
      }
    }
  }

  /// Obtener el motor de Agora para la UI
  static RtcEngine? get engine => _engine;

  /// Verificar si está en una llamada
  static bool get isInCall => _isInCall;

  /// Obtener el canal actual
  static String? get currentChannel => _currentChannel;

  /// Limpiar recursos
  static Future<void> dispose() async {
    if (_engine != null) {
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
      _isInCall = false;
      _currentChannel = null;
    }
  }
}
