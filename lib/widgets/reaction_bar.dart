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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReactionButton(
                type: ReactionType.heart,
                count: reactionCounts[ReactionType.heart] ?? 0,
                isSelected: userReaction?.type == ReactionType.heart,
                onTap: () => _handleReaction(
                  context,
                  ReactionType.heart,
                  userReaction,
                ),
              ),
              _ReactionButton(
                type: ReactionType.like,
                count: reactionCounts[ReactionType.like] ?? 0,
                isSelected: userReaction?.type == ReactionType.like,
                onTap: () => _handleReaction(
                  context,
                  ReactionType.like,
                  userReaction,
                ),
              ),
              _ReactionButton(
                type: ReactionType.smile,
                count: reactionCounts[ReactionType.smile] ?? 0,
                isSelected: userReaction?.type == ReactionType.smile,
                onTap: () => _handleReaction(
                  context,
                  ReactionType.smile,
                  userReaction,
                ),
              ),
              _ReactionButton(
                type: ReactionType.angry,
                count: reactionCounts[ReactionType.angry] ?? 0,
                isSelected: userReaction?.type == ReactionType.angry,
                onTap: () => _handleReaction(
                  context,
                  ReactionType.angry,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.emoji,
              style: TextStyle(
                fontSize: isSelected ? 22 : 20,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 13,
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

