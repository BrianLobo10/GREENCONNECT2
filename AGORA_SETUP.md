# Configuración de Agora RTC para Llamadas

## Pasos para configurar las llamadas de voz y video:

### 1. Crear cuenta en Agora
1. Ve a [https://console.agora.io/](https://console.agora.io/)
2. Crea una cuenta o inicia sesión
3. Verifica tu email si es necesario

### 2. Crear un proyecto
1. En el dashboard, haz clic en "Create Project"
2. Dale un nombre al proyecto (ej: "Wayira Space")
3. Selecciona "Communication" como tipo de proyecto
4. Haz clic en "Submit"

### 3. Obtener el App ID
1. En tu proyecto, ve a "Project Management"
2. Copia el "App ID" que aparece
3. Abre el archivo `lib/config/agora_config.dart`
4. Reemplaza `YOUR_AGORA_APP_ID_HERE` con tu App ID real

### 4. Configurar permisos (Android)
Los permisos ya están configurados en `android/app/src/main/AndroidManifest.xml`:
- RECORD_AUDIO
- CAMERA
- MODIFY_AUDIO_SETTINGS
- ACCESS_WIFI_STATE
- ACCESS_NETWORK_STATE
- CHANGE_NETWORK_STATE
- BLUETOOTH
- BLUETOOTH_CONNECT

### 5. Configurar permisos (iOS)
Agrega estos permisos en `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Esta app necesita acceso a la cámara para videollamadas</string>
<key>NSMicrophoneUsageDescription</key>
<string>Esta app necesita acceso al micrófono para llamadas de voz</string>
```

### 6. Probar las llamadas
1. Ejecuta la app en dos dispositivos diferentes
2. Ve al chat con otro usuario
3. Toca el botón de llamada (teléfono) o videollamada (cámara)
4. Ambos usuarios se conectarán al mismo canal

## Características implementadas:

### Llamadas de Voz:
- ✅ Unirse a canal de audio
- ✅ Mute/unmute micrófono
- ✅ Speaker on/off
- ✅ Colgar llamada

### Videollamadas:
- ✅ Unirse a canal de video
- ✅ Mute/unmute micrófono
- ✅ Encender/apagar cámara
- ✅ Cambiar entre cámara frontal/trasera
- ✅ Video local en esquina
- ✅ Colgar llamada

## Notas importantes:
- Las llamadas funcionan a través de internet (WiFi o datos móviles)
- No necesitas números de teléfono
- Los canales son únicos por llamada
- Funciona entre cualquier usuario de la app

## Solución de problemas:
- Si no funciona, verifica que el App ID esté correcto
- Asegúrate de que ambos dispositivos tengan internet
- Verifica que los permisos estén concedidos
- Revisa los logs en la consola para errores
