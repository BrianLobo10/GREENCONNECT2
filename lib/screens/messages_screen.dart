import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/messages_provider.dart';
import '../widgets/user_avatar.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messagesProvider = context.watch<MessagesProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';

    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Text(
                      'Mensajes',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de conversaciones
              Expanded(
                child: messagesProvider.conversationUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: AppColors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No tienes conversaciones',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: AppColors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Envía un mensaje para empezar',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: messagesProvider.conversationUsers.length,
                        itemBuilder: (context, index) {
                          final userId = messagesProvider.conversationUsers.keys.elementAt(index);
                          final user = messagesProvider.conversationUsers[userId]!;

                          return FutureBuilder(
                            future: messagesProvider.getLastMessage(currentUserId, userId),
                            builder: (context, snapshot) {
                              final lastMessage = snapshot.data;
                              final timeText = lastMessage != null
                                  ? DateFormat('HH:mm').format(lastMessage.fecha)
                                  : '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.15),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading:                                   UserAvatar(
                                    photoUrl: user.foto,
                                    userName: user.nombre,
                                    radius: 30,
                                  ),
                                  title: Text(
                                    user.nombre,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    lastMessage?.texto ?? 'Sin mensajes',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: Text(
                                    timeText,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () {
                                    context.push('/chat/${user.id}');
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

