import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reaction.dart';
import '../providers/posts_provider.dart';
import '../utils/app_colors.dart';

class ReactionBar extends StatelessWidget {
  final String postId;
  final String currentUserId;

  const ReactionBar({
    super.key,
    required this.postId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.read<PostsProvider>();

    return StreamBuilder<List<Reaction>>(
      stream: postsProvider.getPostReactionsStream(postId),
      builder: (context, snapshot) {
        final reactions = snapshot.data ?? [];
        
        // Contar reacciones por tipo
        final reactionCounts = <ReactionType, int>{};
        Reaction? userReaction;

        for (var reaction in reactions) {
          reactionCounts[reaction.type] = (reactionCounts[reaction.type] ?? 0) + 1;
          if (reaction.userId == currentUserId) {
            userReaction = reaction;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReactionButton(
                type: ReactionType.feliz,
                count: reactionCounts[ReactionType.feliz] ?? 0,
                isSelected: userReaction?.type == ReactionType.feliz,
                onTap: () => _handleReaction(
                  context,
                  ReactionType.feliz,
                  userReaction,
                ),
              ),
              _ReactionButton(
                type: ReactionType.cool,
                count: reactionCounts[ReactionType.cool] ?? 0,
                isSelected: userReaction?.type == ReactionType.cool,
                onTap: () => _handleReaction(
                  context,
                  ReactionType.cool,
                  userReaction,
                ),
              ),
              _ReactionButton(
                type: ReactionType.enojado,
                count: reactionCounts[ReactionType.enojado] ?? 0,
                isSelected: userReaction?.type == ReactionType.enojado,
                onTap: () => _handleReaction(
                  context,
                  ReactionType.enojado,
                  userReaction,
                ),
              ),
              _ReactionButton(
                type: ReactionType.triste,
                count: reactionCounts[ReactionType.triste] ?? 0,
                isSelected: userReaction?.type == ReactionType.triste,
                onTap: () => _handleReaction(
                  context,
                  ReactionType.triste,
                  userReaction,
                ),
              ),
              _ReactionButton(
                type: ReactionType.sorprendido,
                count: reactionCounts[ReactionType.sorprendido] ?? 0,
                isSelected: userReaction?.type == ReactionType.sorprendido,
                onTap: () => _handleReaction(
                  context,
                  ReactionType.sorprendido,
                  userReaction,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleReaction(
    BuildContext context,
    ReactionType type,
    Reaction? currentReaction,
  ) {
    final postsProvider = context.read<PostsProvider>();

    if (currentReaction?.type == type) {
      // Si ya tiene esta reacción, eliminarla
      postsProvider.removeReaction(
        postId: postId,
        userId: currentUserId,
      );
    } else {
      // Si no tiene o tiene otra, agregar/actualizar
      postsProvider.addOrUpdateReaction(
        postId: postId,
        userId: currentUserId,
        type: type,
      );
    }
  }
}

class _ReactionButton extends StatelessWidget {
  final ReactionType type;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.type,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              type.iconPath,
              width: isSelected ? 32 : 28,
              height: isSelected ? 32 : 28,
              fit: BoxFit.contain,
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

