import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/text_utils.dart';
import 'reaction_bar.dart';
import 'comments_list.dart';
import 'user_avatar.dart';
import 'video_player_widget.dart';
import 'image_carousel.dart';
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
  User? _postUser;
  final FirestoreService _firestoreService = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    // Configurar español para timeago
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _loadPostUser();
  }



  Future<void> _loadPostUser() async {
    try {
      final user = await _firestoreService.getUserById(widget.post.userId);
      if (mounted && user != null) {
        setState(() {
          _postUser = user;
        });
      }
    } catch (e) {
      // Si falla, usar datos del post
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';
    final isOwner = widget.post.userId == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      shadowColor: AppColors.primary.withOpacity(0.3),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: foto, nombre y fecha
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: UserAvatar(
              photoUrl: _postUser?.foto ?? widget.post.userPhoto,
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
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                      if (isOwner) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
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
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _editPost();
                      } else if (value == 'delete') {
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
                  ),
          ),

          // Indicador de compartido
          if (widget.post.isShared)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.repeat, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Compartido de ${widget.post.sharedFromUserName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Contenido del post
          if (widget.post.contenido.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                      children: TextUtils.formatTextWithLinks(
                        widget.post.contenido,
                        defaultStyle: const TextStyle(fontSize: 15, color: Colors.black),
                        hashtagStyle: const TextStyle(
                          fontSize: 15,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        mentionStyle: const TextStyle(
                          fontSize: 15,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  if (widget.post.isEdited)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '(editado)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Imagen o video del post
          if (widget.post.mediaType == MediaType.image && widget.post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ImageCarousel(
                imageUrls: widget.post.imageUrls ?? [widget.post.imageUrl!],
                height: 400,
              ),
            ),

          // Video del post
          if (widget.post.mediaType == MediaType.video && widget.post.videoUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: VideoPlayerWidget(videoUrl: widget.post.videoUrl!),
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

  void _editPost() {
    // Navegar a la pantalla de edición completa
    context.push('/edit-post/${widget.post.id}');
  }



}

