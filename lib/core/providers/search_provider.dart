// lib/features/search/providers/search_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/search_models.dart';
import '../services/search_service.dart';

/// États possibles pour la recherche
enum SearchState {
  initial,
  loading,
  loaded,
  error,
  loadingMore,
}

/// États pour la découverte
enum DiscoveryState {
  initial,
  loading,
  loaded,
  error,
  refreshing,
  loadingMore,
}

/// Provider pour la gestion de l'état de recherche et découverte
class SearchProvider with ChangeNotifier {
  final SearchService _searchService = SearchService();

  // ===== ÉTAT DE LA RECHERCHE =====
  SearchState _searchState = SearchState.initial;
  SearchResult _searchResult = const SearchResult(posts: [], users: [], total: 0, hasMore: false);
  String? _searchError;
  String _currentQuery = '';
  List<TagCategory> _selectedTags = [];
  SortType _currentSort = SortType.relevance;
  
  // ===== ÉTAT DE LA DÉCOUVERTE =====
  DiscoveryState _discoveryState = DiscoveryState.initial;
  List<PostWithDetails> _discoveryPosts = [];
  String? _discoveryError;
  List<TagCategory> _discoveryTags = [];
  SortType _discoverySort = SortType.relevance;
  bool _hasMoreDiscovery = true;

  // ===== SUGGESTIONS =====
  List<SearchSuggestion> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _suggestionTimer;

  // ===== TAGS TRENDING =====
  List<TrendingTag> _trendingTags = [];
  bool _isLoadingTrending = false;

  // ===== PRÉFÉRENCES =====
  UserPreferences? _userPreferences;

  // ===== PAGINATION =====
  static const int _pageSize = 20;
  int _searchOffset = 0;
  int _discoveryOffset = 0;

  // ===== GETTERS RECHERCHE =====
  SearchState get searchState => _searchState;
  SearchResult get searchResult => _searchResult;
  String? get searchError => _searchError;
  String get currentQuery => _currentQuery;
  List<TagCategory> get selectedTags => List.unmodifiable(_selectedTags);
  SortType get currentSort => _currentSort;
  bool get isSearching => _searchState == SearchState.loading;
  bool get isLoadingMoreSearch => _searchState == SearchState.loadingMore;
  bool get hasSearchResults => _searchResult.isNotEmpty;
  bool get hasMoreSearchResults => _searchResult.hasMore;

  // ===== GETTERS DÉCOUVERTE =====
  DiscoveryState get discoveryState => _discoveryState;
  List<PostWithDetails> get discoveryPosts => List.unmodifiable(_discoveryPosts);
  String? get discoveryError => _discoveryError;
  List<TagCategory> get discoveryTags => List.unmodifiable(_discoveryTags);
  SortType get discoverySort => _discoverySort;
  bool get isLoadingDiscovery => _discoveryState == DiscoveryState.loading || _discoveryState == DiscoveryState.refreshing;
  bool get isLoadingMoreDiscovery => _discoveryState == DiscoveryState.loadingMore;
  bool get hasDiscoveryPosts => _discoveryPosts.isNotEmpty;
  bool get hasMoreDiscovery => _hasMoreDiscovery;

  // ===== GETTERS SUGGESTIONS =====
  List<SearchSuggestion> get suggestions => List.unmodifiable(_suggestions);
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  // ===== GETTERS TRENDING =====
  List<TrendingTag> get trendingTags => List.unmodifiable(_trendingTags);
  bool get isLoadingTrending => _isLoadingTrending;

  // ===== GETTERS PRÉFÉRENCES =====
  UserPreferences? get userPreferences => _userPreferences;
  List<TagCategory> get preferredTags => _userPreferences?.topTags ?? [];

  // ===== MÉTHODES DE RECHERCHE =====

