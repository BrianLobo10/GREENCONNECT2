import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../widgets/user_avatar.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final bool isFollowers; // true = seguidores, false = seguidos

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.isFollowers,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final FirestoreService _firestoreService = FirestoreService.instance;
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      List<String> userIds;
      
      if (widget.isFollowers) {
        // Obtener IDs de seguidores usando método público
        userIds = await _firestoreService.getFollowersIds(widget.userId);
      } else {
        // Obtener IDs de seguidos usando método público
        userIds = await _firestoreService.getFollowingIds(widget.userId);
      }

      // Obtener datos de usuarios
      final users = <User>[];
      for (final id in userIds) {
        final user = await _firestoreService.getUserById(id);
        if (user != null) {
          users.add(user);
        }
      }

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFollowers ? 'Seguidores' : 'Siguiendo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isFollowers ? Icons.people_outline : Icons.person_add_outlined,
                        size: 80,
                        color: AppColors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isFollowers 
                            ? 'No tienes seguidores aún'
                            : 'No sigues a nadie aún',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: UserAvatar(
                        photoUrl: user.foto,
                        userName: user.nombre,
                        radius: 25,
                        showOnlineStatus: true,
                        isOnline: user.isOnline,
                      ),
                      title: Text(
                        user.nombre,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${user.edad} años',
                        style: GoogleFonts.poppins(
                          color: AppColors.grey,
                        ),
                      ),
                      trailing: user.id != context.read<AuthProvider>().currentUser?.id
                          ? IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, size: 16),
                              onPressed: () {
                                context.push('/profile/${user.id}');
                              },
                            )
                          : null,
                      onTap: () {
                        if (user.id != null) {
                          context.push('/profile/${user.id}');
                        }
                      },
                    );
                  },
                ),
    );
  }
}
