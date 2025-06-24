// lib/features/profile/profile_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../../features/auth/models/auth_models.dart';
import '../models/profile_models.dart'; 


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

  /// Upload de l'avatar utilisateur
  Future<AvatarUploadResult> uploadAvatar(File imageFile) async {
    try {
      debugPrint('📤 Uploading avatar: ${imageFile.path}');
      
      // Validation basique du fichier
      if (!imageFile.existsSync()) {
        return AvatarUploadResult.failure(
          AuthError.validation('Fichier image non trouvé')
        );
      }

      // Vérifier la taille (5MB max)
      final fileSizeInBytes = imageFile.lengthSync();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      if (fileSizeInMB > 5) {
        return AvatarUploadResult.failure(
          AuthError.validation('Image trop volumineuse (${fileSizeInMB.toStringAsFixed(1)}MB). Maximum 5MB.')
        );
      }

      // Vérifier l'extension
      final fileName = imageFile.path.toLowerCase();
      if (!fileName.endsWith('.jpg') && 
          !fileName.endsWith('.jpeg') && 
          !fileName.endsWith('.png') && 
          !fileName.endsWith('.gif')) {
        return AvatarUploadResult.failure(
          AuthError.validation('Format non supporté. Utilisez JPG, PNG ou GIF.')
        );
      }

      final response = await _apiService.postMultipart<AvatarUploadResponse>(
        '/profile/avatar',
        fields: {}, // Pas de champs texte pour l'avatar
        files: {
          'avatar': imageFile, // Nom du champ attendu par le backend
        },
        fromJson: (json) => AvatarUploadResponse.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('📤 Avatar uploaded successfully: ${response.data!.avatarUrl}');
        return AvatarUploadResult.success(response.data!);
      } else {
        debugPrint('❌ Failed to upload avatar: ${response.error}');
        return AvatarUploadResult.failure(
          AuthError.fromApiResponse(
            response.error ?? 'Erreur lors de l\'upload de l\'avatar',
            response.statusCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Avatar upload error: $e');
      return AvatarUploadResult.failure(AuthError.network());
    }
  }

  /// Mise à jour de la bio utilisateur
  Future<BioUpdateResult> updateBio(String bio) async {
    try {
      debugPrint('📝 Updating bio: ${bio.length} characters');
      
      // Validation de la bio
      if (bio.length > 500) {
        return BioUpdateResult.failure(
          AuthError.validation('Bio trop longue (${bio.length}/500 caractères)')
        );
      }

      final response = await _apiService.patch<Map<String, dynamic>>(
        '/profile/bio',
        body: {
          'bio': bio.trim(),
        },
        fromJson: (json) => json,
      );

      if (response.isSuccess) {
        debugPrint('📝 Bio updated successfully');
        return BioUpdateResult.success();
      } else {
        debugPrint('❌ Failed to update bio: ${response.error}');
        return BioUpdateResult.failure(
          AuthError.fromApiResponse(
            response.error ?? 'Erreur lors de la mise à jour de la bio',
            response.statusCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Bio update error: $e');
      return BioUpdateResult.failure(AuthError.network());
    }
  }

  /// Vérification de la disponibilité d'un username
  Future<UsernameCheckResult> checkUsernameAvailability(String username) async {
    try {
      debugPrint('🔍 Checking username availability: $username');
      
      // Validation du username
      if (username.trim().isEmpty) {
        return UsernameCheckResult.failure(
          AuthError.validation('Username ne peut pas être vide')
        );
      }

      if (username.length < 3 || username.length > 50) {
        return UsernameCheckResult.failure(
          AuthError.validation('Username doit faire entre 3 et 50 caractères')
        );
      }

      final response = await _apiService.get<UsernameCheckResponse>(
        '/profile/username/check?username=${Uri.encodeComponent(username.trim().toLowerCase())}',
        fromJson: (json) => UsernameCheckResponse.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('🔍 Username check successful: ${response.data!.available}');
        return UsernameCheckResult.success(response.data!);
      } else {
        debugPrint('❌ Failed to check username: ${response.error}');
        return UsernameCheckResult.failure(
          AuthError.fromApiResponse(
            response.error ?? 'Erreur lors de la vérification du username',
            response.statusCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Username check error: $e');
      return UsernameCheckResult.failure(AuthError.network());
    }
  }
}