import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/post_models.dart';

/// Service pour la gestion des posts
class PostsService {
  final ApiService _apiService = ApiService();

  /// Récupère tous les posts visibles pour l'utilisateur connecté
  Future<PostsResult> getAllPosts() async {
    try {
      debugPrint('📱 Fetching all visible posts');
      
      final response = await _apiService.get<dynamic>('/posts/all');

      if (response.isSuccess && response.data != null) {
        final posts = (response.data as List)
            .map((json) => Post.fromJson(json))
            .toList();
        
        debugPrint('📱 ${posts.length} posts fetched successfully');
        return PostsResult.success(posts);
      } else {
        debugPrint('❌ Failed to fetch posts: ${response.error}');
        return PostsResult.failure(response.error ?? 'Erreur de récupération des posts');
      }
    } catch (e) {
      debugPrint('❌ Posts fetch error: $e');
      return PostsResult.failure('Erreur lors de la récupération des posts');
    }
  }

  /// Récupère les posts d'un créateur spécifique
  Future<PostsResult> getCreatorPosts(int creatorId, {bool subscriberOnly = false}) async {
    try {
      debugPrint('📱 Fetching posts from creator: $creatorId');
      
      String endpoint;
      if (subscriberOnly) {
        endpoint = '/posts/from/$creatorId/subscriber-only';
      } else {
        endpoint = '/posts/from/$creatorId';
      }

      final response = await _apiService.get<dynamic>(endpoint);

      if (response.isSuccess && response.data != null) {
        final posts = (response.data as List)
            .map((json) => Post.fromJson(json))
            .toList();
        
        debugPrint('📱 ${posts.length} posts from creator $creatorId fetched successfully');
        return PostsResult.success(posts);
      } else {
        debugPrint('❌ Failed to fetch creator posts: ${response.error}');
        return PostsResult.failure(response.error ?? 'Erreur de récupération des posts du créateur');
      }
    } catch (e) {
      debugPrint('❌ Creator posts fetch error: $e');
      return PostsResult.failure('Erreur lors de la récupération des posts du créateur');
    }
  }

  /// Like/Unlike un post
  Future<LikeResult> toggleLike(int postId) async {
    try {
      debugPrint('❤️ Toggling like for post: $postId');
      
      final response = await _apiService.post<Map<String, dynamic>>(
        '/posts/$postId/likes',
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final liked = response.data!['liked'] ?? false;
        debugPrint('❤️ Post $postId like toggled: $liked');
        return LikeResult.success(liked);
      } else {
        debugPrint('❌ Failed to toggle like: ${response.error}');
        return LikeResult.failure(response.error ?? 'Erreur lors du like');
      }
    } catch (e) {
      debugPrint('❌ Like toggle error: $e');
      return LikeResult.failure('Erreur lors du like');
    }
  }

  /// Récupère le nombre de likes d'un post
  Future<LikesCountResult> getPostLikes(int postId) async {
    try {
      debugPrint('📊 Fetching likes count for post: $postId');
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/posts/$postId/likes',
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final likesCount = response.data!['likes_count'] ?? 0;
        debugPrint('📊 Post $postId has $likesCount likes');
        return LikesCountResult.success(likesCount);
      } else {
        debugPrint('❌ Failed to fetch likes count: ${response.error}');
        return LikesCountResult.failure(response.error ?? 'Erreur de récupération des likes');
      }
    } catch (e) {
      debugPrint('❌ Likes count fetch error: $e');
      return LikesCountResult.failure('Erreur lors de la récupération des likes');
    }
  }

  /// Récupère les commentaires d'un post
  Future<CommentsResult> getPostComments(int postId) async {
    try {
      debugPrint('💬 Fetching comments for post: $postId');
      
      final response = await _apiService.get<dynamic>('/comments/post/$postId');

      if (response.isSuccess && response.data != null) {
        final comments = (response.data as List)
            .map((json) => Comment.fromJson(json))
            .toList();
        
        debugPrint('💬 ${comments.length} comments fetched for post $postId');
        return CommentsResult.success(comments);
      } else {
        debugPrint('❌ Failed to fetch comments: ${response.error}');
        return CommentsResult.failure(response.error ?? 'Erreur de récupération des commentaires');
      }
    } catch (e) {
      debugPrint('❌ Comments fetch error: $e');
      return CommentsResult.failure('Erreur lors de la récupération des commentaires');
    }
  }

  /// Ajoute un commentaire à un post
  Future<CommentResult> addComment(int postId, String content) async {
    try {
      debugPrint('💬 Adding comment to post: $postId');
      
      final response = await _apiService.post<Map<String, dynamic>>(
        '/comments',
        body: {
          'post_id': postId,
          'content': content,
        },
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final comment = Comment.fromJson(response.data!);
        debugPrint('💬 Comment added successfully to post $postId');
        return CommentResult.success(comment);
      } else {
        debugPrint('❌ Failed to add comment: ${response.error}');
        return CommentResult.failure(response.error ?? 'Erreur lors de l\'ajout du commentaire');
      }
    } catch (e) {
      debugPrint('❌ Add comment error: $e');
      return CommentResult.failure('Erreur lors de l\'ajout du commentaire');
    }
  }

  /// Récupère mes posts (pour l'utilisateur connecté)
  Future<PostsResult> getMyPosts() async {
    try {
      debugPrint('📱 Fetching my posts');
      
      final response = await _apiService.get<dynamic>('/posts/me');

      if (response.isSuccess && response.data != null) {
        final posts = (response.data as List)
            .map((json) => Post.fromJson(json))
            .toList();
        
        debugPrint('📱 ${posts.length} of my posts fetched successfully');
        return PostsResult.success(posts);
      } else {
        debugPrint('❌ Failed to fetch my posts: ${response.error}');
        return PostsResult.failure(response.error ?? 'Erreur de récupération de vos posts');
      }
    } catch (e) {
      debugPrint('❌ My posts fetch error: $e');
      return PostsResult.failure('Erreur lors de la récupération de vos posts');
    }
  }

