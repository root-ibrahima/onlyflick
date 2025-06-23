/// Modèle pour l'utilisateur (correspond au backend Go)
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'subscriber',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'role': role,
    'created_at': createdAt.toIso8601String(),
  };

  /// Nom complet de l'utilisateur
  String get fullName => '$firstName $lastName';

  /// Initiales de l'utilisateur
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
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
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'User(id: $id, email: $email, role: $role)';

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

  const UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.password,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (firstName != null) json['first_name'] = firstName;
    if (lastName != null) json['last_name'] = lastName;
    if (email != null) json['email'] = email;
    if (password != null) json['password'] = password;
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