import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Widget helper para mostrar avatares de usuario
/// Soporta URLs de red, emojis y fallback a inicial del nombre
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String userName;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.userName,
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      backgroundImage: photoUrl != null && photoUrl!.startsWith('http')
          ? NetworkImage(photoUrl!)
          : null,
      child: photoUrl == null || !photoUrl!.startsWith('http')
          ? Text(
              photoUrl != null && !photoUrl!.startsWith('http')
                  ? photoUrl! // Es un emoji
                  : userName.isNotEmpty
                      ? userName[0].toUpperCase()
                      : 'U',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: photoUrl != null && !photoUrl!.startsWith('http')
                    ? radius * 1.2 // Emoji más grande
                    : radius * 0.8, // Inicial más pequeña
              ),
            )
          : null,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}