/// Récupère les posts recommandés pour l'utilisateur connecté
Future<PostsResult> getRecommendedPosts() async {
  try {
    debugPrint('🤖 Fetching recommended posts for user');

    final response = await _apiService.get<dynamic>('/posts/recommended');

    if (response.isSuccess && response.data != null) {
      final posts = (response.data as List)
          .map((json) => Post.fromJson(json))
          .toList();

      debugPrint('🤖 ${posts.length} recommended posts fetched successfully');
      return PostsResult.success(posts);
    } else {
      debugPrint('❌ Failed to fetch recommended posts: ${response.error}');
      return PostsResult.failure(response.error ?? 'Erreur de récupération des posts recommandés');
    }
  } catch (e) {
    debugPrint('❌ Recommended posts fetch error: $e');
    return PostsResult.failure('Erreur lors de la récupération des posts recommandés');
  }
}


}

class Comment {
  final int id;
  final int userId;
  final int postId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Comment({
    required this.id,
    required this.userId,
    required this.postId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      postId: json['post_id'] ?? 0,
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'Comment(id: $id, content: $content)';
}

/// Classes de résultats pour les différentes opérations

class PostsResult {
  final bool isSuccess;
  final List<Post>? data;
  final String? error;

  const PostsResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory PostsResult.success(List<Post> data) {
    return PostsResult._(isSuccess: true, data: data);
  }

  factory PostsResult.failure(String error) {
    return PostsResult._(isSuccess: false, error: error);
  }

  bool get isFailure => !isSuccess;
}

class LikeResult {
  final bool isSuccess;
  final bool? data;
  final String? error;

  const LikeResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory LikeResult.success(bool liked) {
    return LikeResult._(isSuccess: true, data: liked);
  }

  factory LikeResult.failure(String error) {
    return LikeResult._(isSuccess: false, error: error);
  }

  bool get isFailure => !isSuccess;
}

class LikesCountResult {
  final bool isSuccess;
  final int? data;
  final String? error;

  const LikesCountResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory LikesCountResult.success(int count) {
    return LikesCountResult._(isSuccess: true, data: count);
  }

  factory LikesCountResult.failure(String error) {
    return LikesCountResult._(isSuccess: false, error: error);
  }

  bool get isFailure => !isSuccess;
}

class CommentsResult {
  final bool isSuccess;
  final List<Comment>? data;
  final String? error;

  const CommentsResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory CommentsResult.success(List<Comment> data) {
    return CommentsResult._(isSuccess: true, data: data);
  }

  factory CommentsResult.failure(String error) {
    return CommentsResult._(isSuccess: false, error: error);
  }

  bool get isFailure => !isSuccess;
}

class CommentResult {
  final bool isSuccess;
  final Comment? data;
  final String? error;

  const CommentResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory CommentResult.success(Comment data) {
    return CommentResult._(isSuccess: true, data: data);
  }

  factory CommentResult.failure(String error) {
    return CommentResult._(isSuccess: false, error: error);
  }

  bool get isFailure => !isSuccess;
}