import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/user_card.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usersProvider = context.watch<UsersProvider>();
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
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Image.asset(
                        'assets/icon/image.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wayira Space',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Conecta con tu comunidad',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: () {
                        usersProvider.refreshUsers(currentUserId);
                      },
                    ),
                  ],
                ),
              ),

              // Lista de usuarios
              Expanded(
                child: usersProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : usersProvider.users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: AppColors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No hay usuarios disponibles',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: usersProvider.users.length,
                            itemBuilder: (context, index) {
                              final user = usersProvider.users[index];
                              final hasLiked = usersProvider.hasLiked(user.id!);

                              return UserCard(
                                user: user,
                                hasLiked: hasLiked,
                                onLike: () {
                                  usersProvider.likeUser(currentUserId, user.id!);
                                },
                                onMessage: () {
                                  context.push('/chat/${user.id}');
                                },
                                onTap: () {
                                  context.push('/profile/${user.id}');
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

