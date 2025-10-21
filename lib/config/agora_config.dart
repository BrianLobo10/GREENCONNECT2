class AgoraConfig {
  // IMPORTANTE: Reemplaza con tu App ID de Agora
  // Para obtener tu App ID:
  // 1. Ve a https://console.agora.io/
  // 2. Crea una cuenta o inicia sesión
  // 3. Crea un nuevo proyecto
  // 4. Copia el App ID y pégalo aquí
  static const String appId = 'YOUR_AGORA_APP_ID_HERE';
  
  // Token opcional para producción (dejar vacío para testing)
  static const String token = '';
  
  // UID del usuario (0 = Agora asigna automáticamente)
  static const int uid = 0;
  
  // Configuración de canales
  static const String channelPrefix = 'wayira_space_call_';
  
  // Configuración de video
  static const int videoWidth = 640;
  static const int videoHeight = 480;
  static const int frameRate = 15;
  static const int bitrate = 400;
  
  // Configuración de audio
  static const int audioSampleRate = 48000;
  static const int audioChannels = 1;
  static const int audioBitrate = 48;
}
