// lib/features/search/services/search_service.dart

import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/search_models.dart';

/// Service pour les opérations de recherche et découverte
class SearchService {
  final ApiService _apiService = ApiService();

  // ===== RECHERCHE D'UTILISATEURS =====

  /// Recherche des utilisateurs par nom/username
  Future<SearchOperationResult> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔍 Searching users: query="$query", limit=$limit, offset=$offset');

      final queryParams = {
        'q': query,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        '/search/users',
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        final users = (response.data!['users'] as List? ?? [])
            .map((user) => UserSearchResult.fromJson(user))
            .toList();

        final total = response.data!['total'] ?? 0;
        final hasMore = response.data!['has_more'] ?? false;

        final searchResult = SearchResult(
          posts: [],
          users: users,
          total: total,
          hasMore: hasMore,
        );

        debugPrint('✅ Users search successful: ${users.length} users found');
        return SearchOperationResult.success(searchResult);
      } else {
        debugPrint('❌ Users search failed: ${response.error}');
        return SearchOperationResult.failure(
          response.error ?? 'Erreur de recherche utilisateurs'
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Users search error: $e');
      debugPrint('Stack trace: $stackTrace');
      return SearchOperationResult.failure('Erreur inattendue lors de la recherche');
    }
  }

  // ===== RECHERCHE DE POSTS =====

