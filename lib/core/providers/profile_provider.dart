// lib/features/profile/profile_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../features/auth/auth_provider.dart';
import '../models/profile_models.dart'; 
import '../../features/auth/models/auth_models.dart';
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
  bool _isCheckingUsername = false;

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
  bool get isCheckingUsername => _isCheckingUsername;
  bool get isLoading => _isLoadingStats || _isLoadingPosts;

  ProfileStats get stats => _stats ?? ProfileStats.empty();
  List<UserPost> get userPosts => _userPosts;
  String get currentPostsType => _currentPostsType;
  bool get hasMorePosts => _hasMorePosts;
  String? get error => _error;

  // ===== MÉTHODES PUBLIQUES =====

  /// Charge toutes les données du profil
  Future<void> loadProfileData() async {
    if (!_authProvider.isAuthenticated) return;
    
    debugPrint('🔄 Loading complete profile data');
    await _loadInitialData();
  }

  /// Rafraîchit toutes les données
  Future<void> refreshAllData() async {
    if (!_authProvider.isAuthenticated) return;
    
    debugPrint('🔄 Refreshing all profile data');
    _clearError();
    
    await Future.wait([
      loadStats(),
      loadUserPosts(refresh: true),
    ]);
  }

  /// Charge les statistiques du profil
  Future<void> loadStats() async {
    if (!_authProvider.isAuthenticated) return;
    
    _setLoadingStats(true);
    _clearError();
    
    try {
      final result = await _profileService.getProfileStats();
      
      if (result.isSuccess && result.data != null) {
        _stats = result.data;
        debugPrint('📊 Stats loaded: ${_stats.toString()}');
      } else {
        _setError(result.error?.message ?? 'Erreur de chargement des statistiques');
      }
    } catch (e) {
      _setError('Erreur inattendue lors du chargement des statistiques');
      debugPrint('❌ Stats loading error: $e');
    } finally {
      _setLoadingStats(false);
    }
  }

  /// Charge les posts de l'utilisateur
  Future<void> loadUserPosts({bool refresh = false, String? type}) async {
    if (!_authProvider.isAuthenticated) return;
    
    // Si on refresh ou change de type, réinitialiser
    if (refresh || (type != null && type != _currentPostsType)) {
      _userPosts.clear();
      _currentPage = 1;
      _hasMorePosts = true;
      if (type != null) _currentPostsType = type;
    }
    
    // Si plus de posts disponibles, arrêter
    if (!_hasMorePosts) return;
    
    _setLoadingPosts(true);
    if (refresh) _clearError();
    
    try {
      final result = await _profileService.getUserPosts(
        page: _currentPage,
        limit: 20,
        type: _currentPostsType,
      );
      
      if (result.isSuccess && result.data != null) {
        final newPosts = result.data!;
        
        if (refresh || _currentPage == 1) {
          _userPosts = newPosts;
        } else {
          _userPosts.addAll(newPosts);
        }
        
        // Vérifier s'il y a plus de posts
        _hasMorePosts = newPosts.length >= 20;
        _currentPage++;
        
        debugPrint('📝 Posts loaded: ${newPosts.length} (total: ${_userPosts.length})');
      } else {
        _setError(result.error?.message ?? 'Erreur de chargement des posts');
      }
    } catch (e) {
      _setError('Erreur inattendue lors du chargement des posts');
      debugPrint('❌ Posts loading error: $e');
    } finally {
      _setLoadingPosts(false);
    }
  }

  /// Charge plus de posts (pagination)
  Future<void> loadMorePosts() async {
    if (!_hasMorePosts || _isLoadingPosts) return;
    
    debugPrint('📝 Loading more posts (page $_currentPage)');
    await loadUserPosts();
  }

  /// Change le type de posts affichés
  Future<void> changePostsType(String type) async {
    if (type == _currentPostsType) return;
    
    debugPrint('🔄 Changing posts type to: $type');
    await loadUserPosts(refresh: true, type: type);
  }

  /// Upload d'avatar
  Future<bool> uploadAvatar(File imageFile) async {
    if (!_authProvider.isAuthenticated) return false;
    
    _setUploadingAvatar(true);
    _clearError();
    
    try {
      final result = await _profileService.uploadAvatar(imageFile);
      
      if (result.isSuccess && result.data != null) {
        // Mettre à jour l'avatar dans l'AuthProvider
        await _authProvider.refreshProfile();
        
        debugPrint('📤 Avatar uploaded successfully: ${result.data!.avatarUrl}');
        return true;
      } else {
        _setError(result.error?.message ?? 'Erreur lors de l\'upload de l\'avatar');
        return false;
      }
    } catch (e) {
      _setError('Erreur inattendue lors de l\'upload');
      debugPrint('❌ Avatar upload error: $e');
      return false;
    } finally {
      _setUploadingAvatar(false);
    }
  }

  /// Mise à jour de la bio
  Future<bool> updateBio(String bio) async {
    if (!_authProvider.isAuthenticated) return false;
    
    _setUpdatingBio(true);
    _clearError();
    
    try {
      final result = await _profileService.updateBio(bio);
      
      if (result.isSuccess) {
        // Mettre à jour la bio dans l'AuthProvider
        await _authProvider.refreshProfile();
        
        debugPrint('📝 Bio updated successfully');
        return true;
      } else {
        _setError(result.error?.message ?? 'Erreur lors de la mise à jour de la bio');
        return false;
      }
    } catch (e) {
      _setError('Erreur inattendue lors de la mise à jour');
      debugPrint('❌ Bio update error: $e');
      return false;
    } finally {
      _setUpdatingBio(false);
    }
  }

  /// Vérification de disponibilité d'un username
  Future<bool?> checkUsernameAvailability(String username) async {
    if (!_authProvider.isAuthenticated) return null;
    
    _setCheckingUsername(true);
    
    try {
      final result = await _profileService.checkUsernameAvailability(username);
      
      if (result.isSuccess && result.data != null) {
        debugPrint('🔍 Username check: ${result.data!.username} available: ${result.data!.available}');
        return result.data!.available;
      } else {
        debugPrint('❌ Username check failed: ${result.error?.message}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Username check error: $e');
      return null;
    } finally {
      _setCheckingUsername(false);
    }
  }

  /// Toggle like sur un post (pour les grilles de posts)
  Future<void> togglePostLike(int postId) async {
    if (!_authProvider.isAuthenticated) return;
    
    // Trouver le post dans la liste
    final postIndex = _userPosts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;
    
    final post = _userPosts[postIndex];
    
    // Mise à jour optimiste de l'UI
    final updatedPost = post.copyWith(
      likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      isLiked: !post.isLiked,
    );
    
    _userPosts[postIndex] = updatedPost;
    notifyListeners();
    
    // TODO: Appeler l'API pour liker/unliker le post
    // Cette fonctionnalité sera implémentée avec le PostsService
    debugPrint('👍 Post $postId like toggled (optimistic update)');
  }

  /// Efface l'erreur courante
  void clearError() {
    _clearError();
  }

  // ===== MÉTHODES PRIVÉES =====

  /// Chargement initial de toutes les données
  Future<void> _loadInitialData() async {
    if (!_authProvider.isAuthenticated) return;

    debugPrint('🔄 Loading initial profile data');
    
    // Charger les statistiques et les posts en parallèle
    await Future.wait([
      loadStats(),
      loadUserPosts(refresh: true),
    ]);
  }

  /// Listener pour les changements d'authentification
  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      debugPrint('👤 User authenticated - loading profile data');
      _loadInitialData();
    } else {
      debugPrint('👤 User logged out - clearing profile data');
      _clearAllData();
    }
  }

  /// Efface toutes les données
  void _clearAllData() {
    _stats = null;
    _userPosts.clear();
    _currentPage = 1;
    _hasMorePosts = true;
    _currentPostsType = 'all';
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

  void _setCheckingUsername(bool checking) {
    _isCheckingUsername = checking;
    notifyListeners();
  }

  /// Gestion des erreurs
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}