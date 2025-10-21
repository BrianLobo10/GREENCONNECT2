import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _messageNotifications = true;
  bool _postNotifications = true;
  bool _followNotifications = true;
  bool _reactionNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Aquí cargarías las configuraciones guardadas del usuario
    // Por ahora usamos valores por defecto
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración de Notificaciones',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de mensajes
          _buildSectionHeader('Mensajes'),
          _buildSwitchTile(
            title: 'Notificaciones de mensajes',
            subtitle: 'Recibe notificaciones cuando recibas mensajes',
            value: _messageNotifications,
            onChanged: (value) {
              setState(() {
                _messageNotifications = value;
              });
            },
            icon: Icons.message,
          ),
          
          const SizedBox(height: 20),
          
          // Sección de publicaciones
          _buildSectionHeader('Publicaciones'),
          _buildSwitchTile(
            title: 'Nuevas publicaciones',
            subtitle: 'Notificaciones de usuarios que sigues',
            value: _postNotifications,
            onChanged: (value) {
              setState(() {
                _postNotifications = value;
              });
            },
            icon: Icons.post_add,
          ),
          _buildSwitchTile(
            title: 'Reacciones a tus publicaciones',
            subtitle: 'Cuando alguien reacciona a tus posts',
            value: _reactionNotifications,
            onChanged: (value) {
              setState(() {
                _reactionNotifications = value;
              });
            },
            icon: Icons.favorite,
          ),
          
          const SizedBox(height: 20),
          
          // Sección de seguimiento
          _buildSectionHeader('Seguimiento'),
          _buildSwitchTile(
            title: 'Nuevos seguidores',
            subtitle: 'Cuando alguien te sigue',
            value: _followNotifications,
            onChanged: (value) {
              setState(() {
                _followNotifications = value;
              });
            },
            icon: Icons.person_add,
          ),
          
          const SizedBox(height: 30),
          
          // Botón de guardar
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Guardar Configuración',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Información adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Información',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Las notificaciones te ayudan a mantenerte conectado con tu comunidad. Puedes cambiar estas configuraciones en cualquier momento.',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        value: value,
        onChanged: onChanged,
        secondary: Icon(
          icon,
          color: AppColors.primary,
        ),
        activeColor: AppColors.primary,
      ),
    );
  }

  void _saveSettings() {
    // Aquí guardarías las configuraciones en Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada ✓'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
