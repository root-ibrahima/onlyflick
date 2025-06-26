// lib/features/search/presentation/pages/search_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/search_models.dart';
import '../../../../core/providers/search_provider.dart' ;

import '../widgets/search_bar_widget.dart';
import '../widgets/search_suggestions_widget.dart';
import '../widgets/posts_grid_widget.dart';
import '../widgets/users_list_widget.dart';
import '../widgets/discovery_feed_widget.dart';
import '../widgets/tags_filter_widget.dart';
import '../widgets/trending_tags_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _showSuggestions = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _searchController.addListener(_onSearchTextChanged);
    
    // Initialiser le provider au premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  void _initializeProvider() {
    final provider = context.read<SearchProvider>();
    provider.initialize();
  }

  void _onSearchFocusChanged() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
    });
  }

  void _onSearchTextChanged() {
    final provider = context.read<SearchProvider>();
    final query = _searchController.text;
    
    if (query.isNotEmpty) {
      provider.loadSuggestions(query);
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus;
      });
    } else {
      provider.clearSuggestions();
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    _searchController.text = suggestion.text;
    _searchFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    
    final provider = context.read<SearchProvider>();
    if (suggestion.isUser) {
      // Basculer sur l'onglet utilisateurs et rechercher
      _tabController.animateTo(1);
      provider.search(query: suggestion.text);
    } else if (suggestion.isTag && suggestion.category != null) {
      // Ajouter le tag aux filtres et basculer sur l'onglet posts
      _tabController.animateTo(0);
      provider.toggleSearchTag(suggestion.category!);
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    
    _searchFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    
    final provider = context.read<SearchProvider>();
    provider.search(query: query.trim());
    
    // Basculer sur l'onglet approprié
    if (_currentTabIndex == 2) {
      _tabController.animateTo(0); // Passer de découverte à posts
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    
    final provider = context.read<SearchProvider>();
    provider.clearSearch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchSection(),
            if (_showSuggestions) _buildSuggestions(),
            if (!_showSuggestions) _buildTabBar(),
            if (!_showSuggestions) _buildFiltersSection(),
            if (!_showSuggestions) Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'OnlyFlick',
        style: GoogleFonts.pacifico(
          fontSize: 24,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchBarWidget(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onSubmitted: _onSearchSubmitted,
        onClear: _clearSearch,
      ),
    );
  }

  Widget _buildSuggestions() {
    return Expanded(
      child: SearchSuggestionsWidget(
        onSuggestionTap: _onSuggestionTap,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        indicator: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black54,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Utilisateurs'),
          Tab(text: 'Découverte'),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    if (_currentTabIndex == 1) return const SizedBox.shrink(); // Pas de filtres pour les utilisateurs
    
    return Column(
      children: [
        TagsFilterWidget(
          isDiscoveryMode: _currentTabIndex == 2,
        ),
        if (_currentTabIndex == 2) const TrendingTagsWidget(),
      ],
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPostsTab(),
        _buildUsersTab(),
        _buildDiscoveryTab(),
      ],
    );
  }

  Widget _buildPostsTab() {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.searchState == SearchState.initial) {
          return _buildInitialPostsState();
        }

        if (provider.searchState == SearchState.loading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (provider.searchState == SearchState.error) {
          return _buildErrorState(
            provider.searchError ?? 'Erreur de recherche',
            () => provider.search(query: _searchController.text),
          );
        }

        if (provider.searchResult.posts.isEmpty && _searchController.text.isNotEmpty) {
          return _buildEmptyPostsState();
        }

        return PostsGridWidget(
          posts: provider.searchResult.posts,
          hasMore: provider.hasMoreSearchResults,
          isLoadingMore: provider.isLoadingMoreSearch,
          onLoadMore: provider.loadMoreSearchResults,
          onPostTap: (post) => provider.trackPostView(post),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.searchState == SearchState.initial) {
          return _buildInitialUsersState();
        }

        if (provider.searchState == SearchState.loading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (provider.searchState == SearchState.error) {
          return _buildErrorState(
            provider.searchError ?? 'Erreur de recherche',
            () => provider.search(query: _searchController.text),
          );
        }

        if (provider.searchResult.users.isEmpty && _searchController.text.isNotEmpty) {
          return _buildEmptyUsersState();
        }

        return UsersListWidget(
          users: provider.searchResult.users,
          hasMore: provider.hasMoreSearchResults,
          isLoadingMore: provider.isLoadingMoreSearch,
          onLoadMore: provider.loadMoreSearchResults,
          onUserTap: (user) => provider.trackProfileView(user),
        );
      },
    );
  }

  Widget _buildDiscoveryTab() {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.discoveryState == DiscoveryState.loading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (provider.discoveryState == DiscoveryState.error) {
          return _buildErrorState(
            provider.discoveryError ?? 'Erreur de chargement',
            () => provider.refreshDiscoveryFeed(),
          );
        }

        return DiscoveryFeedWidget(
          posts: provider.discoveryPosts,
          hasMore: provider.hasMoreDiscovery,
          isLoadingMore: provider.isLoadingMoreDiscovery,
          isRefreshing: provider.discoveryState == DiscoveryState.refreshing,
          onLoadMore: provider.loadMoreDiscoveryPosts,
          onRefresh: provider.refreshDiscoveryFeed,
          onPostTap: (post) => provider.trackPostView(post),
          onLike: (post) => provider.togglePostLike(post),
        );
      },
    );
  }

  Widget _buildInitialPostsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Rechercher des posts',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisez des mots-clés ou des tags\npour trouver du contenu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialUsersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Rechercher des utilisateurs',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tapez un nom ou @username\npour trouver des créateurs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPostsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun post trouvé',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés\nou ajustez vos filtres',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Consumer<SearchProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: provider.clearSearchFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Effacer les filtres'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUsersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez l\'orthographe ou\nessayez un autre nom',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Oups !',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ===== WIDGETS MANQUANTS (À CRÉER DANS LE DOSSIER widgets/) =====

