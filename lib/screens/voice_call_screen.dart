import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/call_service.dart';
import '../utils/app_colors.dart';

class VoiceCallScreen extends StatefulWidget {
  final String channelName;
  final String otherUserName;

  const VoiceCallScreen({
    super.key,
    required this.channelName,
    required this.otherUserName,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isConnecting = true;
  String _status = 'Conectando...';

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  @override
  void dispose() {
    CallService.leaveChannel();
    super.dispose();
  }

  Future<void> _startCall() async {
    // Solicitar permisos
    final hasPermissions = await CallService.requestPermissions();
    if (!hasPermissions) {
      setState(() {
        _status = 'Permisos denegados';
        _isConnecting = false;
      });
      return;
    }

    // Unirse al canal
    final success = await CallService.joinChannel(widget.channelName, enableVideo: false);
    if (success) {
      setState(() {
        _status = 'Conectado';
        _isConnecting = false;
      });
    } else {
      setState(() {
        _status = 'Error al conectar';
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    'Llamada de voz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Espacio para balancear
                ],
              ),
            ),

            const Spacer(),

            // Avatar del usuario
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.person,
                size: 80,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            // Nombre del usuario
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Estado de la llamada
            Text(
              _status,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),

            const Spacer(),

            // Controles de llamada
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                      CallService.toggleMicrophone();
                    },
                    backgroundColor: _isMuted ? Colors.red : Colors.grey[800]!,
                  ),

                  // Colgar
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: Colors.red,
                    size: 60,
                  ),

                  // Speaker
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    onPressed: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                      // Aquí podrías implementar el cambio de speaker
                    },
                    backgroundColor: _isSpeakerOn ? AppColors.primary : Colors.grey[800]!,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double size = 50,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}
