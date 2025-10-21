import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Widget helper para mostrar avatares de usuario
/// Soporta URLs de red, emojis y fallback a inicial del nombre
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String userName;
  final double radius;
  final VoidCallback? onTap;
  final bool showOnlineStatus;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.userName,
    this.radius = 24,
    this.onTap,
    this.showOnlineStatus = false,
    this.isOnline = false,
  });

  bool _isUrl(String? text) {
    if (text == null || text.isEmpty) return false;
    return text.startsWith('http://') || text.startsWith('https://');
  }

  bool _isEmoji(String? text) {
    if (text == null || text.isEmpty) return false;
    // Los emojis son generalmente de 1-4 caracteres y no contienen http
    return text.length <= 4 && !_isUrl(text);
  }

  @override
  Widget build(BuildContext context) {
    final isUrl = _isUrl(photoUrl);
    final isEmoji = _isEmoji(photoUrl);
    
    Widget? avatarChild;
    ImageProvider? avatarImage;

    if (isUrl) {
      // Es una URL de imagen (incluyendo Data Dragon)
      avatarImage = NetworkImage(photoUrl!);
    } else if (isEmoji) {
      // Es un emoji
      avatarChild = Text(
        photoUrl!,
        style: TextStyle(
          fontSize: radius * 1.2,
        ),
      );
    } else {
      // Mostrar inicial del nombre
      avatarChild = Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      );
    }

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: isUrl ? Colors.grey[200] : AppColors.primary,
      backgroundImage: avatarImage,
      child: avatarChild,
    );

    Widget avatarWidget = avatar;

    // Agregar indicador de estado online
    if (showOnlineStatus) {
      avatarWidget = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.online : AppColors.offline,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}

