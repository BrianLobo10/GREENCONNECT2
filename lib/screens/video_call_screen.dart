import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/call_service.dart';
import '../utils/app_colors.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String otherUserName;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.otherUserName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isConnecting = true;
  String _status = 'Conectando...';
  bool _isLocalVideoEnabled = true;

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
    final success = await CallService.joinChannel(widget.channelName, enableVideo: true);
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
        child: Stack(
          children: [
            // Video remoto (pantalla completa)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: _isConnecting
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 20),
                          Text(
                            'Conectando...',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Esperando video...',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
            ),

            // Video local (pequeño en esquina)
            if (_isLocalVideoEnabled && !_isConnecting)
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const Center(
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),

            // Header con nombre
            Positioned(
              top: 50,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _status,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Controles en la parte inferior
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
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

                    // Video on/off
                    _buildControlButton(
                      icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
                      onPressed: () {
                        setState(() {
                          _isVideoOn = !_isVideoOn;
                          _isLocalVideoEnabled = _isVideoOn;
                        });
                        CallService.toggleVideo();
                      },
                      backgroundColor: _isVideoOn ? Colors.grey[800]! : Colors.red,
                    ),

                    // Colgar
                    _buildControlButton(
                      icon: Icons.call_end,
                      onPressed: () => Navigator.pop(context),
                      backgroundColor: Colors.red,
                      size: 60,
                    ),

                    // Cambiar cámara
                    _buildControlButton(
                      icon: Icons.switch_camera,
                      onPressed: () => CallService.switchCamera(),
                      backgroundColor: Colors.grey[800]!,
                    ),

                    // Minimizar
                    _buildControlButton(
                      icon: Icons.minimize,
                      onPressed: () {
                        // Aquí podrías implementar minimizar
                      },
                      backgroundColor: Colors.grey[800]!,
                    ),
                  ],
                ),
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
