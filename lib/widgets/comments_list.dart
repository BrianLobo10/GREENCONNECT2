import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment.dart';
import '../models/comment_vote.dart';
import '../models/user.dart';
import '../providers/posts_provider.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import 'user_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsList extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserPhoto;

  const CommentsList({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserPhoto,
  });

  @override
  State<CommentsList> createState() => _CommentsListState();
}

class _CommentsListState extends State<CommentsList> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Configurar español para timeago
    timeago.setLocaleMessages('es', timeago.EsMessages());
    
    // Escuchar cuando el campo de texto recibe el foco
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Hacer scroll al campo de texto cuando recibe el foco
      Future.delayed(const Duration(milliseconds: 300), () {
        final context = _textFieldKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.read<PostsProvider>();

    return Column(
      children: [
        const Divider(height: 1),
        
        // Campo de entrada de comentario
        Padding(
          key: _textFieldKey,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatar(
                photoUrl: widget.currentUserPhoto,
                userName: widget.currentUserName,
                radius: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSubmitting ? null : _submitComment,
                icon: Icon(
                  Icons.send,
                  color: _isSubmitting ? Colors.grey : AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Lista de comentarios
        StreamBuilder<List<Comment>>(
          stream: postsProvider.getPostCommentsStream(widget.postId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error al cargar comentarios: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final comments = snapshot.data ?? [];

            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No hay comentarios aún',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: comments.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final comment = comments[index];
                return _CommentItem(
                  comment: comment,
                  currentUserId: widget.currentUserId,
                  onDelete: () => _deleteComment(comment.id!),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _submitComment() async {
    final texto = _commentController.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final postsProvider = context.read<PostsProvider>();
    final success = await postsProvider.createComment(
      postId: widget.postId,
      userId: widget.currentUserId,
      userName: widget.currentUserName,
      userPhoto: widget.currentUserPhoto,
      texto: texto,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      _commentController.clear();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar comentario')),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Estás seguro de que quieres eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final postsProvider = context.read<PostsProvider>();
      await postsProvider.deleteComment(commentId);
    }
  }
}

class _CommentItem extends StatefulWidget {
  final Comment comment;
  final String currentUserId;
  final VoidCallback onDelete;

  const _CommentItem({
    required this.comment,
    required this.currentUserId,
    required this.onDelete,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  CommentVote? _userVote;
  User? _commentUser;
  final FirestoreService _firestoreService = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    _loadUserVote();
    _loadCommentUser();
  }

  Future<void> _loadUserVote() async {
    if (widget.comment.id == null) return;
    final postsProvider = context.read<PostsProvider>();
    final vote = await postsProvider.getUserCommentVote(
      widget.comment.id!,
      widget.currentUserId,
    );
    if (mounted) {
      setState(() {
        _userVote = vote;
      });
    }
  }

  Future<void> _loadCommentUser() async {
    try {
      final user = await _firestoreService.getUserById(widget.comment.userId);
      if (mounted) {
        setState(() {
          _commentUser = user;
        });
      }
    } catch (e) {
      // Si falla, usar datos del comentario
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.comment.userId == widget.currentUserId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          photoUrl: _commentUser?.foto ?? widget.comment.userPhoto,
          userName: widget.comment.userName,
          radius: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.comment.texto,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    timeago.format(widget.comment.fecha, locale: 'es'),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botón de like
                  InkWell(
                    onTap: () => _handleVote(VoteType.like),
                    child: Row(
                      children: [
                        Icon(
                          _userVote?.type == VoteType.like
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          size: 16,
                          color: _userVote?.type == VoteType.like
                              ? AppColors.primary
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.comment.likes.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _userVote?.type == VoteType.like
                                ? AppColors.primary
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botón de dislike
                  InkWell(
                    onTap: () => _handleVote(VoteType.dislike),
                    child: Row(
                      children: [
                        Icon(
                          _userVote?.type == VoteType.dislike
                              ? Icons.thumb_down
                              : Icons.thumb_down_outlined,
                          size: 16,
                          color: _userVote?.type == VoteType.dislike
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.comment.dislikes.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _userVote?.type == VoteType.dislike
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleVote(VoteType type) async {
    if (widget.comment.id == null) return;

    final postsProvider = context.read<PostsProvider>();
    await postsProvider.voteComment(
      commentId: widget.comment.id!,
      userId: widget.currentUserId,
      type: type,
    );

    // Recargar el voto del usuario
    _loadUserVote();
  }
}

