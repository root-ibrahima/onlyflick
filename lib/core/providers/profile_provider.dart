import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../features/auth/models/auth_models.dart';
import '../../features/auth/auth_provider.dart';
import '../services/profile_service.dart';


/// Provider pour la gestion de l'état de la page profil
class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final AuthProvider _authProvider;

  // États de chargement
  bool _isLoadingStats = false;
  bool _isLoadingPosts = false;
  bool _isUploadingAvatar = false;
  bool _isUpdatingBio = false;

  // Données
  ProfileStats? _stats;
  List<UserPost> _userPosts = [];
  String _currentPostsType = 'all'; // 'all', 'public', 'subscriber'
  int _currentPage = 1;
  bool _hasMorePosts = true;

  // Erreurs
  String? _error;

  ProfileProvider(this._authProvider) {
    // Écouter les changements d'authentification
    _authProvider.addListener(_onAuthChanged);
    
    // Charger les données si l'utilisateur est connecté
    if (_authProvider.isAuthenticated) {
      _loadInitialData();
    }
  }

  // ===== GETTERS =====
  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isUpdatingBio => _isUpdatingBio;
  bool get isLoading => _isLoadingStats || _isLoadingPosts;

  ProfileStats get stats => _stats ?? ProfileStats.empty;
  List<UserPost> get userPosts => _userPosts;
  String get currentPostsType => _currentPostsType;
  bool get hasMorePosts => _hasMorePosts;
  String? get error => _error;
  bool get hasError => _error != null;

  User? get currentUser => _authProvider.user;
  bool get isCurrentUserCreator => currentUser?.isCreator ?? false;

  // ===== MÉTHODES PUBLIQUES =====

  /// Chargement initial des données du profil
  Future<void> loadProfileData() async {
    await _loadInitialData();
  }

  /// Actualisation complète des données
  Future<void> refresh() async {
    _clearError();
    await _loadInitialData();
  }

  /// Chargement des statistiques
  Future<void> loadStats() async {
    if (_isLoadingStats) return;

    _setLoadingStats(true);
    _clearError();

    try {
      debugPrint('📊 Loading profile stats...');
      final result = await _profileService.getProfileStats();

      if (result.isSuccess && result.data != null) {
        _stats = result.data;
        debugPrint('📊 Stats loaded: ${_stats!.postsCount} posts, ${_stats!.followersCount} followers');
      } else {
        _setError(result.error?.message ?? 'Erreur de chargement des statistiques');
      }
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
      _setError('Erreur de connexion');
    } finally {
      _setLoadingStats(false);
    }
  }

  /// Chargement des posts utilisateur
  Future<void> loadUserPosts({bool refresh = false}) async {
    if (_isLoadingPosts) return;

    if (refresh) {
      _currentPage = 1;
      _userPosts.clear();
      _hasMorePosts = true;
    }

    if (!_hasMorePosts) return;

    _setLoadingPosts(true);
    _clearError();

    try {
      debugPrint('📝 Loading user posts (page: $_currentPage, type: $_currentPostsType)...');
      final result = await _profileService.getUserPosts(
        page: _currentPage,
        type: _currentPostsType,
      );

      if (result.isSuccess && result.data != null) {
        final newPosts = result.data!;
        
        if (refresh) {
          _userPosts = newPosts;
        } else {
          _userPosts.addAll(newPosts);
        }

        _hasMorePosts = newPosts.length >= 20; // Si moins de 20 posts, pas de page suivante
        if (_hasMorePosts) _currentPage++;

        debugPrint('📝 Posts loaded: ${newPosts.length} new posts, ${_userPosts.length} total');
      } else {
        _setError(result.error?.message ?? 'Erreur de chargement des posts');
      }
    } catch (e) {
      debugPrint('❌ Error loading posts: $e');
      _setError('Erreur de connexion');
    } finally {
      _setLoadingPosts(false);
    }
  }

  /// Changement du type de posts à afficher
  Future<void> changePostsType(String type) async {
    if (_currentPostsType == type) return;

    _currentPostsType = type;
    await loadUserPosts(refresh: true);
  }

  /// Chargement de plus de posts (pagination)
  Future<void> loadMorePosts() async {
    if (!_hasMorePosts || _isLoadingPosts) return;
    await loadUserPosts();
  }

  /// Upload d'un nouvel avatar
  Future<bool> uploadAvatar(String imagePath) async {
    if (_isUploadingAvatar) return false;

    _setUploadingAvatar(true);
    _clearError();

    try {
      debugPrint('📸 Uploading avatar...');
      final result = await _profileService.uploadAvatar(imagePath);

      if (result.isSuccess && result.data != null) {
        debugPrint('📸 Avatar uploaded successfully: ${result.data!.avatarUrl}');
        
        // Actualiser le profil utilisateur dans AuthProvider
        await _authProvider.refreshProfile();
        
        return true;
      } else {
        _setError(result.error?.message ?? 'Erreur d\'upload de l\'avatar');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      _setError('Erreur de connexion');
      return false;
    } finally {
      _setUploadingAvatar(false);
    }
  }

  /// Mise à jour de la bio
  Future<bool> updateBio(String bio) async {
    if (_isUpdatingBio) return false;

    _setUpdatingBio(true);
    _clearError();

    try {
      debugPrint('📝 Updating bio...');
      final result = await _profileService.updateBio(bio);

      if (result.isSuccess && result.data != null) {
        debugPrint('📝 Bio updated successfully');
        
        // Actualiser le profil utilisateur dans AuthProvider
        await _authProvider.refreshProfile();
        
        return true;
      } else {
        _setError(result.error?.message ?? 'Erreur de mise à jour de la bio');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating bio: $e');
      _setError('Erreur de connexion');
      return false;
    } finally {
      _setUpdatingBio(false);
    }
  }

  /// Toggle like sur un post
  Future<void> togglePostLike(int postId) async {
    try {
      // Trouver le post dans la liste
      final postIndex = _userPosts.indexWhere((post) => post.id == postId);
      if (postIndex == -1) return;

      final post = _userPosts[postIndex];
      
      // Optimistic update
      final newLikesCount = post.isLiked ? post.likesCount - 1 : post.likesCount + 1;
      final updatedPost = UserPost(
        id: post.id,
        content: post.content,
        imageUrl: post.imageUrl,
        videoUrl: post.videoUrl,
        visibility: post.visibility,
        likesCount: newLikesCount,
        commentsCount: post.commentsCount,
        createdAt: post.createdAt,
        isLiked: !post.isLiked,
      );

      _userPosts[postIndex] = updatedPost;
      notifyListeners();

      // TODO: Appeler l'API pour toggle le like
      // Si l'API échoue, revenir en arrière
      
    } catch (e) {
      debugPrint('❌ Error toggling post like: $e');
      // Recharger les posts en cas d'erreur
      await loadUserPosts(refresh: true);
    }
  }

  /// Demande de passage en créateur
  Future<bool> requestCreatorUpgrade() async {
    try {
      debugPrint('🔄 Requesting creator upgrade...');
      final result = await _authProvider.requestCreatorUpgrade();
      
      if (result) {
        debugPrint('🔄 Creator upgrade requested successfully');
        return true;
      } else {
        _setError('Erreur lors de la demande de passage en créateur');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error requesting creator upgrade: $e');
      _setError('Erreur de connexion');
      return false;
    }
  }

  // ===== MÉTHODES PRIVÉES =====

  /// Chargement initial de toutes les données
  Future<void> _loadInitialData() async {
    if (!_authProvider.isAuthenticated) return;

    // Charger les statistiques et les posts en parallèle
    await Future.wait([
      loadStats(),
      loadUserPosts(refresh: true),
    ]);
  }

  /// Listener pour les changements d'authentification
  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      _loadInitialData();
    } else {
      _clearAllData();
    }
  }

  /// Efface toutes les données
  void _clearAllData() {
    _stats = null;
    _userPosts.clear();
    _currentPage = 1;
    _hasMorePosts = true;
    _clearError();
    notifyListeners();
  }

  /// Gestion des états de chargement
  void _setLoadingStats(bool loading) {
    _isLoadingStats = loading;
    notifyListeners();
  }

  void _setLoadingPosts(bool loading) {
    _isLoadingPosts = loading;
    notifyListeners();
  }

  void _setUploadingAvatar(bool uploading) {
    _isUploadingAvatar = uploading;
    notifyListeners();
  }

  void _setUpdatingBio(bool updating) {
    _isUpdatingBio = updating;
    notifyListeners();
  }

  /// Gestion des erreurs
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}