import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/auth_provider.dart';
import '../../../../core/providers/posts_providers.dart';

import '../widgets/connected_post_widget.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late PostsProvider _postsProvider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Initialiser le provider après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postsProvider = context.read<PostsProvider>();
      _postsProvider.initializeFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _postsProvider.refreshPosts();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<PostsProvider>(
                builder: (context, postsProvider, _) {
                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: Colors.black,
                    child: _buildContent(postsProvider),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.black12, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OnlyFlick',
                style: GoogleFonts.pacifico(
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  // Badge de rôle
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getRoleColor(user.role), width: 0.5),
                      ),
                      child: Text(
                        _getRoleLabel(user.role),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getRoleColor(user.role),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chat_bubble_outline, color: Colors.black),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(PostsProvider postsProvider) {
    switch (postsProvider.state) {
      case FeedState.initial:
      case FeedState.loading:
        return _buildLoadingState();
      
      case FeedState.error:
        return _buildErrorState(postsProvider);
      
      case FeedState.loaded:
      case FeedState.refreshing:
        if (postsProvider.posts.isEmpty) {
          return _buildEmptyState();
        }
        return _buildPostsList(postsProvider);
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.black),
          SizedBox(height: 16),
          Text(
            'Chargement du feed...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(PostsProvider postsProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              postsProvider.error ?? 'Une erreur inattendue s\'est produite',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => postsProvider.retry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun post disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Il n\'y a pas encore de contenu à afficher.\nTirez vers le bas pour actualiser.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _postsProvider.refreshPosts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(PostsProvider postsProvider) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: postsProvider.posts.length + (postsProvider.isRefreshing ? 1 : 0),
      itemBuilder: (context, index) {
        // Indicateur de chargement en haut pendant le refresh
        if (postsProvider.isRefreshing && index == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            ),
          );
        }

        // Ajuster l'index si on a l'indicateur de refresh
        final postIndex = postsProvider.isRefreshing ? index - 1 : index;
        
        if (postIndex < 0 || postIndex >= postsProvider.posts.length) {
          return const SizedBox.shrink();
        }

        final post = postsProvider.posts[postIndex];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ConnectedPostWidget(
            post: post,
            onLike: () => postsProvider.toggleLike(post.id),
            onComment: (content) => postsProvider.addComment(post.id, content),
            onError: (message) => _showSnackBar(message, isError: true),
          ),
        );
      },
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'creator':
        return 'Créateur';
      case 'admin':
        return 'Admin';
      case 'subscriber':
      default:
        return 'Abonné';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'creator':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      case 'subscriber':
      default:
        return Colors.blue;
    }
  }
}