import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/posts_providers.dart';
import '../../../../../core/services/posts_service.dart';

class ConnectedPostWidget extends StatefulWidget {
  final Post post;
  final VoidCallback onLike;
  final Function(String) onComment;
  final Function(String) onError;

  const ConnectedPostWidget({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onError,
  });

  @override
  State<ConnectedPostWidget> createState() => _ConnectedPostWidgetState();
}

class _ConnectedPostWidgetState extends State<ConnectedPostWidget> {
  final TextEditingController _commentController = TextEditingController();
  bool _showComments = false;
  bool _isAddingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleAddComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isAddingComment = true;
    });

    final success = await widget.onComment(content);
    
    if (success) {
      _commentController.clear();
      // Fermer le clavier
      FocusScope.of(context).unfocus();
    } else {
      widget.onError('Erreur lors de l\'ajout du commentaire');
    }

    setState(() {
      _isAddingComment = false;
    });
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostsProvider>(
      builder: (context, postsProvider, _) {
        final likesCount = postsProvider.getLikesCount(widget.post.id);
        final isLiked = postsProvider.isLikedByUser(widget.post.id);
        final commentsCount = postsProvider.getCommentsCount(widget.post.id);

        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostHeader(),
              _buildPostImage(),
              _buildPostActions(isLiked, likesCount, commentsCount),
              _buildPostDescription(),
              if (_showComments) _buildCommentsSection(postsProvider),
              if (_showComments) _buildAddCommentSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/150?img=${widget.post.userId % 20}',
            ),
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'user${widget.post.userId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.post.isSubscriberOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple, width: 0.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 10, color: Colors.purple),
                            SizedBox(width: 2),
                            Text(
                              'Abonnés',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(
                  _getTimeAgo(widget.post.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onSelected: (value) {
              switch (value) {
                case 'report':
                  widget.onError('Fonctionnalité de signalement à venir');
                  break;
                case 'share':
                  widget.onError('Fonctionnalité de partage à venir');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Signaler'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Partager'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: widget.post.mediaUrl.isNotEmpty
            ? Image.network(
                widget.post.mediaUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.black,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Impossible de charger l\'image',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              ),
      ),
    );
  }

  Widget _buildPostActions(bool isLiked, int likesCount, int commentsCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onLike,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.black,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _toggleComments,
                child: const Icon(
                  Icons.mode_comment_outlined,
                  color: Colors.black,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.send_outlined, color: Colors.black, size: 24),
              const Spacer(),
              const Icon(Icons.bookmark_border, color: Colors.black),
            ],
          ),
          const SizedBox(height: 8),
          if (likesCount > 0)
            Text(
              '$likesCount J\'aime${likesCount > 1 ? 's' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          if (commentsCount > 0) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _toggleComments,
              child: Text(
                'Voir ${_showComments ? 'moins' : 'tous'} les $commentsCount commentaire${commentsCount > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.title.isNotEmpty)
            Text(
              widget.post.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          if (widget.post.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.post.description,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection(PostsProvider postsProvider) {
    return FutureBuilder<List<Comment>>(
      future: postsProvider.getComments(widget.post.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final comments = snapshot.data ?? [];
        
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Aucun commentaire pour le moment',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=${comment.userId % 20}',
                      ),
                      radius: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'user${comment.userId} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: comment.content,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _getTimeAgo(comment.createdAt),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAddCommentSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black12, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Ajouter un commentaire...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleAddComment(),
            ),
          ),
          if (_isAddingComment)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              onPressed: _handleAddComment,
              icon: const Icon(Icons.send, color: Colors.black),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}