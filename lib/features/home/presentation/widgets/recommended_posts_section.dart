// lib/features/posts/widgets/recommended_posts_section.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/post_models.dart';
import '../../../../core/services/posts_service.dart';

class RecommendedPostsSection extends StatefulWidget {
  const RecommendedPostsSection({super.key});

  @override
  State<RecommendedPostsSection> createState() => _RecommendedPostsSectionState();
}

class _RecommendedPostsSectionState extends State<RecommendedPostsSection> {
  final PostsService _postsService = PostsService();
  late Future<PostsResult> _recommendedPostsFuture;

  @override
  void initState() {
    super.initState();
    _recommendedPostsFuture = _postsService.getRecommendedPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section
        
        
        // Grille mosaïque de posts
        FutureBuilder<PostsResult>(
          future: _recommendedPostsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isFailure) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "Aucune recommandation disponible pour le moment.",
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            final posts = snapshot.data!.data!;
            if (posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "Aucune recommandation pour l'instant.",
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            return _buildMasonryGrid(posts);
          },
        ),
      ],
    );
  }

  Widget _buildMasonryGrid(List<Post> posts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _MasonryGridLayout(posts: posts),
    );
  }
}

class _MasonryGridLayout extends StatelessWidget {
  final List<Post> posts;
  
  const _MasonryGridLayout({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final itemWidth = (screenWidth - 4) / 3; // 3 colonnes avec 2px de gap
        
        return Column(
          children: _buildRows(itemWidth),
        );
      },
    );
  }

  List<Widget> _buildRows(double itemWidth) {
    final List<Widget> rows = [];
    int index = 0;
    
    while (index < posts.length) {
      // Pattern inspiré de la maquette Instagram
      if (index == 0 && posts.length > 2) {
        // Première ligne: un grand item (2x2) + un normal
        rows.add(_buildFirstRow(itemWidth, index));
        index += 2;
      } else if (index > 0 && index + 1 < posts.length && (index - 2) % 6 == 0) {
        // Ligne avec un item large (2x1)
        rows.add(_buildWideRow(itemWidth, index));
        index += 2;
      } else {
        // Ligne normale avec 3 items
        rows.add(_buildNormalRow(itemWidth, index));
        index += 3;
      }
    }
    
    return rows;
  }

  Widget _buildFirstRow(double itemWidth, int startIndex) {
    return SizedBox(
      height: itemWidth * 2 + 2, // Double hauteur + gap
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item large (2x2)
          if (startIndex < posts.length)
            _buildPostItem(
              posts[startIndex], 
              itemWidth * 2 + 2, // Double largeur + gap
              itemWidth * 2 + 2, // Double hauteur + gap
              true, // isLarge
            ),
          
          const SizedBox(width: 2),
          
          // Colonne droite avec deux items normaux
          Expanded(
            child: Column(
              children: [
                if (startIndex + 1 < posts.length)
                  _buildPostItem(
                    posts[startIndex + 1], 
                    itemWidth, 
                    itemWidth,
                    false,
                  ),
                
                const SizedBox(height: 2),
                
                if (startIndex + 2 < posts.length)
                  _buildPostItem(
                    posts[startIndex + 2], 
                    itemWidth, 
                    itemWidth,
                    false,
                  )
                else
                  Container(
                    height: itemWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideRow(double itemWidth, int startIndex) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      height: itemWidth,
      child: Row(
        children: [
          // Item wide (2x1)
          if (startIndex < posts.length)
            _buildPostItem(
              posts[startIndex], 
              itemWidth * 2 + 2, // Double largeur + gap
              itemWidth,
              false,
            ),
          
          const SizedBox(width: 2),
          
          // Item normal
          if (startIndex + 1 < posts.length)
            _buildPostItem(
              posts[startIndex + 1], 
              itemWidth, 
              itemWidth,
              false,
            ),
        ],
      ),
    );
  }

  Widget _buildNormalRow(double itemWidth, int startIndex) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      height: itemWidth,
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            if (startIndex + i < posts.length)
              _buildPostItem(
                posts[startIndex + i], 
                itemWidth, 
                itemWidth,
                false,
              )
            else
              Container(
                width: itemWidth,
                height: itemWidth,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostItem(Post post, double width, double height, bool isLarge) {
    return GestureDetector(
      onTap: () => _onPostTap(post),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image de fond ou gradient
              _buildBackground(post),
              
              // Overlay sombre pour la lisibilité
              _buildOverlay(),
              
              // Indicateur de type de contenu
              _buildContentIndicator(post),
              
              // Titre du post
              _buildPostTitle(post, isLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(Post post) {
    if (post.mediaUrl.isNotEmpty) {
      return Image.network(
        post.mediaUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildGradientBackground(post);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildGradientBackground(post);
        },
      );
    }
    
    return _buildGradientBackground(post);
  }

  Widget _buildGradientBackground(Post post) {
    // Différents gradients selon le post pour créer de la diversité
    final gradients = [
      const LinearGradient(
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFfa709a), Color(0xFFfee140)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];
    
    final gradientIndex = post.title.hashCode % gradients.length;
    
    return Container(
      decoration: BoxDecoration(
        gradient: gradients[gradientIndex.abs()],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildContentIndicator(Post post) {
    IconData icon;
    String contentType = _getContentType(post);
    
    switch (contentType) {
      case 'video':
        icon = Icons.videocam;
        break;
      case 'carousel':
        icon = Icons.collections;
        break;
      case 'audio':
        icon = Icons.music_note;
        break;
      default:
        icon = Icons.camera_alt;
    }

    return Positioned(
      top: 6,
      right: 6,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }

  Widget _buildPostTitle(Post post, bool isLarge) {
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Text(
        post.title,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: isLarge ? 16 : 14,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        maxLines: isLarge ? 2 : 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getContentType(Post post) {
    // Logique simple pour déterminer le type de contenu
    if (post.mediaUrl.contains('.mp4') || 
        post.mediaUrl.contains('video')) {
      return 'video';
    } else if (post.mediaUrl.contains('carousel') ||
               post.title.toLowerCase().contains('carousel')) {
      return 'carousel';
    } else if (post.mediaUrl.contains('.mp3') ||
               post.title.toLowerCase().contains('music') ||
               post.title.toLowerCase().contains('audio')) {
      return 'audio';
    }
    return 'image';
  }

  void _onPostTap(Post post) {
    // TODO: Naviguer vers le détail du post
    debugPrint('Tap sur le post: ${post.title}');
  }

  /// Génère un nombre de likes factice pour la démo
  int _generateFakeLikes(Post post) {
    // Utilise l'ID du post et son titre pour générer un nombre cohérent
    final seed = post.id.hashCode + post.title.hashCode;
    final random = seed.abs();
    return 15 + (random % 500); // Entre 15 et 515 likes
  }
}