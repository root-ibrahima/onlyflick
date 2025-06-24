import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../../features/auth/models/auth_models.dart';


/// Service pour les opérations de profil utilisateur
class ProfileService {
  final ApiService _apiService = ApiService();

  /// Récupération des statistiques du profil
  Future<ProfileStatsResult> getProfileStats() async {
    try {
      debugPrint('📊 Fetching profile stats');
      
      final response = await _apiService.get<ProfileStats>(
        '/profile/stats',
        fromJson: (json) => ProfileStats.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('📊 Profile stats fetched successfully');
        return ProfileStatsResult.success(response.data!);
      } else {
        debugPrint('❌ Failed to fetch profile stats: ${response.error}');
        return ProfileStatsResult.failure(
          AuthError.fromApiResponse(
            response.error ?? 'Erreur de récupération des statistiques',
            response.statusCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Profile stats fetch error: $e');
      return ProfileStatsResult.failure(AuthError.network());
    }
  }

  /// Récupération des posts de l'utilisateur
  Future<UserPostsResult> getUserPosts({
    int page = 1,
    int limit = 20,
    String type = 'all', // 'all', 'public', 'subscriber'
  }) async {
    try {
      debugPrint('📝 Fetching user posts (page: $page, type: $type)');
      
      final response = await _apiService.get<List<UserPost>>(
        '/profile/posts?page=$page&limit=$limit&type=$type',
        fromJson: (json) => (json as List)
            .map((item) => UserPost.fromJson(item))
            .toList(),
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('📝 User posts fetched successfully (${response.data!.length} posts)');
        return UserPostsResult.success(response.data!);
      } else {
        debugPrint('❌ Failed to fetch user posts: ${response.error}');
        return UserPostsResult.failure(
          AuthError.fromApiResponse(
            response.error ?? 'Erreur de récupération des posts',
            response.statusCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ User posts fetch error: $e');
      return UserPostsResult.failure(AuthError.network());
    }
  }

  /// Upload d'avatar
  Future<AvatarUploadResult> uploadAvatar(String imagePath) async {
    try {
      debugPrint('📸 Uploading avatar');
      
      final response = await _apiService.postMultipart<AvatarUploadResponse>(
        '/profile/avatar',
        filePath: imagePath,
        fieldName: 'avatar',
        fromJson: (json) => AvatarUploadResponse.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('📸 Avatar uploaded successfully');
        return AvatarUploadResult.success(response.data!);
      } else {
        debugPrint('❌ Failed to upload avatar: ${response.error}');
        return AvatarUploadResult.failure(
          AuthError.fromApiResponse(
            response.error ?? 'Erreur d\'upload de l\'avatar',
            response.statusCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Avatar upload error: $e');
      return AvatarUploadResult.failure(AuthError.network());
    }
  }

  /// Mise à jour de la bio
  Future<UserResult> updateBio(String bio) async {
    try {
      debugPrint('📝 Updating bio');
      
      final response = await _apiService.patch<Map<String, dynamic>>(
        '/profile/bio',
        body: {'bio': bio},
      );

      if (response.isSuccess) {
        debugPrint('📝 Bio updated successfully');
        // Retourner le profil mis à jour
        final authService = AuthService();
        return await authService.getProfile();
      } else {
        debugPrint('❌ Failed to update bio: ${response.error}');
        return UserResult.failure(
          AuthError.fromApiResponse(
            response.error ?? 'Erreur de mise à jour de la bio',
            response.statusCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Bio update error: $e');
      return UserResult.failure(AuthError.network());
    }
  }
}

// ===== MODÈLES DE DONNÉES =====

/// Statistiques du profil utilisateur
class ProfileStats {
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int likesReceived;
  final double totalEarnings;

  const ProfileStats({
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.likesReceived,
    required this.totalEarnings,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      postsCount: json['posts_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      likesReceived: json['likes_received'] ?? 0,
      totalEarnings: (json['total_earnings'] ?? 0.0).toDouble(),
    );
  }

  /// Statistiques par défaut (pour les nouveaux utilisateurs)
  static const ProfileStats empty = ProfileStats(
    postsCount: 0,
    followersCount: 0,
    followingCount: 0,
    likesReceived: 0,
    totalEarnings: 0.0,
  );
}

/// Post de l'utilisateur (version simplifiée pour le profil)
class UserPost {
  final int id;
  final String content;
  final String? imageUrl;
  final String? videoUrl;
  final String visibility; // 'public', 'subscriber'
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool isLiked;

  const UserPost({
    required this.id,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    required this.visibility,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.isLiked,
  });

  factory UserPost.fromJson(Map<String, dynamic> json) {
    return UserPost(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      visibility: json['visibility'] ?? 'public',
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isLiked: json['is_liked'] ?? false,
    );
  }

  bool get hasMedia => imageUrl != null || videoUrl != null;
  bool get isVideo => videoUrl != null;
  bool get isSubscriberOnly => visibility == 'subscriber';
}

/// Réponse d'upload d'avatar
class AvatarUploadResponse {
  final String message;
  final String avatarUrl;

  const AvatarUploadResponse({
    required this.message,
    required this.avatarUrl,
  });

  factory AvatarUploadResponse.fromJson(Map<String, dynamic> json) {
    return AvatarUploadResponse(
      message: json['message'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }
}

// ===== CLASSES DE RÉSULTATS =====

/// Résultat pour les statistiques de profil
class ProfileStatsResult {
  final bool isSuccess;
  final ProfileStats? data;
  final AuthError? error;

  const ProfileStatsResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory ProfileStatsResult.success(ProfileStats data) {
    return ProfileStatsResult._(isSuccess: true, data: data);
  }

  factory ProfileStatsResult.failure(AuthError error) {
    return ProfileStatsResult._(isSuccess: false, error: error);
  }

  bool get isFailure => !isSuccess;
}

/// Résultat pour les posts utilisateur
class UserPostsResult {
  final bool isSuccess;
  final List<UserPost>? data;
  final AuthError? error;

  const UserPostsResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory UserPostsResult.success(List<UserPost> data) {
    return UserPostsResult._(isSuccess: true, data: data);
  }

  factory UserPostsResult.failure(AuthError error) {
    return UserPostsResult._(isSuccess: false, error: error);
  }

  bool get isFailure => !isSuccess;
}

/// Résultat pour l'upload d'avatar
class AvatarUploadResult {
  final bool isSuccess;
  final AvatarUploadResponse? data;
  final AuthError? error;

  const AvatarUploadResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory AvatarUploadResult.success(AvatarUploadResponse data) {
    return AvatarUploadResult._(isSuccess: true, data: data);
  }

  factory AvatarUploadResult.failure(AuthError error) {
    return AvatarUploadResult._(isSuccess: false, error: error);
  }

  bool get isFailure => !isSuccess;
}