// Widget pour la barre de recherche
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSubmitted;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher des posts, utilisateurs...',
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.black54),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
      ),
    );
  }
}

// Widget pour les suggestions (placeholder)
class SearchSuggestionsWidget extends StatelessWidget {
  final Function(SearchSuggestion) onSuggestionTap;

  const SearchSuggestionsWidget({
    super.key,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingSuggestions) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        if (provider.suggestions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Tapez pour voir des suggestions...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = provider.suggestions[index];
            return ListTile(
              leading: suggestion.isUser
                  ? CircleAvatar(
                      backgroundImage: suggestion.avatarUrl != null
                          ? NetworkImage(suggestion.avatarUrl!)
                          : null,
                      child: suggestion.avatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          suggestion.category?.emoji ?? '🏷️',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
              title: Text(suggestion.display),
              subtitle: Text(suggestion.isUser ? 'Utilisateur' : 'Tag'),
              onTap: () => onSuggestionTap(suggestion),
            );
          },
        );
      },
    );
  }
}

// Placeholders pour les autres widgets (à implémenter)
class TagsFilterWidget extends StatelessWidget {
  final bool isDiscoveryMode;

  const TagsFilterWidget({super.key, required this.isDiscoveryMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.grey[50],
      child: const Center(
        child: Text('Filtres Tags - À implémenter'),
      ),
    );
  }
}

class TrendingTagsWidget extends StatelessWidget {
  const TrendingTagsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.grey[50],
      child: const Center(
        child: Text('Tags Trending - À implémenter'),
      ),
    );
  }
}

class PostsGridWidget extends StatelessWidget {
  final List<PostWithDetails> posts;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final Function(PostWithDetails) onPostTap;

  const PostsGridWidget({
    super.key,
    required this.posts,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: posts.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= posts.length) {
          if (!isLoadingMore) onLoadMore();
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        final post = posts[index];
        return GestureDetector(
          onTap: () => onPostTap(post),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  post.mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              ),
              if (post.tags.isNotEmpty)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.tags.first.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${post.likesCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class UsersListWidget extends StatelessWidget {
  final List<UserSearchResult> users;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final Function(UserSearchResult) onUserTap;

  const UsersListWidget({
    super.key,
    required this.users,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= users.length) {
          if (!isLoadingMore) onLoadMore();
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        final user = users[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(user.firstName[0].toUpperCase())
                : null,
          ),
          title: Text(user.fullName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName),
              if (user.bio != null && user.bio!.isNotEmpty)
                Text(
                  user.bio!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.isCreator) const Icon(Icons.verified, color: Colors.blue, size: 16),
              Text('${user.followersCount} abonnés', style: const TextStyle(fontSize: 12)),
            ],
          ),
          onTap: () => onUserTap(user),
        );
      },
    );
  }
}

class DiscoveryFeedWidget extends StatelessWidget {
  final List<PostWithDetails> posts;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final Function(PostWithDetails) onPostTap;
  final Function(PostWithDetails) onLike;

  const DiscoveryFeedWidget({
    super.key,
    required this.posts,
    required this.hasMore,
    required this.isLoadingMore,
    required this.isRefreshing,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onPostTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= posts.length) {
            if (!isLoadingMore) onLoadMore();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.black),
              ),
            );
          }

          final post = posts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: post.author.avatarUrl != null
                        ? NetworkImage(post.author.avatarUrl!)
                        : null,
                    child: post.author.avatarUrl == null
                        ? Text(post.author.firstName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(post.author.fullName),
                  subtitle: Text(post.timeAgo),
                  trailing: post.author.isCreator
                      ? const Icon(Icons.verified, color: Colors.blue)
                      : null,
                ),
                GestureDetector(
                  onTap: () => onPostTap(post),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      post.mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => onLike(post),
                            child: Icon(
                              post.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: post.isLiked ? Colors.red : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${post.likesCount} likes'),
                          const Spacer(),
                          if (post.tags.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              children: post.tags.take(3).map((tag) {
                                return Text(
                                  tag.emoji,
                                  style: const TextStyle(fontSize: 16),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (post.description.isNotEmpty)
                        Text(
                          post.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
  }
}