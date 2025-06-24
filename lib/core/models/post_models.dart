// lib/core/models/post_models.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// Modèle pour un post
class Post {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String mediaUrl;
  final String? fileId;
  final String visibility;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.mediaUrl,
    this.fileId,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      mediaUrl: json['media_url'] ?? '',
      fileId: json['file_id'],
      visibility: json['visibility'] ?? 'public',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'media_url': mediaUrl,
      'file_id': fileId,
      'visibility': visibility,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Post copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? mediaUrl,
    String? fileId,
    String? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileId: fileId ?? this.fileId,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Énumération pour la visibilité des posts
enum PostVisibility {
  public('public'),
  subscriber('subscriber');

  const PostVisibility(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case PostVisibility.public:
        return 'Public';
      case PostVisibility.subscriber:
        return 'Abonnés uniquement';
    }
  }

  String get description {
    switch (this) {
      case PostVisibility.public:
        return 'Visible par tous les utilisateurs';
      case PostVisibility.subscriber:
        return 'Visible uniquement par vos abonnés';
    }
  }

  IconData get icon {
    switch (this) {
      case PostVisibility.public:
        return Icons.public;
      case PostVisibility.subscriber:
        return Icons.lock;
    }
  }

  /// Convertit une string en PostVisibility
  static PostVisibility fromString(String value) {
    switch (value.toLowerCase()) {
      case 'subscriber':
        return PostVisibility.subscriber;
      case 'public':
      default:
        return PostVisibility.public;
    }
  }
}

/// Résultat de création/modification de post
class PostCreationResult {
  final bool isSuccess;
  final Post? data;
  final String? error;

  const PostCreationResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory PostCreationResult.success(Post post) {
    return PostCreationResult._(
      isSuccess: true,
      data: post,
    );
  }

  factory PostCreationResult.failure(String error) {
    return PostCreationResult._(
      isSuccess: false,
      error: error,
    );
  }

  bool get isFailure => !isSuccess;
}

/// Extensions pour les fichiers média
extension MediaValidation on File {
  /// Vérifie si le fichier est une image valide
  bool get isValidImage {
    final extension = path.extension(this.path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif'].contains(extension);
  }

  /// Vérifie la taille du fichier (max 10MB)
  Future<bool> get isValidSize async {
    try {
      final bytes = await length();
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      return bytes <= maxSizeBytes;
    } catch (e) {
      return false;
    }
  }

  /// Retourne la taille du fichier en MB
  Future<double> get sizeInMB async {
    try {
      final bytes = await length();
      return bytes / (1024 * 1024);
    } catch (e) {
      return 0;
    }
  }
}