  /// Lance une nouvelle recherche
  Future<void> search({
    required String query,
    List<TagCategory>? tags,
    SortType? sortBy,
    bool resetResults = true,
  }) async {
    if (query.trim().isEmpty && (tags?.isEmpty ?? true)) {
      clearSearch();
      return;
    }

    try {
      _currentQuery = query.trim();
      _selectedTags = tags ?? _selectedTags;
      _currentSort = sortBy ?? _currentSort;

      if (resetResults) {
        _searchOffset = 0;
        _searchState = SearchState.loading;
        _searchError = null;
      } else {
        _searchState = SearchState.loadingMore;
      }
      notifyListeners();

      debugPrint('🔍 Searching: query="$_currentQuery", tags=${_selectedTags.length}');

      final result = await _searchService.searchAll(
        query: _currentQuery,
        tags: _selectedTags,
        sortBy: _currentSort,
        limit: _pageSize,
        offset: _searchOffset,
      );

      if (result.isSuccess) {
        if (resetResults) {
          _searchResult = result.data!;
        } else {
          // Ajouter aux résultats existants
          _searchResult = _searchResult.copyWith(
            posts: [..._searchResult.posts, ...result.data!.posts],
            users: [..._searchResult.users, ...result.data!.users],
            total: result.data!.total,
            hasMore: result.data!.hasMore,
          );
        }
        _searchOffset += _pageSize;
        _searchState = SearchState.loaded;
        _searchError = null;

        debugPrint('✅ Search completed: ${_searchResult.posts.length} posts, ${_searchResult.users.length} users');
      } else {
        _searchState = SearchState.error;
        _searchError = result.error;
        debugPrint('❌ Search failed: ${result.error}');
      }
    } catch (e, stackTrace) {
      _searchState = SearchState.error;
      _searchError = 'Erreur inattendue lors de la recherche';
      debugPrint('❌ Search error: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    notifyListeners();
  }

  /// Charge plus de résultats de recherche
  Future<void> loadMoreSearchResults() async {
    if (!_searchResult.hasMore || _searchState == SearchState.loadingMore) return;

    await search(
      query: _currentQuery,
      tags: _selectedTags,
      sortBy: _currentSort,
      resetResults: false,
    );
  }

  /// Efface les résultats de recherche
  void clearSearch() {
    _searchState = SearchState.initial;
    _searchResult = const SearchResult(posts: [], users: [], total: 0, hasMore: false);
    _searchError = null;
    _currentQuery = '';
    _searchOffset = 0;
    notifyListeners();
  }

  // ===== MÉTHODES DE DÉCOUVERTE =====

  /// Charge le feed de découverte
  Future<void> loadDiscoveryFeed({
    List<TagCategory>? tags,
    SortType? sortBy,
    bool refresh = false,
  }) async {
    try {
      _discoveryTags = tags ?? _discoveryTags;
      _discoverySort = sortBy ?? _discoverySort;

      if (refresh || _discoveryState == DiscoveryState.initial) {
        _discoveryOffset = 0;
        _discoveryState = refresh ? DiscoveryState.refreshing : DiscoveryState.loading;
        _discoveryError = null;
      } else {
        _discoveryState = DiscoveryState.loadingMore;
      }
      notifyListeners();

      debugPrint('🎯 Loading discovery feed: tags=${_discoveryTags.length}, sort=$_discoverySort');

      final result = await _searchService.getDiscoveryFeed(
        tags: _discoveryTags,
        sortBy: _discoverySort,
        limit: _pageSize,
        offset: _discoveryOffset,
      );

      if (result.isSuccess) {
        if (refresh || _discoveryOffset == 0) {
          _discoveryPosts = result.posts!;
        } else {
          _discoveryPosts.addAll(result.posts!);
        }
        
        _hasMoreDiscovery = result.posts!.length == _pageSize;
        _discoveryOffset += _pageSize;
        _discoveryState = DiscoveryState.loaded;
        _discoveryError = null;

        debugPrint('✅ Discovery feed loaded: ${_discoveryPosts.length} total posts');
      } else {
        _discoveryState = DiscoveryState.error;
        _discoveryError = result.error;
        debugPrint('❌ Discovery feed failed: ${result.error}');
      }
    } catch (e, stackTrace) {
      _discoveryState = DiscoveryState.error;
      _discoveryError = 'Erreur inattendue lors du chargement';
      debugPrint('❌ Discovery feed error: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    notifyListeners();
  }

  /// Rafraîchit le feed de découverte
  Future<void> refreshDiscoveryFeed() async {
    await loadDiscoveryFeed(refresh: true);
  }

  /// Charge plus de posts de découverte
  Future<void> loadMoreDiscoveryPosts() async {
    if (!_hasMoreDiscovery || _discoveryState == DiscoveryState.loadingMore) return;

    await loadDiscoveryFeed();
  }

  // ===== MÉTHODES DES FILTRES =====

  /// Ajoute ou retire un tag des filtres de recherche
  void toggleSearchTag(TagCategory tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();

    // Relancer la recherche si on a une query
    if (_currentQuery.isNotEmpty) {
      search(
        query: _currentQuery,
        tags: _selectedTags,
        sortBy: _currentSort,
      );
    }

    // Track l'interaction
    _searchService.trackTagClick(tag);
  }

  /// Change le tri de recherche
  void changeSearchSort(SortType sortType) {
    if (_currentSort == sortType) return;

    _currentSort = sortType;
    notifyListeners();

    // Relancer la recherche si on a des résultats
    if (_currentQuery.isNotEmpty || _selectedTags.isNotEmpty) {
      search(
        query: _currentQuery,
        tags: _selectedTags,
        sortBy: _currentSort,
      );
    }
  }

  /// Ajoute ou retire un tag des filtres de découverte
  void toggleDiscoveryTag(TagCategory tag) {
    if (_discoveryTags.contains(tag)) {
      _discoveryTags.remove(tag);
    } else {
      _discoveryTags.add(tag);
    }
    notifyListeners();

    // Relancer la découverte
    loadDiscoveryFeed(tags: _discoveryTags, sortBy: _discoverySort, refresh: true);

    // Track l'interaction
    _searchService.trackTagClick(tag);
  }

  /// Change le tri de découverte
  void changeDiscoverySort(SortType sortType) {
    if (_discoverySort == sortType) return;

    _discoverySort = sortType;
    notifyListeners();

    // Relancer la découverte
    loadDiscoveryFeed(tags: _discoveryTags, sortBy: _discoverySort, refresh: true);
  }

  /// Efface tous les filtres de recherche
  void clearSearchFilters() {
    _selectedTags.clear();
    _currentSort = SortType.relevance;
    notifyListeners();

    // Relancer la recherche si on a une query
    if (_currentQuery.isNotEmpty) {
      search(query: _currentQuery);
    }
  }

  /// Efface tous les filtres de découverte
  void clearDiscoveryFilters() {
    _discoveryTags.clear();
    _discoverySort = SortType.relevance;
    notifyListeners();

    // Relancer la découverte
    loadDiscoveryFeed(refresh: true);
  }

  // ===== MÉTHODES DES SUGGESTIONS =====

  /// Charge les suggestions pour une query
  Future<void> loadSuggestions(String query) async {
    // Annuler le timer précédent
    _suggestionTimer?.cancel();

    if (query.length < 2) {
      _suggestions.clear();
      notifyListeners();
      return;
    }

    // Debounce de 300ms
    _suggestionTimer = Timer(const Duration(milliseconds: 300), () async {
      await _loadSuggestionsNow(query);
    });
  }

  Future<void> _loadSuggestionsNow(String query) async {
    try {
      _isLoadingSuggestions = true;
      notifyListeners();

      debugPrint('💡 Loading suggestions for: "$query"');

      final suggestions = await _searchService.getCachedSuggestions(query);
      _suggestions = suggestions;

      debugPrint('✅ Suggestions loaded: ${suggestions.length} suggestions');
    } catch (e, stackTrace) {
      debugPrint('❌ Suggestions error: $e');
      debugPrint('Stack trace: $stackTrace');
      _suggestions.clear();
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }

  /// Efface les suggestions
  void clearSuggestions() {
    _suggestions.clear();
    _suggestionTimer?.cancel();
    notifyListeners();
  }

  // ===== MÉTHODES DES TAGS TRENDING =====

  /// Charge les tags en tendance
  Future<void> loadTrendingTags({String period = 'week'}) async {
    try {
      _isLoadingTrending = true;
      notifyListeners();

      debugPrint('📈 Loading trending tags for period: $period');

      final tags = await _searchService.getTrendingTags(period: period);
      _trendingTags = tags;

      debugPrint('✅ Trending tags loaded: ${tags.length} tags');
    } catch (e, stackTrace) {
      debugPrint('❌ Trending tags error: $e');
      debugPrint('Stack trace: $stackTrace');
      _trendingTags.clear();
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  // ===== MÉTHODES DES PRÉFÉRENCES =====

  /// Charge les préférences utilisateur
  Future<void> loadUserPreferences() async {
    try {
      debugPrint('⚙️ Loading user preferences');

      final preferences = await _searchService.getUserPreferences();
      _userPreferences = preferences;

      debugPrint('✅ User preferences loaded');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ User preferences error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // ===== MÉTHODES DE TRACKING =====

  /// Track une vue de post
  Future<void> trackPostView(PostWithDetails post) async {
    await _searchService.trackPostView(post.id);
    
    // Mettre à jour le post dans les résultats si nécessaire
    _updatePostInResults(post.copyWith(viewsCount: post.viewsCount + 1));
  }

  /// Track un clic sur profil
  Future<void> trackProfileView(UserSearchResult user) async {
    await _searchService.trackProfileView(user.id);
  }

  /// Met à jour un post dans les résultats
  void _updatePostInResults(PostWithDetails updatedPost) {
    // Mettre à jour dans les résultats de recherche
    final searchIndex = _searchResult.posts.indexWhere((p) => p.id == updatedPost.id);
    if (searchIndex != -1) {
      final newPosts = List<PostWithDetails>.from(_searchResult.posts);
      newPosts[searchIndex] = updatedPost;
      _searchResult = _searchResult.copyWith(posts: newPosts);
    }

    // Mettre à jour dans la découverte
    final discoveryIndex = _discoveryPosts.indexWhere((p) => p.id == updatedPost.id);
    if (discoveryIndex != -1) {
      _discoveryPosts[discoveryIndex] = updatedPost;
    }

    notifyListeners();
  }

  // ===== MÉTHODES D'INTERACTIONS =====

  /// Like/Unlike un post
  Future<void> togglePostLike(PostWithDetails post) async {
    final newIsLiked = !post.isLiked;
    final newLikesCount = newIsLiked ? post.likesCount + 1 : post.likesCount - 1;

    // Mise à jour optimiste
    final updatedPost = post.copyWith(
      isLiked: newIsLiked,
      likesCount: newLikesCount,
    );
    _updatePostInResults(updatedPost);

    // Track l'interaction
    if (newIsLiked) {
      await _searchService.trackInteraction(
        interactionType: InteractionType.like,
        contentType: 'post',
        contentId: post.id,
      );
    }
  }

  /// Applique des filtres rapides basés sur les préférences
  void applyPreferredFilters() {
    if (_userPreferences == null) return;

    final topTags = _userPreferences!.topTags.take(3).toList();
    _selectedTags = topTags;
    _currentSort = SortType.relevance;
    notifyListeners();

    // Lancer une recherche si on a une query
    if (_currentQuery.isNotEmpty) {
      search(
        query: _currentQuery,
        tags: _selectedTags,
        sortBy: _currentSort,
      );
    }
  }

  // ===== MÉTHODES DE RESET =====

  /// Reset complet du provider
  void reset() {
    clearSearch();
    _discoveryState = DiscoveryState.initial;
    _discoveryPosts.clear();
    _discoveryError = null;
    _discoveryTags.clear();
    _discoverySort = SortType.relevance;
    _hasMoreDiscovery = true;
    _discoveryOffset = 0;
    
    clearSuggestions();
    _trendingTags.clear();
    _userPreferences = null;

    notifyListeners();
  }

  /// Initialise le provider (à appeler après connexion)
  Future<void> initialize() async {
    debugPrint('🚀 Initializing SearchProvider');
    
    // Charger les données initiales en parallèle
    await Future.wait([
      loadUserPreferences(),
      loadTrendingTags(),
      loadDiscoveryFeed(),
    ]);

    debugPrint('✅ SearchProvider initialized');
  }

  @override
  void dispose() {
    _suggestionTimer?.cancel();
    _searchService.clearCache();
    super.dispose();
  }
}