  /// Recherche des posts avec filtres
  Future<SearchOperationResult> searchPosts({
    String? query,
    List<TagCategory> tags = const [],
    SortType sortBy = SortType.recent,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔍 Searching posts: query="$query", tags=${tags.length}, sortBy=$sortBy');

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        'sort': sortBy.value,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      if (tags.isNotEmpty) {
        queryParams['tags'] = tags.map((tag) => tag.value).join(',');
      }

      final response = await _apiService.get<SearchResult>(
        '/search/posts',
        queryParams: queryParams,
        fromJson: (json) => SearchResult.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Posts search successful: ${response.data!.posts.length} posts found');
        return SearchOperationResult.success(response.data!);
      } else {
        debugPrint('❌ Posts search failed: ${response.error}');
        return SearchOperationResult.failure(
          response.error ?? 'Erreur de recherche posts'
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Posts search error: $e');
      debugPrint('Stack trace: $stackTrace');
      return SearchOperationResult.failure('Erreur inattendue lors de la recherche');
    }
  }

  // ===== FEED DE DÉCOUVERTE =====

  /// Récupère le feed de découverte personnalisé
  Future<DiscoveryResult> getDiscoveryFeed({
    List<TagCategory> tags = const [],
    SortType sortBy = SortType.relevance,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('🎯 Fetching discovery feed: tags=${tags.length}, sortBy=$sortBy');

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        'sort': sortBy.value,
      };

      if (tags.isNotEmpty) {
        queryParams['tags'] = tags.map((tag) => tag.value).join(',');
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/discovery/feed',
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        final posts = (response.data!['posts'] as List? ?? [])
            .map((post) => PostWithDetails.fromJson(post))
            .toList();

        debugPrint('✅ Discovery feed successful: ${posts.length} posts retrieved');
        return DiscoveryResult.success(posts);
      } else {
        debugPrint('❌ Discovery feed failed: ${response.error}');
        return DiscoveryResult.failure(
          response.error ?? 'Erreur de chargement du feed découverte'
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Discovery feed error: $e');
      debugPrint('Stack trace: $stackTrace');
      return DiscoveryResult.failure('Erreur inattendue lors du chargement');
    }
  }

  // ===== GESTION DES TAGS =====

  /// Ajoute des tags à un post
  Future<bool> addPostTags({
    required int postId,
    required List<TagCategory> tags,
  }) async {
    try {
      debugPrint('🏷️ Adding tags to post $postId: ${tags.map((t) => t.displayName).join(', ')}');

      final body = {
        'tags': tags.map((tag) => tag.value).toList(),
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        '/posts/$postId/tags',
        body: body,
      );

      if (response.isSuccess) {
        debugPrint('✅ Tags added successfully to post $postId');
        return true;
      } else {
        debugPrint('❌ Failed to add tags: ${response.error}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Add tags error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Récupère les tags d'un post
  Future<List<TagCategory>> getPostTags(int postId) async {
    try {
      debugPrint('🏷️ Fetching tags for post $postId');

      final response = await _apiService.get<Map<String, dynamic>>(
        '/posts/$postId/tags',
      );

      if (response.isSuccess && response.data != null) {
        final tagsData = response.data!['tags'] as List? ?? [];
        final tags = tagsData
            .map((tagData) => TagCategory.fromString(tagData['category'] ?? ''))
            .where((tag) => tag != null)
            .cast<TagCategory>()
            .toList();

        debugPrint('✅ Tags retrieved for post $postId: ${tags.length} tags');
        return tags;
      } else {
        debugPrint('❌ Failed to get tags: ${response.error}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Get tags error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Récupère les tags en tendance
  Future<List<TrendingTag>> getTrendingTags({
    String period = 'week',
    int limit = 10,
  }) async {
    try {
      debugPrint('📈 Fetching trending tags: period=$period, limit=$limit');

      final queryParams = {
        'period': period,
        'limit': limit.toString(),
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        '/trending/tags',
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        final trendsData = response.data!['trending_tags'] as List? ?? [];
        final trends = trendsData
            .map((trendData) => TrendingTag.fromJson(trendData))
            .toList();

        debugPrint('✅ Trending tags retrieved: ${trends.length} trends');
        return trends;
      } else {
        debugPrint('❌ Failed to get trending tags: ${response.error}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Trending tags error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  // ===== TRACKING DES INTERACTIONS =====

  /// Enregistre une interaction utilisateur
  Future<bool> trackInteraction({
    required InteractionType interactionType,
    required String contentType,
    required int contentId,
    String? contentMeta,
  }) async {
    try {
      debugPrint('📊 Tracking interaction: ${interactionType.value} on $contentType:$contentId');

      final body = {
        'interaction_type': interactionType.value,
        'content_type': contentType,
        'content_id': contentId,
        if (contentMeta != null) 'content_meta': contentMeta,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        '/interactions/track',
        body: body,
      );

      if (response.isSuccess) {
        debugPrint('✅ Interaction tracked successfully');
        return true;
      } else {
        debugPrint('❌ Failed to track interaction: ${response.error}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Track interaction error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // ===== PRÉFÉRENCES UTILISATEUR =====

  /// Récupère les préférences calculées de l'utilisateur
  Future<UserPreferences?> getUserPreferences() async {
    try {
      debugPrint('⚙️ Fetching user preferences');

      final response = await _apiService.get<UserPreferences>(
        '/preferences',
        fromJson: (json) => UserPreferences.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ User preferences retrieved');
        return response.data;
      } else {
        debugPrint('❌ Failed to get user preferences: ${response.error}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ User preferences error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // ===== SUGGESTIONS DE RECHERCHE =====

  /// Récupère des suggestions de recherche
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    try {
      if (query.length < 2) return [];

      debugPrint('💡 Fetching search suggestions for: "$query"');

      final queryParams = {'q': query};

      final response = await _apiService.get<Map<String, dynamic>>(
        '/search/suggestions',
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        final suggestionsData = response.data!['suggestions'] as List? ?? [];
        final suggestions = suggestionsData
            .map((suggestionData) => SearchSuggestion.fromJson(suggestionData))
            .toList();

        debugPrint('✅ Search suggestions retrieved: ${suggestions.length} suggestions');
        return suggestions;
      } else {
        debugPrint('❌ Failed to get suggestions: ${response.error}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Search suggestions error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  // ===== STATISTIQUES =====

  /// Récupère les statistiques de recherche de l'utilisateur
  Future<Map<String, dynamic>?> getSearchStats() async {
    try {
      debugPrint('📊 Fetching search stats');

      final response = await _apiService.get<Map<String, dynamic>>(
        '/search/stats',
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Search stats retrieved');
        return response.data;
      } else {
        debugPrint('❌ Failed to get search stats: ${response.error}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Search stats error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // ===== MÉTHODES UTILITAIRES =====

  /// Track automatiquement une vue de post
  Future<void> trackPostView(int postId) async {
    await trackInteraction(
      interactionType: InteractionType.view,
      contentType: 'post',
      contentId: postId,
    );
  }

  /// Track automatiquement un clic sur tag
  Future<void> trackTagClick(TagCategory tag, {int? postId}) async {
    await trackInteraction(
      interactionType: InteractionType.tagClick,
      contentType: 'tag',
      contentId: postId ?? 0,
      contentMeta: tag.value,
    );
  }

  /// Track automatiquement une recherche
  Future<void> trackSearch(String query) async {
    await trackInteraction(
      interactionType: InteractionType.search,
      contentType: 'search',
      contentId: 0,
      contentMeta: query,
    );
  }

  /// Track automatiquement une vue de profil
  Future<void> trackProfileView(int userId) async {
    await trackInteraction(
      interactionType: InteractionType.profileView,
      contentType: 'user',
      contentId: userId,
    );
  }

  // ===== RECHERCHE COMBINÉE =====

  /// Recherche combinée posts + utilisateurs
  Future<SearchOperationResult> searchAll({
    required String query,
    List<TagCategory> tags = const [],
    SortType sortBy = SortType.relevance,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔍 Combined search: query="$query", tags=${tags.length}');

      // Track la recherche
      if (query.isNotEmpty) {
        trackSearch(query);
      }

      // Recherche des posts
      final postsResult = await searchPosts(
        query: query,
        tags: tags,
        sortBy: sortBy,
        limit: limit ~/ 2, // Diviser la limite entre posts et users
        offset: offset,
      );

      // Recherche des utilisateurs (seulement si on a un terme de recherche)
      SearchOperationResult usersResult = SearchOperationResult.success(
        const SearchResult(posts: [], users: [], total: 0, hasMore: false)
      );

      if (query.isNotEmpty) {
        usersResult = await searchUsers(
          query: query,
          limit: limit ~/ 2,
          offset: offset,
        );
      }

      if (postsResult.isSuccess && usersResult.isSuccess) {
        final combinedResult = SearchResult(
          posts: postsResult.data?.posts ?? [],
          users: usersResult.data?.users ?? [],
          total: (postsResult.data?.total ?? 0) + (usersResult.data?.total ?? 0),
          hasMore: (postsResult.data?.hasMore ?? false) || (usersResult.data?.hasMore ?? false),
        );

        debugPrint('✅ Combined search successful: ${combinedResult.posts.length} posts, ${combinedResult.users.length} users');
        return SearchOperationResult.success(combinedResult);
      } else {
        final error = postsResult.error ?? usersResult.error ?? 'Erreur de recherche';
        debugPrint('❌ Combined search failed: $error');
        return SearchOperationResult.failure(error);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Combined search error: $e');
      debugPrint('Stack trace: $stackTrace');
      return SearchOperationResult.failure('Erreur inattendue lors de la recherche');
    }
  }

  // ===== CACHE ET OPTIMISATIONS =====

  /// Cache simple pour les suggestions
  final Map<String, List<SearchSuggestion>> _suggestionsCache = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Récupère des suggestions avec cache
  Future<List<SearchSuggestion>> getCachedSuggestions(String query) async {
    if (query.length < 2) return [];

    final cacheKey = query.toLowerCase();
    final timestamp = _cacheTimestamps[cacheKey];
    final cached = _suggestionsCache[cacheKey];

    // Vérifier si le cache est valide
    if (cached != null && 
        timestamp != null && 
        DateTime.now().difference(timestamp) < _cacheTimeout) {
      debugPrint('📦 Using cached suggestions for: "$query"');
      return cached;
    }

    // Récupérer de nouvelles suggestions
    final suggestions = await getSearchSuggestions(query);
    
    // Mettre en cache
    _suggestionsCache[cacheKey] = suggestions;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Nettoyer le cache si trop d'entrées
    if (_suggestionsCache.length > 100) {
      _clearOldCache();
    }

    return suggestions;
  }

  /// Nettoie les entrées anciennes du cache
  void _clearOldCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheTimeout) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _suggestionsCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    debugPrint('🧹 Cache cleaned: removed ${keysToRemove.length} old entries');
  }

  /// Vide complètement le cache
  void clearCache() {
    _suggestionsCache.clear();
    _cacheTimestamps.clear();
    debugPrint('🧹 Search cache cleared');
  }
}