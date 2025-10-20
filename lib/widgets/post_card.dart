import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../utils/app_colors.dart';
import 'reaction_bar.dart';
import 'comments_list.dart';
import 'user_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onUserTap;

  const PostCard({
    super.key,
    required this.post,
    this.onUserTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    // Configurar español para timeago
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';
    final isOwner = widget.post.userId == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: AppColors.primary.withOpacity(0.2),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: foto, nombre y fecha
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: UserAvatar(
              photoUrl: widget.post.userPhoto,
              userName: widget.post.userName,
              radius: 24,
              onTap: widget.onUserTap,
            ),
            title: GestureDetector(
              onTap: widget.onUserTap,
              child: Text(
                widget.post.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            subtitle: Text(
              timeago.format(widget.post.fecha, locale: 'es'),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            trailing: isOwner
                ? PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar publicación'),
                            content: const Text(
                              '¿Estás seguro de que quieres eliminar esta publicación?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && widget.post.id != null) {
                          final postsProvider = context.read<PostsProvider>();
                          await postsProvider.deletePost(widget.post.id!);
                        }
                      }
                    },
                  )
                : null,
          ),

          // Contenido del post
          if (widget.post.contenido.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.post.contenido,
                style: const TextStyle(fontSize: 15),
              ),
            ),

          // Imagen del post
          if (widget.post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Image.network(
                widget.post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.error, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),

          // Barra de reacciones
          ReactionBar(
            postId: widget.post.id ?? '',
            currentUserId: currentUserId,
          ),

          const Divider(height: 1),

          // Botón de comentarios
          InkWell(
            onTap: () {
              setState(() {
                _showComments = !_showComments;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _showComments ? Icons.comment : Icons.comment_outlined,
                    size: 20,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showComments ? 'Ocultar comentarios' : 'Ver comentarios',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de comentarios
          if (_showComments)
            CommentsList(
              postId: widget.post.id ?? '',
              currentUserId: currentUserId,
              currentUserName: authProvider.currentUser?.nombre ?? '',
              currentUserPhoto: authProvider.currentUser?.foto,
            ),
        ],
      ),
    );
  }
}

