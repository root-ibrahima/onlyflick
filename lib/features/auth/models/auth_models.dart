//auth_models.dart
/// Modèle pour l'utilisateur (correspond au backend Go)
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final DateTime createdAt;
  // ===== NOUVEAUX CHAMPS PROFIL =====
  final String avatarUrl;
  final String bio;
  final String username;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.createdAt,
    // ===== NOUVEAUX CHAMPS AVEC VALEURS PAR DÉFAUT =====
    this.avatarUrl = '',
    this.bio = '',
    this.username = '',
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'subscriber',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      // ===== PARSING DES NOUVEAUX CHAMPS =====
      avatarUrl: json['avatar_url'] ?? '',
      bio: json['bio'] ?? '',
      username: json['username'] ?? '',
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'role': role,
    'created_at': createdAt.toIso8601String(),
    // ===== SÉRIALISATION DES NOUVEAUX CHAMPS =====
    'avatar_url': avatarUrl,
    'bio': bio,
    'username': username,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  /// Nom complet de l'utilisateur
  String get fullName => '$firstName $lastName';

  /// Initiales de l'utilisateur
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  /// Nom d'affichage (username si disponible, sinon nom complet)
  String get displayName {
    if (username.isNotEmpty) return '@$username';
    return fullName;
  }

  /// Vérifie si l'utilisateur a un avatar personnalisé
  bool get hasCustomAvatar => avatarUrl.isNotEmpty;

  /// Vérifie si l'utilisateur a une bio
  bool get hasBio => bio.isNotEmpty;

  /// Vérifie si l'utilisateur a un username
  bool get hasUsername => username.isNotEmpty;

  /// URL de l'avatar avec fallback
  String get effectiveAvatarUrl {
    if (avatarUrl.isNotEmpty) return avatarUrl;
    // Fallback vers un avatar généré basé sur l'ID
    return 'https://i.pravatar.cc/150?img=${id % 20}';
  }

  /// Vérifie si l'utilisateur est un créateur
  bool get isCreator => role == 'creator';

  /// Vérifie si l'utilisateur est un administrateur
  bool get isAdmin => role == 'admin';

  /// Vérifie si l'utilisateur est un abonné
  bool get isSubscriber => role == 'subscriber';

  /// Copie avec modification
  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    DateTime? createdAt,
    String? avatarUrl,
    String? bio,
    String? username,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      username: username ?? this.username,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'User(id: $id, email: $email, role: $role, username: $username)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modèle pour la requête de connexion
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

/// Modèle pour la requête d'inscription
class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'password': password,
  };
}

/// Modèle pour la réponse d'authentification (login/register)
class AuthResponse {
  final String message;
  final int userId;
  final String token;

  const AuthResponse({
    required this.message,
    required this.userId,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] ?? '',
      userId: json['user_id'] ?? 0,
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'user_id': userId,
    'token': token,
  };
}

/// Modèle pour la requête de mise à jour du profil
class UpdateProfileRequest {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? password;
  final String? avatarUrl;
  final String? bio;
  final String? username;

  const UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.avatarUrl,
    this.bio,
    this.username,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (firstName != null) json['first_name'] = firstName;
    if (lastName != null) json['last_name'] = lastName;
    if (email != null) json['email'] = email;
    if (password != null) json['password'] = password;
    if (avatarUrl != null) json['avatar_url'] = avatarUrl;
    if (bio != null) json['bio'] = bio;
    if (username != null) json['username'] = username;
    return json;
  }
}

/// États d'authentification
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Modèle pour les erreurs d'authentification
class AuthError {
  final String message;
  final String? field;
  final int? statusCode;

  const AuthError({
    required this.message,
    this.field,
    this.statusCode,
  });

  factory AuthError.fromApiResponse(String message, int? statusCode) {
    return AuthError(
      message: message,
      statusCode: statusCode,
    );
  }

  factory AuthError.validation(String message, {String? field}) {
    return AuthError(
      message: message,
      field: field,
      statusCode: 400,
    );
  }

  factory AuthError.network() {
    return const AuthError(
      message: 'Problème de connexion réseau',
    );
  }

  factory AuthError.server() {
    return const AuthError(
      message: 'Erreur serveur, veuillez réessayer',
      statusCode: 500,
    );
  }

  bool get isValidationError => statusCode == 400;
  bool get isAuthError => statusCode == 401;
  bool get isNetworkError => statusCode == null;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'AuthError(message: $message, field: $field, statusCode: $statusCode)';
}

/// Classe pour les résultats d'authentification
class AuthResult {
  final bool isSuccess;
  final AuthResponse? data;
  final AuthError? error;

  const AuthResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory AuthResult.success(AuthResponse? data) {
    return AuthResult._(isSuccess: true, data: data);
  }

  factory AuthResult.failure(AuthError error) {
    return AuthResult._(isSuccess: false, error: error);
  }

  bool get isFailure => !isSuccess;
}

/// Classe pour les résultats d'utilisateur
class UserResult {
  final bool isSuccess;
  final User? data;
  final AuthError? error;

  const UserResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory UserResult.success(User data) {
    return UserResult._(isSuccess: true, data: data);
  }

  factory UserResult.failure(AuthError error) {
    return UserResult._(isSuccess: false, error: error);
  }

  bool get isFailure => !isSuccess;
}